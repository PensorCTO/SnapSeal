-- Polygon transaction indexing for NotarizationMonitorService.
--
-- Adds indexes to support high-frequency polling from the monitor service
-- which looks up pending transactions by chain_tx_hash and status.

-- Index for RPC polling: the monitor fetches receipts by chain_tx_hash
-- after the relay returns from broadcast.
create index if not exists idx_proof_ledger_chain_tx_hash
  on public.proof_ledger using btree (chain_tx_hash)
  where chain_tx_hash is not null;

-- Index for pending-status lookups: the monitor queries for assets
-- that still need on-chain confirmation.
create index if not exists idx_proof_ledger_notarization_status
  on public.proof_ledger using btree (notarization_status);
