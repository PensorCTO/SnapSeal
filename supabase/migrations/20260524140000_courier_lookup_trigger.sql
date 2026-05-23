-- Keep courier unlock_code/status populated for new and refreshed packages.

create or replace function public.sync_courier_package_lookup_fields()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.unlock_code is null or btrim(new.unlock_code) = '' then
    new.unlock_code := new.package_id::text;
  end if;

  new.status :=
    case
      when new.is_bricked or new.burned_at is not null then 'locked'
      when new.expires_at is not null and new.expires_at <= now() then 'expired'
      when new.download_count >= new.max_downloads then 'exhausted'
      when new.failed_attempts >= new.max_attempts then 'locked'
      when new.unlocked_at is not null then 'unlocked'
      else 'available'
    end;

  return new;
end;
$$;

drop trigger if exists courier_packages_sync_lookup_fields on public.courier_packages;

create trigger courier_packages_sync_lookup_fields
  before insert or update on public.courier_packages
  for each row
  execute function public.sync_courier_package_lookup_fields();

notify pgrst, 'reload schema';
