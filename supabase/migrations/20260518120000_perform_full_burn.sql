-- App Store account deletion: permanently remove remote user data and auth identity.
-- Client must still burn the local wallet after a successful RPC.

create or replace function public.perform_full_burn()
returns void
language plpgsql
security definer
set search_path = public, auth, storage
as $$
declare
  v_uid uuid := auth.uid();
  v_pkg record;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  for v_pkg in
    select cp.storage_bucket, cp.storage_path
    from public.courier_packages cp
    where cp.owner_id = v_uid
  loop
    delete from storage.objects so
    where so.bucket_id = v_pkg.storage_bucket
      and so.name = v_pkg.storage_path;
  end loop;

  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.perform_full_burn() from public;
grant execute on function public.perform_full_burn() to authenticated;

notify pgrst, 'reload schema';
