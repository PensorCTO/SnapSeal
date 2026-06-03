-- Archive quota telemetry: tier catalog, per-user metering, strict RLS, RPC mutations.
-- Dual egress model: byte-weighted account cap (this migration) + per-package max_downloads (existing).

-- 1. Tier reference catalog (public read-only for clients).
create table public.archive_tiers (
  tier_id text primary key,
  display_name text not null,
  storage_limit_bytes bigint not null check (storage_limit_bytes > 0),
  egress_limit_bytes bigint not null check (egress_limit_bytes > 0),
  monthly_price_cents integer not null default 0 check (monthly_price_cents >= 0)
);

insert into public.archive_tiers (
  tier_id,
  display_name,
  storage_limit_bytes,
  egress_limit_bytes,
  monthly_price_cents
)
values
  (
    'free',
    'Zero-Trust Tourist',
    52428800,        -- 50 MB
    3221225472,      -- 3 GB monthly egress
    0
  ),
  (
    'picture',
    'The Creator',
    5368709120,      -- 5 GB
    26843545600,     -- 25 GB
    100
  ),
  (
    'video',
    'The Archivist',
    53687091200,     -- 50 GB
    214748364800,    -- 200 GB
    1000
  )
on conflict (tier_id) do update
  set display_name = excluded.display_name,
      storage_limit_bytes = excluded.storage_limit_bytes,
      egress_limit_bytes = excluded.egress_limit_bytes,
      monthly_price_cents = excluded.monthly_price_cents;

alter table public.archive_tiers enable row level security;

drop policy if exists "Public read archive tiers" on public.archive_tiers;
create policy "Public read archive tiers"
  on public.archive_tiers
  for select
  to authenticated, anon
  using (true);

grant select on table public.archive_tiers to authenticated, anon;

-- 2. Per-user quota row (1:1 with profiles).
create table public.archive_quotas (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  tier_id text not null default 'free' references public.archive_tiers (tier_id),
  storage_used_bytes bigint not null default 0 check (storage_used_bytes >= 0),
  egress_used_bytes bigint not null default 0 check (egress_used_bytes >= 0),
  egress_period_start timestamptz not null default date_trunc('month', now()),
  updated_at timestamptz not null default now()
);

create index archive_quotas_tier_id_idx
  on public.archive_quotas (tier_id);

alter table public.archive_quotas enable row level security;

drop policy if exists "Users select own archive quota" on public.archive_quotas;
create policy "Users select own archive quota"
  on public.archive_quotas
  for select
  to authenticated
  using (user_id = auth.uid());

grant select on table public.archive_quotas to authenticated;

-- 3. Seed quota rows for new profiles.
create or replace function private.seed_archive_quota()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.archive_quotas (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_profile_created_seed_archive_quota on public.profiles;
create trigger on_profile_created_seed_archive_quota
  after insert on public.profiles
  for each row execute function private.seed_archive_quota();

-- Backfill existing profiles.
insert into public.archive_quotas (user_id)
select p.id
from public.profiles p
left join public.archive_quotas aq on aq.user_id = p.id
where aq.user_id is null;

-- 4. Internal helper: reset egress window when calendar month rolls over.
create or replace function private.reset_archive_egress_if_needed(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.archive_quotas aq
  set egress_used_bytes = 0,
      egress_period_start = date_trunc('month', now()),
      updated_at = now()
  where aq.user_id = p_user_id
    and aq.egress_period_start < date_trunc('month', now());
end;
$$;

-- 5. RPC: fetch joined quota + tier limits for the authenticated user.
create or replace function public.get_my_archive_quota()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_row record;
begin
  if v_uid is null then
    raise exception 'Authenticated user required';
  end if;

  perform private.reset_archive_egress_if_needed(v_uid);

  insert into public.archive_quotas (user_id)
  values (v_uid)
  on conflict (user_id) do nothing;

  select
    aq.user_id,
    aq.tier_id,
    aq.storage_used_bytes,
    aq.egress_used_bytes,
    aq.egress_period_start,
    aq.updated_at,
    t.display_name,
    t.storage_limit_bytes,
    t.egress_limit_bytes,
    t.monthly_price_cents
  into v_row
  from public.archive_quotas aq
  join public.archive_tiers t on t.tier_id = aq.tier_id
  where aq.user_id = v_uid;

  return jsonb_build_object(
    'user_id', v_row.user_id,
    'tier_id', v_row.tier_id,
    'display_name', v_row.display_name,
    'storage_used_bytes', v_row.storage_used_bytes,
    'storage_limit_bytes', v_row.storage_limit_bytes,
    'egress_used_bytes', v_row.egress_used_bytes,
    'egress_limit_bytes', v_row.egress_limit_bytes,
    'egress_period_start', v_row.egress_period_start,
    'monthly_price_cents', v_row.monthly_price_cents,
    'updated_at', v_row.updated_at,
    'storage_pct',
      case
        when v_row.storage_limit_bytes = 0 then 0
        else round(
          (v_row.storage_used_bytes::numeric / v_row.storage_limit_bytes::numeric) * 100,
          2
        )
      end,
    'egress_pct',
      case
        when v_row.egress_limit_bytes = 0 then 0
        else round(
          (v_row.egress_used_bytes::numeric / v_row.egress_limit_bytes::numeric) * 100,
          2
        )
      end
  );
end;
$$;

-- 6. RPC: increment storage for authenticated uploader.
create or replace function public.increment_archive_storage(p_bytes bigint)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_limit bigint;
  v_used bigint;
begin
  if v_uid is null then
    raise exception 'Authenticated user required';
  end if;

  if p_bytes is null or p_bytes <= 0 then
    return;
  end if;

  insert into public.archive_quotas (user_id)
  values (v_uid)
  on conflict (user_id) do nothing;

  select t.storage_limit_bytes, aq.storage_used_bytes
    into v_limit, v_used
  from public.archive_quotas aq
  join public.archive_tiers t on t.tier_id = aq.tier_id
  where aq.user_id = v_uid
  for update of aq;

  if v_used + p_bytes > v_limit then
    raise exception 'Archive storage limit reached';
  end if;

  update public.archive_quotas
  set storage_used_bytes = storage_used_bytes + p_bytes,
      updated_at = now()
  where user_id = v_uid;
end;
$$;

-- 7. RPC: increment egress for package owner (courier unlock path).
create or replace function public.increment_archive_egress(
  p_owner_id uuid,
  p_bytes bigint
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_limit bigint;
  v_used bigint;
  v_effective_bytes bigint := greatest(coalesce(p_bytes, 0), 0);
begin
  if p_owner_id is null then
    raise exception 'Archive owner required';
  end if;

  perform private.reset_archive_egress_if_needed(p_owner_id);

  insert into public.archive_quotas (user_id)
  values (p_owner_id)
  on conflict (user_id) do nothing;

  select t.egress_limit_bytes, aq.egress_used_bytes
    into v_limit, v_used
  from public.archive_quotas aq
  join public.archive_tiers t on t.tier_id = aq.tier_id
  where aq.user_id = p_owner_id
  for update of aq;

  if v_used + v_effective_bytes > v_limit then
    raise exception 'Archive egress limit reached';
  end if;

  update public.archive_quotas
  set egress_used_bytes = egress_used_bytes + v_effective_bytes,
      updated_at = now()
  where user_id = p_owner_id;
end;
$$;

-- 8. RPC: set tier after billing confirmation (mock gateway today).
create or replace function public.set_archive_tier(p_tier_id text)
returns void
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

  if not exists (
    select 1 from public.archive_tiers t where t.tier_id = p_tier_id
  ) then
    raise exception 'Unknown archive tier';
  end if;

  insert into public.archive_quotas (user_id, tier_id)
  values (v_uid, p_tier_id)
  on conflict (user_id) do update
    set tier_id = excluded.tier_id,
        updated_at = now();
end;
$$;

-- 9. Patch attempt_courier_unlock to meter owner egress (byte-weighted).
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
  asset_hash text
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
      v_package.asset_hash;
end;
$$;

revoke all on function public.get_my_archive_quota() from public;
grant execute on function public.get_my_archive_quota() to authenticated, service_role;

revoke all on function public.increment_archive_storage(bigint) from public;
grant execute on function public.increment_archive_storage(bigint) to authenticated, service_role;

revoke all on function public.increment_archive_egress(uuid, bigint) from public;
grant execute on function public.increment_archive_egress(uuid, bigint) to service_role;

revoke all on function public.set_archive_tier(text) from public;
grant execute on function public.set_archive_tier(text) to authenticated, service_role;

notify pgrst, 'reload schema';
