-- Phase 1: compliant tier display names + per-tier single-capture cap (free = 50 MB).

alter table public.archive_tiers
  add column if not exists max_single_capture_bytes bigint
    check (max_single_capture_bytes is null or max_single_capture_bytes > 0);

update public.archive_tiers
set
  display_name = 'Sovereign Free Baseline',
  max_single_capture_bytes = 52428800
where tier_id = 'free';

update public.archive_tiers
set
  display_name = 'Core Pro Tier',
  max_single_capture_bytes = null
where tier_id = 'picture';

update public.archive_tiers
set
  display_name = 'Sovereign Archivist',
  max_single_capture_bytes = null
where tier_id = 'video';

create or replace function public.get_my_archive_quota()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_row record;
begin
  if v_uid is null then
    raise exception 'Authenticated user required';
  end if;

  perform private.reset_archive_egress_if_needed(v_uid);

  insert into public.archive_quotas (user_id)
  values (v_uid)
  on conflict (user_id) do nothing;

  select
    aq.user_id,
    aq.tier_id,
    aq.storage_used_bytes,
    aq.egress_used_bytes,
    aq.egress_period_start,
    aq.updated_at,
    t.display_name,
    t.storage_limit_bytes,
    t.egress_limit_bytes,
    t.monthly_price_cents,
    t.max_single_capture_bytes
  into v_row
  from public.archive_quotas aq
  join public.archive_tiers t on t.tier_id = aq.tier_id
  where aq.user_id = v_uid;

  return jsonb_build_object(
    'user_id', v_row.user_id,
    'tier_id', v_row.tier_id,
    'display_name', v_row.display_name,
    'storage_used_bytes', v_row.storage_used_bytes,
    'storage_limit_bytes', v_row.storage_limit_bytes,
    'egress_used_bytes', v_row.egress_used_bytes,
    'egress_limit_bytes', v_row.egress_limit_bytes,
    'egress_period_start', v_row.egress_period_start,
    'monthly_price_cents', v_row.monthly_price_cents,
    'max_single_capture_bytes', v_row.max_single_capture_bytes,
    'updated_at', v_row.updated_at,
    'storage_pct',
      case
        when v_row.storage_limit_bytes = 0 then 0
        else round(
          (v_row.storage_used_bytes::numeric / v_row.storage_limit_bytes::numeric) * 100,
          2
        )
      end,
    'egress_pct',
      case
        when v_row.egress_limit_bytes = 0 then 0
        else round(
          (v_row.egress_used_bytes::numeric / v_row.egress_limit_bytes::numeric) * 100,
          2
        )
      end
  );
end;
$$;

notify pgrst, 'reload schema';
