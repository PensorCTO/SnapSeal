-- Repair accidental revert in 20260605161717_my_schema.sql:
-- restore credit metering, courier metadata RPCs, UGC safety, and proof attestation.

-- ── 1. Credit metering (subscription_cycles + RPCs) ─────────────────────────

create table if not exists public.subscription_cycles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  cycle_start timestamptz not null,
  cycle_end timestamptz not null,
  base_allocation integer not null default 50 check (base_allocation > 0),
  egress_credits_balance integer not null default 12 check (egress_credits_balance >= 0),
  created_at timestamptz not null default now(),
  check (cycle_end > cycle_start)
);

create unique index if not exists subscription_cycles_user_month_idx
  on public.subscription_cycles (user_id, cycle_start);

create index if not exists subscription_cycles_user_id_idx
  on public.subscription_cycles (user_id, cycle_start desc);

alter table public.subscription_cycles enable row level security;

drop policy if exists "Users select own subscription cycles" on public.subscription_cycles;
create policy "Users select own subscription cycles"
  on public.subscription_cycles
  for select
  to authenticated
  using (user_id = auth.uid());

grant select on table public.subscription_cycles to authenticated;

create table if not exists public.metered_consumption_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  cycle_id uuid references public.subscription_cycles (id) on delete set null,
  action_type text not null check (action_type in ('pro_proof', 'verification_credit')),
  created_at timestamptz not null default now()
);

create index if not exists metered_consumption_ledger_user_action_created_idx
  on public.metered_consumption_ledger (user_id, action_type, created_at);

alter table public.metered_consumption_ledger enable row level security;

drop policy if exists "Users select own metered consumption" on public.metered_consumption_ledger;
create policy "Users select own metered consumption"
  on public.metered_consumption_ledger
  for select
  to authenticated
  using (user_id = auth.uid());

grant select on table public.metered_consumption_ledger to authenticated;

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

-- ── 2. Courier payload metadata columns ─────────────────────────────────────

alter table public.courier_packages
  add column if not exists content_mime_type text,
  add column if not exists content_category text,
  add column if not exists moderation_status text not null default 'pending_scan';

alter table public.courier_packages
  drop constraint if exists courier_packages_content_category_check;

alter table public.courier_packages
  add constraint courier_packages_content_category_check
  check (
    content_category is null
    or content_category in (
      'image',
      'video',
      'audio',
      'document',
      'archive',
      'binary'
    )
  );

alter table public.courier_packages
  drop constraint if exists courier_packages_moderation_status_check;

alter table public.courier_packages
  add constraint courier_packages_moderation_status_check
  check (
    moderation_status in ('pending_scan', 'cleared', 'flagged', 'quarantined')
  );

-- ── 3. Send Proof origination RPC (7-parameter signature) ───────────────────

drop function if exists public.get_or_create_courier_package(text, text, text, text, text);
drop function if exists public.get_or_create_courier_package(
  text, text, text, text, text, text, text
);

create or replace function public.get_or_create_courier_package(
  p_asset_hash text,
  p_verifier_password text,
  p_encoded_vault_key text,
  p_file_extension text,
  p_storage_path text,
  p_content_mime_type text default null,
  p_content_category text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_owner_id uuid := auth.uid();
  v_package_id uuid;
  v_verifier_secret_hash text;
  v_category text;
begin
  if v_owner_id is null then
    raise exception 'Authenticated user required';
  end if;

  if nullif(trim(p_asset_hash), '') is null then
    raise exception 'Asset hash is required';
  end if;

  if nullif(p_verifier_password, '') is null then
    raise exception 'Verifier password is required';
  end if;

  if nullif(trim(p_encoded_vault_key), '') is null then
    raise exception 'Encoded vault key is required';
  end if;

  if nullif(trim(p_storage_path), '') is null then
    raise exception 'Storage path is required';
  end if;

  if split_part(p_storage_path, '/', 1) <> v_owner_id::text then
    raise exception 'Storage path must be scoped to the authenticated user';
  end if;

  v_category := nullif(lower(trim(p_content_category)), '');
  if v_category is not null
     and v_category not in (
       'image',
       'video',
       'audio',
       'document',
       'archive',
       'binary'
     ) then
    raise exception 'Invalid content category';
  end if;

  v_verifier_secret_hash :=
    encode(extensions.digest(coalesce(p_verifier_password, ''), 'sha256'), 'hex');

  select cp.package_id
    into v_package_id
    from public.courier_packages cp
    where cp.owner_id = v_owner_id
      and cp.asset_hash = trim(p_asset_hash)
    order by cp.created_at desc
    limit 1;

  if v_package_id is not null then
    update public.courier_packages cp
      set verifier_secret_hash = v_verifier_secret_hash,
          storage_path = trim(p_storage_path),
          file_extension = lower(trim(p_file_extension)),
          vault_key = trim(p_encoded_vault_key),
          content_mime_type = nullif(trim(p_content_mime_type), ''),
          content_category = v_category,
          failed_attempts = 0,
          download_count = 0,
          last_failed_at = null,
          requestor_email = null,
          unlocked_at = null,
          burned_at = null,
          is_bricked = false,
          expires_at = now() + interval '7 days',
          updated_at = now()
      where cp.package_id = v_package_id;
    return v_package_id;
  end if;

  insert into public.courier_packages (
    owner_id,
    asset_hash,
    storage_bucket,
    storage_path,
    file_extension,
    vault_key,
    verifier_secret_hash,
    content_mime_type,
    content_category,
    expires_at
  )
  values (
    v_owner_id,
    trim(p_asset_hash),
    'courier-blobs',
    trim(p_storage_path),
    lower(trim(p_file_extension)),
    trim(p_encoded_vault_key),
    v_verifier_secret_hash,
    nullif(trim(p_content_mime_type), ''),
    v_category,
    now() + interval '7 days'
  )
  returning package_id into v_package_id;

  return v_package_id;
end;
$$;

revoke all on function public.get_or_create_courier_package(
  text, text, text, text, text, text, text
) from public;
grant execute on function public.get_or_create_courier_package(
  text, text, text, text, text, text, text
) to authenticated, service_role;

-- ── 4. Recipient unlock RPC (content_mime_type in result) ─────────────────

drop function if exists public.attempt_courier_unlock(uuid, text, text);

create or replace function public.attempt_courier_unlock(
  p_package_id uuid,
  p_verifier_guess text,
  p_requestor_email text
)
returns table (
  key text,
  file_extension text,
  storage_bucket text,
  storage_path text,
  asset_hash text,
  content_mime_type text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_package public.courier_packages%rowtype;
  v_guess_hash text;
begin
  select *
    into v_package
    from public.courier_packages
    where package_id = p_package_id
    for update;

  if not found then
    raise exception 'Courier package not found';
  end if;

  if v_package.moderation_status = 'quarantined' then
    raise exception 'This package is unavailable pending review';
  end if;

  if v_package.is_bricked
      or v_package.burned_at is not null
      or v_package.expires_at <= now()
      or v_package.failed_attempts >= v_package.max_attempts
      or v_package.download_count >= v_package.max_downloads then
    raise exception 'Courier package is locked';
  end if;

  v_guess_hash := encode(extensions.digest(coalesce(p_verifier_guess, ''), 'sha256'), 'hex');

  if v_guess_hash <> v_package.verifier_secret_hash then
    update public.courier_packages cp
      set failed_attempts = failed_attempts + 1,
          last_failed_at = now(),
          requestor_email = nullif(p_requestor_email, '')
      where cp.package_id = p_package_id
      returning * into v_package;

    if v_package.failed_attempts >= v_package.max_attempts then
      update public.courier_packages cp
        set burned_at = now(),
            is_bricked = true
        where cp.package_id = p_package_id;

      delete from storage.objects so
      where so.bucket_id = v_package.storage_bucket
        and so.name = v_package.storage_path;
    end if;

    raise exception 'Invalid verifier challenge';
  end if;

  update public.courier_packages cp
    set unlocked_at = now(),
        download_count = download_count + 1,
        requestor_email = nullif(p_requestor_email, '')
    where cp.package_id = p_package_id
    returning * into v_package;

  perform public.increment_archive_egress(
    v_package.owner_id,
    coalesce(v_package.file_size_bytes, 0)
  );

  return query
    select
      v_package.vault_key,
      v_package.file_extension,
      v_package.storage_bucket,
      v_package.storage_path,
      v_package.asset_hash,
      v_package.content_mime_type;
end;
$$;

revoke all on function public.attempt_courier_unlock(uuid, text, text) from public;
grant execute on function public.attempt_courier_unlock(uuid, text, text)
  to anon, authenticated, service_role;

-- ── 5. Public proof attestation (courier proof panel) ───────────────────────

create or replace function public.get_public_proof_attestation(p_asset_hash text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.proof_ledger%rowtype;
  v_hash text := lower(trim(coalesce(p_asset_hash, '')));
begin
  if v_hash = '' then
    return jsonb_build_object('found', false, 'error', 'asset_hash required');
  end if;

  select *
    into v_row
    from public.proof_ledger pl
    where lower(pl.asset_hash) = v_hash
      and pl.notarization_status = 'notarized'
    order by pl.sealed_at desc nulls last
    limit 1;

  if not found then
    return jsonb_build_object('found', false);
  end if;

  return jsonb_build_object(
    'found', true,
    'chain_tx_hash', v_row.chain_tx_hash,
    'sealed_at', v_row.sealed_at,
    'notarization_status', v_row.notarization_status,
    'block_number', null
  );
end;
$$;

revoke all on function public.get_public_proof_attestation(text) from public;
grant execute on function public.get_public_proof_attestation(text)
  to anon, authenticated, service_role;

notify pgrst, 'reload schema';
