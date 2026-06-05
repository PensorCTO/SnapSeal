---
tags: [analysis, factlockcam, rls, security, zero_trust, june_2026]
summary: "June 2026 RLS audit matrix proving AES-GCM key isolation and user-scoped courier/proof access."
---

# Zero-Trust RLS Audit (2026-06)

## Core Synthesis

Audit of Row Level Security and RPC gating for zero-trust communication primitive positioning. Plaintext AES keys must never be readable by `anon` via direct table SELECT.

### `courier_packages`

| Role | SELECT | INSERT | UPDATE | DELETE |
|------|--------|--------|--------|--------|
| `authenticated` | own rows (`owner_id = auth.uid()`) | own rows | own rows | own rows |
| `anon` | **denied** | **denied** | **denied** | **denied** |

**Key column `vault_key`:** Returned only via `attempt_courier_unlock` after successful verifier — never in direct SELECT for recipients. **PR9 deferred rename** to `archive_key`.

**RPC-only reads for recipients:** `check_courier_attempts`, `attempt_courier_unlock` (SECURITY DEFINER).

### `courier_content_reports` / `courier_sender_blocks`

| Role | INSERT | SELECT |
|------|--------|--------|
| `anon` / `authenticated` | reports: yes | **denied** (RPC/service only) |
| blocks | RPC-only (`block_courier_sender`) | **denied** |

### `courier_moderation_queue`

| Role | All ops |
|------|---------|
| clients | **denied** (service role + `courier-content-scan` only) |

### `proof_ledger`

| Role | Access pattern |
|------|----------------|
| `authenticated` | owner-scoped policies per saga migrations |
| pre-flight | `check_proof_status` SECURITY DEFINER — global hash collision check only |

### `archive_quotas` / `subscription_cycles`

Mutations via SECURITY DEFINER RPCs (`get_my_archive_quota`, metering RPCs). Direct client UPDATE forbidden.

### Storage `courier-blobs`

| Role | Pattern |
|------|---------|
| `authenticated` | CRUD under `{auth.uid()}/` prefix |
| `anon` | SELECT only when package unlocked, not burned, within download quota |

### Storage `factlock_vault`

Owner-prefix RLS; ciphertext `.seal` blobs only. **Bucket rename deferred (PR9).**

### Zero-trust proof

1. Recipients cannot enumerate `courier_packages` or read `vault_key` without verifier success.
2. Reporters cannot learn `owner_id` from report RPC responses.
3. Local AES keys remain in Secure Storage / `.factlock` — not in Postgres columns accessible to anon.

## Provenance Tracking

* *Audit*: `supabase/migrations/20260605120000_ugc_safety_infrastructure.sql` + prior courier migrations (2026-06-05); migration **pushed hosted** same day via `factlockcam_supabase_pipeline.sh push`.

## Related Notes

* [[UGC_Safety_Reporting_2026-06]]
* [[Compliance_Refactor_2026-06]]
* [[Compliance_Refactor_2026-06]]
