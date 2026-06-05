-- Anon-safe public proof attestation for courier unlock proof panel.
-- Returns only non-PII ledger fields for a given asset hash.

create or replace function public.get_public_proof_attestation(p_asset_hash text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.proof_ledger%rowtype;
  v_hash text := lower(trim(coalesce(p_asset_hash, '')));
begin
  if v_hash = '' then
    return jsonb_build_object('found', false, 'error', 'asset_hash required');
  end if;

  select *
    into v_row
    from public.proof_ledger pl
    where lower(pl.asset_hash) = v_hash
      and pl.notarization_status = 'notarized'
    order by pl.sealed_at desc nulls last
    limit 1;

  if not found then
    return jsonb_build_object('found', false);
  end if;

  return jsonb_build_object(
    'found', true,
    'chain_tx_hash', v_row.chain_tx_hash,
    'sealed_at', v_row.sealed_at,
    'notarization_status', v_row.notarization_status,
    'block_number', null
  );
end;
$$;

revoke all on function public.get_public_proof_attestation(text) from public;
grant execute on function public.get_public_proof_attestation(text)
  to anon, authenticated, service_role;

notify pgrst, 'reload schema';
