-- Web courier foundation: RPC-only package unlock surface for browser recipients.

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.courier_packages (
  package_id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  asset_hash text not null,
  storage_bucket text not null default 'courier-blobs',
  storage_path text not null unique,
  file_extension text not null,
  vault_key text not null,
  verifier_secret_hash text not null,
  requestor_email text,
  failed_attempts integer not null default 0 check (failed_attempts >= 0),
  max_attempts integer not null default 5 check (max_attempts > 0),
  last_failed_at timestamptz,
  unlocked_at timestamptz,
  burned_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.courier_packages enable row level security;

grant select, insert, update, delete on table public.courier_packages to authenticated;

drop policy if exists "Users select own courier packages" on public.courier_packages;
drop policy if exists "Users insert own courier packages" on public.courier_packages;
drop policy if exists "Users update own courier packages" on public.courier_packages;
drop policy if exists "Users delete own courier packages" on public.courier_packages;

create policy "Users select own courier packages"
  on public.courier_packages
  for select
  to authenticated
  using (owner_id = auth.uid());

create policy "Users insert own courier packages"
  on public.courier_packages
  for insert
  to authenticated
  with check (owner_id = auth.uid());

create policy "Users update own courier packages"
  on public.courier_packages
  for update
  to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create policy "Users delete own courier packages"
  on public.courier_packages
  for delete
  to authenticated
  using (owner_id = auth.uid());

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists courier_packages_set_updated_at on public.courier_packages;
create trigger courier_packages_set_updated_at
  before update on public.courier_packages
  for each row execute function public.set_updated_at();

insert into storage.buckets (id, name, public)
values ('courier-blobs', 'courier-blobs', false)
on conflict (id) do update
  set public = false;

drop policy if exists "Courier owners upload encrypted blobs" on storage.objects;
drop policy if exists "Courier owners read own encrypted blobs" on storage.objects;
drop policy if exists "Courier owners update own encrypted blobs" on storage.objects;
drop policy if exists "Courier owners delete own encrypted blobs" on storage.objects;
drop policy if exists "Recipients read active encrypted courier blobs" on storage.objects;

create policy "Courier owners upload encrypted blobs"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'courier-blobs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Courier owners read own encrypted blobs"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'courier-blobs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Courier owners update own encrypted blobs"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'courier-blobs'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'courier-blobs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Courier owners delete own encrypted blobs"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'courier-blobs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Recipients read active encrypted courier blobs"
  on storage.objects
  for select
  to anon
  using (
    bucket_id = 'courier-blobs'
    and exists (
      select 1
      from public.courier_packages cp
      where cp.storage_bucket = storage.objects.bucket_id
        and cp.storage_path = storage.objects.name
        and cp.burned_at is null
        and (cp.expires_at is null or cp.expires_at > now())
    )
  );

create or replace function public.check_courier_attempts(p_package_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_package public.courier_packages%rowtype;
begin
  select *
    into v_package
    from public.courier_packages
    where package_id = p_package_id;

  if not found then
    return jsonb_build_object(
      'status', 'not_found',
      'locked', true,
      'attempts_remaining', 0
    );
  end if;

  return jsonb_build_object(
    'status',
      case
        when v_package.burned_at is not null then 'burned'
        when v_package.expires_at is not null and v_package.expires_at <= now() then 'expired'
        when v_package.failed_attempts >= v_package.max_attempts then 'locked'
        else 'available'
      end,
    'locked',
      v_package.burned_at is not null
      or (v_package.expires_at is not null and v_package.expires_at <= now())
      or v_package.failed_attempts >= v_package.max_attempts,
    'attempts_remaining',
      greatest(v_package.max_attempts - v_package.failed_attempts, 0),
    'max_attempts', v_package.max_attempts
  );
end;
$$;

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

  if v_package.burned_at is not null
      or (v_package.expires_at is not null and v_package.expires_at <= now())
      or v_package.failed_attempts >= v_package.max_attempts then
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
        set burned_at = now()
        where cp.package_id = p_package_id;

      delete from storage.objects so
      where so.bucket_id = v_package.storage_bucket
        and so.name = v_package.storage_path;
    end if;

    raise exception 'Invalid verifier challenge';
  end if;

  update public.courier_packages cp
    set unlocked_at = now(),
        requestor_email = nullif(p_requestor_email, '')
    where cp.package_id = p_package_id
    returning * into v_package;

  return query
    select
      v_package.vault_key,
      v_package.file_extension,
      v_package.storage_bucket,
      v_package.storage_path,
      v_package.asset_hash;
end;
$$;

revoke all on function public.check_courier_attempts(uuid) from public;
revoke all on function public.attempt_courier_unlock(uuid, text, text) from public;
grant execute on function public.check_courier_attempts(uuid) to anon, authenticated, service_role;
grant execute on function public.attempt_courier_unlock(uuid, text, text) to anon, authenticated, service_role;

notify pgrst, 'reload schema';
