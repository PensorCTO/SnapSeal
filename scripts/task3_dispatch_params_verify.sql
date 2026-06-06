-- Task 3: verify get_or_create_courier_package accepts dispatch policy params.
-- Run via: ./scripts/factlockcam_supabase_pipeline.sh query-file scripts/task3_dispatch_params_verify.sql

-- 1. Function signatures (expect 9-parameter variant with dispatch params)
select
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as arguments
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'get_or_create_courier_package'
order by arguments;

-- 2. Dispatch param argument names present
select
  case
    when exists (
      select 1
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public'
        and p.proname = 'get_or_create_courier_package'
        and pg_get_function_identity_arguments(p.oid) like '%p_max_downloads%'
        and pg_get_function_identity_arguments(p.oid) like '%p_link_ttl_days%'
    ) then 'OK: dispatch params on get_or_create_courier_package'
    else 'FAIL: missing p_max_downloads or p_link_ttl_days'
  end as dispatch_params_check;

-- 3. Recent package policy fields (no owner_id)
select
  package_id,
  max_downloads,
  expires_at,
  download_count,
  updated_at
from public.courier_packages
order by updated_at desc nulls last
limit 5;
