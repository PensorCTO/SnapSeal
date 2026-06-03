-- Credit-based metering layer: subscription cycles + consumption ledger.
-- Complements byte-weighted archive_quotas (storage/egress bytes).

-- 1. Subscription cycles (monthly pro-proof allocation + egress credit balance).
create table public.subscription_cycles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  cycle_start timestamptz not null,
  cycle_end timestamptz not null,
  base_allocation integer not null default 50 check (base_allocation > 0),
  egress_credits_balance integer not null default 12 check (egress_credits_balance >= 0),
  created_at timestamptz not null default now(),
  check (cycle_end > cycle_start)
);

create unique index subscription_cycles_user_month_idx
  on public.subscription_cycles (user_id, cycle_start);

create index subscription_cycles_user_id_idx
  on public.subscription_cycles (user_id, cycle_start desc);

alter table public.subscription_cycles enable row level security;

drop policy if exists "Users select own subscription cycles" on public.subscription_cycles;
create policy "Users select own subscription cycles"
  on public.subscription_cycles
  for select
  to authenticated
  using (user_id = auth.uid());

grant select on table public.subscription_cycles to authenticated;

-- 2. Metered consumption ledger (append-only debits).
create table public.metered_consumption_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  cycle_id uuid references public.subscription_cycles (id) on delete set null,
  action_type text not null check (action_type in ('pro_proof', 'verification_credit')),
  created_at timestamptz not null default now()
);

create index metered_consumption_ledger_user_action_created_idx
  on public.metered_consumption_ledger (user_id, action_type, created_at);

alter table public.metered_consumption_ledger enable row level security;

drop policy if exists "Users select own metered consumption" on public.metered_consumption_ledger;
create policy "Users select own metered consumption"
  on public.metered_consumption_ledger
  for select
  to authenticated
  using (user_id = auth.uid());

grant select on table public.metered_consumption_ledger to authenticated;

-- 3. Ensure an active calendar-month cycle exists for a user.
create or replace function private.ensure_active_subscription_cycle(p_user_id uuid)
returns public.subscription_cycles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cycle public.subscription_cycles%rowtype;
  v_month_start timestamptz := date_trunc('month', now());
  v_month_end timestamptz := v_month_start + interval '1 month';
begin
  select *
    into v_cycle
    from public.subscription_cycles sc
    where sc.user_id = p_user_id
      and sc.cycle_end > now()
    order by sc.cycle_start desc
    limit 1
    for update;

  if found then
    return v_cycle;
  end if;

  insert into public.subscription_cycles (
    user_id,
    cycle_start,
    cycle_end,
    base_allocation,
    egress_credits_balance
  )
  values (
    p_user_id,
    v_month_start,
    v_month_end,
    50,
    12
  )
  returning * into v_cycle;

  return v_cycle;
end;
$$;

-- 4. Seed cycle on new profile.
create or replace function private.seed_subscription_cycle()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform private.ensure_active_subscription_cycle(new.id);
  return new;
end;
$$;

drop trigger if exists on_profile_created_seed_subscription_cycle on public.profiles;
create trigger on_profile_created_seed_subscription_cycle
  after insert on public.profiles
  for each row execute function private.seed_subscription_cycle();

-- Backfill existing profiles.
insert into public.subscription_cycles (user_id, cycle_start, cycle_end)
select
  p.id,
  date_trunc('month', now()),
  date_trunc('month', now()) + interval '1 month'
from public.profiles p
where not exists (
  select 1
  from public.subscription_cycles sc
  where sc.user_id = p.id
    and sc.cycle_end > now()
);

-- 5. Build quota status JSON for a user (internal helper).
create or replace function private.build_quota_status_json(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cycle public.subscription_cycles%rowtype;
  v_proofs_used integer;
  v_proofs_remaining integer;
begin
  v_cycle := private.ensure_active_subscription_cycle(p_user_id);

  select count(*)::integer
    into v_proofs_used
    from public.metered_consumption_ledger mcl
    where mcl.user_id = p_user_id
      and mcl.action_type = 'pro_proof'
      and mcl.created_at >= v_cycle.cycle_start
      and mcl.created_at < v_cycle.cycle_end;

  v_proofs_remaining := greatest(v_cycle.base_allocation - v_proofs_used, 0);

  return jsonb_build_object(
    'pro_proofs_remaining', v_proofs_remaining,
    'pro_proofs_base', v_cycle.base_allocation,
    'egress_credits_balance', v_cycle.egress_credits_balance,
    'cycle_end', v_cycle.cycle_end
  );
end;
$$;

-- 6. RPC: poll current quota status for authenticated user.
create or replace function public.get_current_quota_status()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Authenticated user required';
  end if;

  return private.build_quota_status_json(v_uid);
end;
$$;

-- 7. RPC: record a metered consumption debit.
create or replace function public.record_metered_consumption(p_action_type text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_cycle public.subscription_cycles%rowtype;
  v_proofs_used integer;
  v_proofs_remaining integer;
begin
  if v_uid is null then
    raise exception 'Authenticated user required';
  end if;

  if p_action_type is null
      or p_action_type not in ('pro_proof', 'verification_credit') then
    raise exception 'Invalid metered action type';
  end if;

  v_cycle := private.ensure_active_subscription_cycle(v_uid);

  if p_action_type = 'pro_proof' then
    select count(*)::integer
      into v_proofs_used
      from public.metered_consumption_ledger mcl
      where mcl.user_id = v_uid
        and mcl.action_type = 'pro_proof'
        and mcl.created_at >= v_cycle.cycle_start
        and mcl.created_at < v_cycle.cycle_end;

    v_proofs_remaining := v_cycle.base_allocation - v_proofs_used;

    if v_proofs_remaining <= 0 then
      raise exception 'Pro proof quota exhausted';
    end if;
  elsif p_action_type = 'verification_credit' then
    if v_cycle.egress_credits_balance <= 0 then
      raise exception 'Verification credits exhausted';
    end if;

    update public.subscription_cycles
      set egress_credits_balance = egress_credits_balance - 1
      where id = v_cycle.id
      returning * into v_cycle;
  end if;

  insert into public.metered_consumption_ledger (
    user_id,
    cycle_id,
    action_type
  )
  values (
    v_uid,
    v_cycle.id,
    p_action_type
  );

  return private.build_quota_status_json(v_uid);
end;
$$;

revoke all on function public.get_current_quota_status() from public;
grant execute on function public.get_current_quota_status() to authenticated, service_role;

revoke all on function public.record_metered_consumption(text) from public;
grant execute on function public.record_metered_consumption(text) to authenticated, service_role;

notify pgrst, 'reload schema';
