-- Improve Realtime UPDATE payloads for proof_ledger saga monitor fallback.
ALTER TABLE public.proof_ledger REPLICA IDENTITY FULL;
