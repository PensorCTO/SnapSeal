-- Replace world-readable SELECT on ledger replicas with wallet-scoped reads for
-- authenticated sessions. INSERT policies unchanged; UPDATE/DELETE remain
-- absent (immutable append-only ledgers).

drop policy if exists "Public read of active wallet ledger" on public.seal_ledger;

create policy "Users select own wallet seal ledger rows"
  on public.seal_ledger
  for select
  to authenticated
  using (
    wallet_id = (
      select profiles.wallet_id
      from public.profiles
      where profiles.id = auth.uid()
    )
  );

drop policy if exists "Public read simulated chain ledger" on public.simulated_chain_ledger;

create policy "Users select own wallet simulated chain rows"
  on public.simulated_chain_ledger
  for select
  to authenticated
  using (
    wallet_id = (
      select profiles.wallet_id
      from public.profiles
      where profiles.id = auth.uid()
    )
  );

drop policy if exists "Public read proof ledger" on public.proof_ledger;

create policy "Users select own wallet proof ledger rows"
  on public.proof_ledger
  for select
  to authenticated
  using (
    wallet_id = (
      select profiles.wallet_id
      from public.profiles
      where profiles.id = auth.uid()
    )
  );

notify pgrst, 'reload schema';
