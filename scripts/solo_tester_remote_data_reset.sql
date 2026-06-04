-- Solo tester hosted reset: keep one legitimate proof row, purge orphaned ledgers.
-- Run (loads .env.local for link):
--   ./scripts/factlockcam_supabase_pipeline.sh query-file scripts/solo_tester_remote_data_reset.sql
--
-- Edit v_keep_asset_hash if the keeper row changes (default: newest proof_ledger row).

do $$
declare
  v_user_id uuid := '8b625de2-a79f-4519-9cd8-36e1479df351';
  v_wallet_id uuid;
  v_keep_asset_hash text := 'a283f677876df4b5d7764a1753bdaa1c32001f0746217ccdaa85a64477b0ff55';
begin
  select p.wallet_id into v_wallet_id
  from public.profiles p
  where p.id = v_user_id;

  if v_wallet_id is null then
    raise exception 'Profile not found for solo tester user_id %', v_user_id;
  end if;

  -- Note: hosted Supabase blocks direct DELETE on storage.objects (protect_delete).
  -- Orphaned courier-blobs are removed via Dashboard Storage or a service-role script.
  -- Ledger tables below are the source of truth for app/courier UX.

  delete from public.courier_packages
  where owner_id = v_user_id
    and asset_hash is distinct from v_keep_asset_hash;

  delete from public.proof_ledger pl
  where pl.wallet_id = v_wallet_id
    and pl.asset_hash is distinct from v_keep_asset_hash;

  delete from public.metered_consumption_ledger
  where user_id = v_user_id;

  delete from public.subscription_cycles
  where user_id = v_user_id;

  update public.archive_quotas aq
  set storage_used_bytes = 0,
      egress_used_bytes = 0,
      egress_period_start = date_trunc('month', now()),
      updated_at = now()
  where aq.user_id = v_user_id;

  delete from public.wallet_history
  where owner_id = v_user_id;
end;
$$;
