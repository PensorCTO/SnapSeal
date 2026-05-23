-- Migration: Optimize Courier Lookups
-- Target: eliminate sequential scans for attempt_courier_unlock RPC

alter table public.courier_packages
  add column if not exists unlock_code text,
  add column if not exists status text not null default 'available';

update public.courier_packages cp
set
  unlock_code = coalesce(cp.unlock_code, cp.package_id::text),
  status = case
    when cp.burned_at is not null or cp.is_bricked then 'locked'
    when cp.expires_at is not null and cp.expires_at <= now() then 'expired'
    when cp.failed_attempts >= cp.max_attempts then 'locked'
    when cp.download_count >= cp.max_downloads then 'locked'
    when cp.unlocked_at is not null then 'unlocked'
    else 'available'
  end
where cp.unlock_code is null
   or cp.status = 'available';

create index if not exists idx_courier_packages_unlock_code
  on public.courier_packages using btree (unlock_code, status);

-- Justification: structured migrations prevent schema drift between
-- development and production environments, ensuring resilience under high traffic.

notify pgrst, 'reload schema';
