-- Idempotent: hosted QA / partial restores may miss the bucket row even when
-- app code expects uploads to `courier-blobs`.
insert into storage.buckets (id, name, public)
values ('courier-blobs', 'courier-blobs', false)
on conflict (id) do update
  set public = false;

notify pgrst, 'reload schema';
