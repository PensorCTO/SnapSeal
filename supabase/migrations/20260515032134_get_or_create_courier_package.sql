-- Mobile courier origination: create or refresh an owner-scoped package row.

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

  -- Refresh the most recent package for the same asset instead of creating
  -- duplicate black-box links. The storage path is deterministic client-side,
  -- so the blob upload can safely upsert before this RPC.
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
        last_failed_at = null,
        requestor_email = null,
        unlocked_at = null,
        burned_at = null,
        expires_at = null,
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
    verifier_secret_hash
  )
  values (
    v_owner_id,
    trim(p_asset_hash),
    'courier-blobs',
    trim(p_storage_path),
    lower(trim(p_file_extension)),
    trim(p_encoded_vault_key),
    v_verifier_secret_hash
  )
  returning package_id into v_package_id;

  return v_package_id;
end;
$$;

revoke all on function public.get_or_create_courier_package(text, text, text, text, text) from public;
grant execute on function public.get_or_create_courier_package(text, text, text, text, text)
  to authenticated, service_role;

notify pgrst, 'reload schema';
