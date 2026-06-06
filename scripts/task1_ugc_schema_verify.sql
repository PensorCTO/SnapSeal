-- Task 1 verification probes (read-only). Run via:
--   ./scripts/factlockcam_supabase_pipeline.sh query-file scripts/task1_ugc_schema_verify.sql

-- 1. Tables exist
select 'courier_content_reports' as object,
       exists (
         select 1 from information_schema.tables
         where table_schema = 'public' and table_name = 'courier_content_reports'
       ) as present;

select 'courier_sender_blocks' as object,
       exists (
         select 1 from information_schema.tables
         where table_schema = 'public' and table_name = 'courier_sender_blocks'
       ) as present;

select 'courier_moderation_queue' as object,
       exists (
         select 1 from information_schema.tables
         where table_schema = 'public' and table_name = 'courier_moderation_queue'
       ) as present;

-- 2. moderation_status column
select column_name, data_type
from information_schema.columns
where table_schema = 'public'
  and table_name = 'courier_packages'
  and column_name = 'moderation_status';

-- 3. RPCs exist
select p.proname as rpc_name,
       pg_get_function_identity_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'report_courier_package',
    'get_public_proof_attestation',
    'block_courier_sender',
    'check_sender_blocked_for_reporter'
  )
order by p.proname;

-- 4. RLS enabled
select c.relname as table_name, c.relrowsecurity as rls_enabled
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in (
    'courier_content_reports',
    'courier_sender_blocks',
    'courier_moderation_queue'
  );

-- 5. courier_content_reports policies
select policyname, cmd, roles
from pg_policies
where schemaname = 'public' and tablename = 'courier_content_reports';

-- 6. Table grants (client INSERT only expected for reports)
select grantee, privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name = 'courier_content_reports'
order by grantee, privilege_type;
