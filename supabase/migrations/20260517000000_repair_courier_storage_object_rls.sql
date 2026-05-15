-- Fix Storage 403 / RLS on courier uploads when policies were never applied (e.g. bucket
-- created only in Dashboard) or need a clearer path check than storage.foldername(name).
--
-- Path contract (mobile): "{auth.uid()}/{assetFingerprint}{ext}.seal"

-- IaC: ensure the private courier bucket exists (no Dashboard/manual step required).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'courier-blobs',
  'courier-blobs',
  false,
  52428800, -- 50MB limit
  array[
    'application/octet-stream',
    'image/jpeg',
    'video/mp4',
    'application/pdf'
  ]::text[]
)
on conflict (id) do update
set public = false;

drop policy if exists "Courier owners upload encrypted blobs" on storage.objects;
drop policy if exists "Courier owners read own encrypted blobs" on storage.objects;
drop policy if exists "Courier owners update own encrypted blobs" on storage.objects;
drop policy if exists "Courier owners delete own encrypted blobs" on storage.objects;
drop policy if exists "Recipients read active encrypted courier blobs" on storage.objects;

create policy "Courier owners upload encrypted blobs"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'courier-blobs'
    and split_part(ltrim(name, '/'), '/', 1) = auth.uid()::text
  );

create policy "Courier owners read own encrypted blobs"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'courier-blobs'
    and split_part(ltrim(name, '/'), '/', 1) = auth.uid()::text
  );

create policy "Courier owners update own encrypted blobs"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'courier-blobs'
    and split_part(ltrim(name, '/'), '/', 1) = auth.uid()::text
  )
  with check (
    bucket_id = 'courier-blobs'
    and split_part(ltrim(name, '/'), '/', 1) = auth.uid()::text
  );

create policy "Courier owners delete own encrypted blobs"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'courier-blobs'
    and split_part(ltrim(name, '/'), '/', 1) = auth.uid()::text
  );

create policy "Recipients read active encrypted courier blobs"
  on storage.objects
  for select
  to anon
  using (
    bucket_id = 'courier-blobs'
    and exists (
      select 1
      from public.courier_packages cp
      where cp.storage_bucket = storage.objects.bucket_id
        and cp.storage_path = ltrim(storage.objects.name, '/')
        and cp.burned_at is null
        and (cp.expires_at is null or cp.expires_at > now())
    )
  );

notify pgrst, 'reload schema';
