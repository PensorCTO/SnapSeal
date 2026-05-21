-- Migration: Optimize Courier Lookups for Web Vault
-- Rationale: The web app queries these RPC-backed surfaces via deep links.

create index if not exists idx_courier_packages_id
  on public.courier_packages (package_id);

create index if not exists idx_courier_packages_hash
  on public.courier_packages (asset_hash);

create index if not exists idx_courier_packages_owner
  on public.courier_packages (owner_id)
  where owner_id is not null;

create index if not exists idx_courier_packages_active_storage
  on public.courier_packages (storage_bucket, storage_path)
  where burned_at is null;

grant execute on function public.check_courier_attempts(uuid) to anon;

notify pgrst, 'reload schema';
