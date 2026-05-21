-- Polygon saga: async notarization status, nullable chain tx, EVM address on profiles.

alter table public.profiles
  add column if not exists evm_address text;

grant update (evm_address) on table public.profiles to authenticated;

drop policy if exists "Users update own profile evm address" on public.profiles;
create policy "Users update own profile evm address"
  on public.profiles
  for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

alter table public.proof_ledger
  drop constraint if exists proof_ledger_chain_tx_hash_fkey;

alter table public.proof_ledger
  alter column chain_tx_hash drop not null;

alter table public.proof_ledger
  add column if not exists notarization_status text not null default 'notarized';

alter table public.proof_ledger
  drop constraint if exists proof_ledger_notarization_status_check;

alter table public.proof_ledger
  add constraint proof_ledger_notarization_status_check
  check (
    notarization_status in (
      'pending_notarization',
      'notarized',
      'failed'
    )
  );

-- Backfill existing rows (simulated path) as finalized.
update public.proof_ledger
set notarization_status = 'notarized'
where notarization_status is null
   or notarization_status = 'notarized';

-- Realtime publication for monitor service (idempotent).
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'proof_ledger'
  ) then
    alter publication supabase_realtime add table public.proof_ledger;
  end if;
end $$;

-- Service-role finalizer invoked by anchor-relay after relay success.
create or replace function public.finalize_polygon_notarization(
  p_asset_hash text,
  p_chain_tx_hash text,
  p_wallet_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.proof_ledger
  set
    chain_tx_hash = p_chain_tx_hash,
    notarization_status = 'notarized',
    sealed_at = coalesce(sealed_at, now())
  where asset_hash = p_asset_hash
    and wallet_id = p_wallet_id
    and notarization_status = 'pending_notarization';
end;
$$;

revoke all on function public.finalize_polygon_notarization(text, text, uuid) from public;
grant execute on function public.finalize_polygon_notarization(text, text, uuid) to service_role;

-- Mark relay failures without dropping the pending local asset.
create or replace function public.fail_polygon_notarization(
  p_asset_hash text,
  p_wallet_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.proof_ledger
  set notarization_status = 'failed'
  where asset_hash = p_asset_hash
    and wallet_id = p_wallet_id
    and notarization_status = 'pending_notarization';
end;
$$;

revoke all on function public.fail_polygon_notarization(text, uuid) from public;
grant execute on function public.fail_polygon_notarization(text, uuid) to service_role;
