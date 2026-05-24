-- App Store remediation: courier unlock latency for Send Proof E2E review path.
-- package_hash in product spec maps to asset_hash (content fingerprint column).

create index if not exists idx_courier_packages_package_hash
  on public.courier_packages using btree (asset_hash);

create index if not exists idx_courier_packages_id_expires_at
  on public.courier_packages using btree (package_id, expires_at);

-- Accelerates get_or_create_courier_package owner + fingerprint lookup.
create index if not exists idx_courier_packages_owner_asset_hash
  on public.courier_packages using btree (owner_id, asset_hash);

notify pgrst, 'reload schema';
