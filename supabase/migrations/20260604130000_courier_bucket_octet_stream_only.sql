-- Align courier-blobs bucket with client uploads (application/octet-stream only).

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'courier-blobs',
  'courier-blobs',
  false,
  52428800,
  array['application/octet-stream']::text[]
)
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

notify pgrst, 'reload schema';
