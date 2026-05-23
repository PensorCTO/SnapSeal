-- Send Proof cost control: download quotas, mandatory expiry, and RPC gatekeeping.

alter table public.courier_packages
  add column if not exists max_downloads integer not null default 3
    check (max_downloads > 0),
  add column if not exists download_count integer not null default 0
    check (download_count >= 0),
  add column if not exists is_bricked boolean not null default false;

update public.courier_packages
  set expires_at = created_at + interval '7 days'
  where expires_at is null;

update public.courier_packages
  set is_bricked = true
  where burned_at is not null and is_bricked = false;

alter table public.courier_packages
  alter column expires_at set default (now() + interval '7 days');

-- Origination: refresh packages with TTL + reset download counters.
create or replace function public.get_or_create_courier_package(
  p_asset_hash text,
  p_verifier_password text,
  p_encoded_vault_key text,
  p_file_extension text,
  p_storage_path text
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
    now() + interval '7 days'
  )
  returning package_id into v_package_id;

  return v_package_id;
end;
$$;

create or replace function public.check_courier_attempts(p_package_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_package public.courier_packages%rowtype;
  v_locked boolean;
  v_status text;
begin
  select *
    into v_package
    from public.courier_packages
    where package_id = p_package_id;

  if not found then
    return jsonb_build_object(
      'status', 'not_found',
      'locked', true,
      'attempts_remaining', 0,
      'downloads_remaining', 0
    );
  end if;

  v_locked :=
    v_package.is_bricked
    or v_package.burned_at is not null
    or v_package.expires_at <= now()
    or v_package.failed_attempts >= v_package.max_attempts
    or v_package.download_count >= v_package.max_downloads;

  v_status :=
    case
      when v_package.is_bricked or v_package.burned_at is not null then 'burned'
      when v_package.expires_at <= now() then 'expired'
      when v_package.download_count >= v_package.max_downloads then 'exhausted'
      when v_package.failed_attempts >= v_package.max_attempts then 'locked'
      else 'available'
    end;

  return jsonb_build_object(
    'status', v_status,
    'locked', v_locked,
    'attempts_remaining',
      greatest(v_package.max_attempts - v_package.failed_attempts, 0),
    'max_attempts', v_package.max_attempts,
    'downloads_remaining',
      greatest(v_package.max_downloads - v_package.download_count, 0),
    'max_downloads', v_package.max_downloads,
    'expires_at', v_package.expires_at
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

  return query
    select
      v_package.vault_key,
      v_package.file_extension,
      v_package.storage_bucket,
      v_package.storage_path,
      v_package.asset_hash;
end;
$$;

drop policy if exists "Recipients read active encrypted courier blobs" on storage.objects;

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
        and cp.storage_path = ltrim(storage.objects.name, '/')
        and cp.burned_at is null
        and cp.is_bricked = false
        and cp.expires_at > now()
        and cp.download_count <= cp.max_downloads
        and cp.unlocked_at is not null
    )
  );

revoke all on function public.get_or_create_courier_package(text, text, text, text, text) from public;
grant execute on function public.get_or_create_courier_package(text, text, text, text, text)
  to authenticated, service_role;

revoke all on function public.check_courier_attempts(uuid) from public;
revoke all on function public.attempt_courier_unlock(uuid, text, text) from public;
grant execute on function public.check_courier_attempts(uuid) to anon, authenticated, service_role;
grant execute on function public.attempt_courier_unlock(uuid, text, text) to anon, authenticated, service_role;

notify pgrst, 'reload schema';
