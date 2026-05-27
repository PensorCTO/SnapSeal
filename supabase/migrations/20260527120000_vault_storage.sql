-- Cloud vault storage: private factlock_vault bucket + courier_packages metadata alignment.
-- Plaintext never touches Supabase; clients upload AES-GCM ciphertext only.

-- 1. Create private storage bucket (50MB per object, octet-stream only).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'factlock_vault',
  'factlock_vault',
  false,
  52428800,
  array['application/octet-stream']::text[]
)
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- 2. Align courier_packages for cloud vault metadata (columns may already exist).
alter table public.courier_packages
  add column if not exists file_size_bytes bigint check (file_size_bytes is null or file_size_bytes >= 0);

create index if not exists idx_courier_packages_storage_path
  on public.courier_packages using btree (storage_path);

-- 3. Storage RLS: owner upload policy.
drop policy if exists "Vault owners upload encrypted assets" on storage.objects;
drop policy if exists "Vault owners read own encrypted assets" on storage.objects;
drop policy if exists "Vault owners update own encrypted assets" on storage.objects;
drop policy if exists "Vault owners delete own encrypted assets" on storage.objects;
drop policy if exists "Vault authorized recipient read" on storage.objects;

create policy "Vault owners upload encrypted assets"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'factlock_vault'
    and split_part(ltrim(name, '/'), '/', 1) = auth.uid()::text
  );

create policy "Vault owners read own encrypted assets"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'factlock_vault'
    and split_part(ltrim(name, '/'), '/', 1) = auth.uid()::text
  );

create policy "Vault owners update own encrypted assets"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'factlock_vault'
    and split_part(ltrim(name, '/'), '/', 1) = auth.uid()::text
  )
  with check (
    bucket_id = 'factlock_vault'
    and split_part(ltrim(name, '/'), '/', 1) = auth.uid()::text
  );

create policy "Vault owners delete own encrypted assets"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'factlock_vault'
    and split_part(ltrim(name, '/'), '/', 1) = auth.uid()::text
  );

-- 4. Recipient read: gated by courier_packages unlock + download quota.
create policy "Vault authorized recipient read"
  on storage.objects
  for select
  to anon, authenticated
  using (
    bucket_id = 'factlock_vault'
    and exists (
      select 1
      from public.courier_packages cp
      where cp.storage_bucket = storage.objects.bucket_id
        and cp.storage_path = ltrim(storage.objects.name, '/')
        and cp.is_bricked = false
        and cp.burned_at is null
        and cp.expires_at > now()
        and cp.download_count < cp.max_downloads
        and cp.unlocked_at is not null
    )
  );

notify pgrst, 'reload schema';
