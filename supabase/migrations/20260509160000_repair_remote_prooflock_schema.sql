-- Repair hosted DB drift: proof_ledger on some projects was an older ad-hoc shape
-- (e.g. owner_id, tx_hash) and never had simulated_chain_ledger or
-- simulate_chain_notarize, while schema_migrations could still list the
-- 20260503120000 migration as applied. This migration force-aligns the FactLockCam
-- proof surface to match 20260503120000_prooflock_simulated_chain.sql.
-- WARNING: drops proof ledger tables; any data in those tables is lost.

drop table if exists public.proof_ledger cascade;
drop table if exists public.simulated_chain_ledger cascade;

create table public.simulated_chain_ledger (
  id uuid primary key default gen_random_uuid(),
  wallet_id uuid not null references public.profiles (wallet_id) on delete cascade,
  asset_fingerprint text not null,
  device_signature text not null,
  simulated_tx_hash text not null unique,
  created_at timestamptz not null default now()
);

create index if not exists simulated_chain_ledger_wallet_id_idx
  on public.simulated_chain_ledger (wallet_id);

create table public.proof_ledger (
  asset_hash text primary key,
  wallet_id uuid not null references public.profiles (wallet_id) on delete cascade,
  device_signature text not null,
  chain_tx_hash text not null references public.simulated_chain_ledger (simulated_tx_hash) on delete restrict,
  sealed_at timestamptz not null default now()
);

create index if not exists proof_ledger_wallet_id_idx
  on public.proof_ledger (wallet_id);

alter table public.simulated_chain_ledger enable row level security;
alter table public.proof_ledger enable row level security;

grant select, insert on table public.simulated_chain_ledger to authenticated;
grant select, insert on table public.proof_ledger to authenticated;

drop policy if exists "Public read simulated chain ledger" on public.simulated_chain_ledger;
drop policy if exists "Users insert own simulated chain rows" on public.simulated_chain_ledger;
drop policy if exists "Public read proof ledger" on public.proof_ledger;
drop policy if exists "Users insert own proof ledger rows" on public.proof_ledger;

create policy "Public read simulated chain ledger"
  on public.simulated_chain_ledger
  for select
  using (true);

create policy "Users insert own simulated chain rows"
  on public.simulated_chain_ledger
  for insert
  to authenticated
  with check (
    wallet_id = (
      select profiles.wallet_id
      from public.profiles
      where profiles.id = auth.uid()
    )
  );

create policy "Public read proof ledger"
  on public.proof_ledger
  for select
  using (true);

create policy "Users insert own proof ledger rows"
  on public.proof_ledger
  for insert
  to authenticated
  with check (
    wallet_id = (
      select profiles.wallet_id
      from public.profiles
      where profiles.id = auth.uid()
    )
  );

create or replace function public.check_proof_status(p_file_hash text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_wallet uuid;
  v_owner uuid;
begin
  select pl.wallet_id
    into v_wallet
    from public.proof_ledger pl
    where pl.asset_hash = p_file_hash;

  if v_wallet is null then
    return 'new';
  end if;

  select p.id
    into v_owner
    from public.profiles p
    where p.wallet_id = v_wallet;

  if v_owner is null then
    return 'anonymous';
  end if;

  if v_owner = auth.uid() then
    return 'owned_by_me';
  end if;

  return 'owned_by_other';
end;
$$;

revoke all on function public.check_proof_status(text) from public;
grant execute on function public.check_proof_status(text) to authenticated;
grant execute on function public.check_proof_status(text) to service_role;

create or replace function public.simulate_chain_notarize(
  p_file_hash text,
  p_device_signature text
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_wallet uuid;
  v_tx text;
begin
  select profiles.wallet_id
    into v_wallet
    from public.profiles
    where profiles.id = auth.uid();

  if v_wallet is null then
    raise exception 'No wallet_id for current user';
  end if;

  v_tx := gen_random_uuid()::text;

  insert into public.simulated_chain_ledger (
    wallet_id,
    asset_fingerprint,
    device_signature,
    simulated_tx_hash
  ) values (
    v_wallet,
    p_file_hash,
    p_device_signature,
    v_tx
  );

  return v_tx;
end;
$$;

revoke all on function public.simulate_chain_notarize(text, text) from public;
grant execute on function public.simulate_chain_notarize(text, text) to authenticated;
grant execute on function public.simulate_chain_notarize(text, text) to service_role;

-- Ensure PostgREST refreshes RPC metadata immediately after migration.
notify pgrst, 'reload schema';
