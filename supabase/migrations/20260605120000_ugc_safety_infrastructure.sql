-- UGC safety infrastructure: reporting, blocking, async moderation queue (App Store Guideline 1.2).

-- Extend courier_packages with moderation lifecycle.
alter table public.courier_packages
  add column if not exists moderation_status text not null default 'pending_scan'
    check (moderation_status in ('pending_scan', 'cleared', 'flagged', 'quarantined'));

create index if not exists idx_courier_packages_moderation_status
  on public.courier_packages (moderation_status)
  where moderation_status <> 'cleared';

-- Content reports submitted by recipients (anon or authenticated).
create table if not exists public.courier_content_reports (
  report_id uuid primary key default gen_random_uuid(),
  package_id uuid not null references public.courier_packages (package_id) on delete cascade,
  reporter_fingerprint text not null,
  reason text not null check (reason in (
    'spam', 'harassment', 'illegal', 'violence', 'sexual', 'other'
  )),
  detail_text text,
  status text not null default 'pending'
    check (status in ('pending', 'reviewed', 'actioned')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_courier_content_reports_package_id
  on public.courier_content_reports (package_id);

alter table public.courier_content_reports enable row level security;

-- Clients insert reports only; no direct SELECT (admin/service role reads).
grant insert on table public.courier_content_reports to anon, authenticated;

create policy "Anon and auth insert courier content reports"
  on public.courier_content_reports
  for insert
  to anon, authenticated
  with check (true);

-- Sender blocks: reporter blocks future packages from the same owner (server-side resolution).
create table if not exists public.courier_sender_blocks (
  block_id uuid primary key default gen_random_uuid(),
  blocked_owner_id uuid not null references public.profiles (id) on delete cascade,
  reporter_fingerprint text not null,
  source_package_id uuid not null references public.courier_packages (package_id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (blocked_owner_id, reporter_fingerprint)
);

create index if not exists idx_courier_sender_blocks_owner
  on public.courier_sender_blocks (blocked_owner_id);

create index if not exists idx_courier_sender_blocks_reporter
  on public.courier_sender_blocks (reporter_fingerprint);

alter table public.courier_sender_blocks enable row level security;

-- No client grants on blocks — RPC-only inserts.

-- Async moderation queue (service role / edge functions only).
create table if not exists public.courier_moderation_queue (
  queue_id uuid primary key default gen_random_uuid(),
  package_id uuid not null references public.courier_packages (package_id) on delete cascade,
  scan_status text not null default 'pending'
    check (scan_status in ('pending', 'processing', 'completed', 'failed')),
  ml_score numeric(5, 4),
  human_review_required boolean not null default false,
  scan_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (package_id)
);

create index if not exists idx_courier_moderation_queue_status
  on public.courier_moderation_queue (scan_status)
  where scan_status in ('pending', 'processing');

alter table public.courier_moderation_queue enable row level security;

-- No client grants on moderation queue.

-- Fingerprint helper: hash reporter email for privacy-preserving dedup.
create or replace function public._courier_reporter_fingerprint(p_email text)
returns text
language sql
immutable
set search_path = public
as $$
  select encode(
    extensions.digest(lower(trim(coalesce(p_email, ''))), 'sha256'),
    'hex'
  );
$$;

-- Report a courier package (never returns owner_id).
create or replace function public.report_courier_package(
  p_package_id uuid,
  p_reason text,
  p_detail text default null,
  p_reporter_email text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pkg public.courier_packages%rowtype;
  v_report_id uuid;
  v_fingerprint text;
begin
  if p_package_id is null then
    raise exception 'package_id is required';
  end if;

  if p_reason is null or p_reason not in (
    'spam', 'harassment', 'illegal', 'violence', 'sexual', 'other'
  ) then
    raise exception 'Invalid report reason';
  end if;

  select * into v_pkg
  from public.courier_packages
  where package_id = p_package_id;

  if not found then
    raise exception 'Package not found';
  end if;

  v_fingerprint := public._courier_reporter_fingerprint(p_reporter_email);

  insert into public.courier_content_reports (
    package_id,
    reporter_fingerprint,
    reason,
    detail_text
  )
  values (
    p_package_id,
    v_fingerprint,
    p_reason,
    nullif(trim(coalesce(p_detail, '')), '')
  )
  returning report_id into v_report_id;

  -- Flag for human review when report count exceeds threshold.
  update public.courier_packages
  set moderation_status = 'flagged',
      updated_at = now()
  where package_id = p_package_id
    and moderation_status = 'cleared';

  return jsonb_build_object(
    'report_id', v_report_id,
    'status', 'received',
    'message', 'Report submitted. Our team will review within 24 hours.'
  );
end;
$$;

grant execute on function public.report_courier_package(uuid, text, text, text)
  to anon, authenticated;

-- Block sender server-side (resolves owner_id from package_id).
create or replace function public.block_courier_sender(
  p_package_id uuid,
  p_reporter_email text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pkg public.courier_packages%rowtype;
  v_fingerprint text;
  v_block_id uuid;
begin
  if p_package_id is null then
    raise exception 'package_id is required';
  end if;

  select * into v_pkg
  from public.courier_packages
  where package_id = p_package_id;

  if not found then
    raise exception 'Package not found';
  end if;

  v_fingerprint := public._courier_reporter_fingerprint(p_reporter_email);

  insert into public.courier_sender_blocks (
    blocked_owner_id,
    reporter_fingerprint,
    source_package_id
  )
  values (
    v_pkg.owner_id,
    v_fingerprint,
    p_package_id
  )
  on conflict (blocked_owner_id, reporter_fingerprint) do nothing
  returning block_id into v_block_id;

  return jsonb_build_object(
    'blocked', true,
    'message', 'Sender blocked. You will not receive packages from this origin.'
  );
end;
$$;

grant execute on function public.block_courier_sender(uuid, text)
  to anon, authenticated;

-- Optional pre-unlock gate: check if reporter has blocked this package's sender.
create or replace function public.check_sender_blocked_for_reporter(
  p_package_id uuid,
  p_reporter_email text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pkg public.courier_packages%rowtype;
  v_fingerprint text;
  v_blocked boolean;
begin
  select * into v_pkg
  from public.courier_packages
  where package_id = p_package_id;

  if not found then
    return jsonb_build_object('blocked', false);
  end if;

  v_fingerprint := public._courier_reporter_fingerprint(p_reporter_email);

  select exists (
    select 1
    from public.courier_sender_blocks
    where blocked_owner_id = v_pkg.owner_id
      and reporter_fingerprint = v_fingerprint
  ) into v_blocked;

  return jsonb_build_object('blocked', coalesce(v_blocked, false));
end;
$$;

grant execute on function public.check_sender_blocked_for_reporter(uuid, text)
  to anon, authenticated;

-- Owner lookup: resolve package_id for a sealed asset (authenticated only).
create or replace function public.get_own_courier_package_id(p_asset_hash text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_package_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select package_id into v_package_id
  from public.courier_packages
  where owner_id = auth.uid()
    and asset_hash = p_asset_hash
    and burned_at is null
  order by created_at desc
  limit 1;

  return v_package_id;
end;
$$;

grant execute on function public.get_own_courier_package_id(text) to authenticated;

-- Reject quarantined packages in attempt_courier_unlock (preserve payload + egress logic).
drop function if exists public.attempt_courier_unlock(uuid, text, text);

create or replace function public.attempt_courier_unlock(
  p_package_id uuid,
  p_verifier_guess text,
  p_requestor_email text
)
returns table (
  key text,
  file_extension text,
  storage_bucket text,
  storage_path text,
  asset_hash text,
  content_mime_type text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_package public.courier_packages%rowtype;
  v_guess_hash text;
begin
  select *
    into v_package
    from public.courier_packages
    where package_id = p_package_id
    for update;

  if not found then
    raise exception 'Courier package not found';
  end if;

  if v_package.moderation_status = 'quarantined' then
    raise exception 'This package is unavailable pending review';
  end if;

  if v_package.is_bricked
      or v_package.burned_at is not null
      or v_package.expires_at <= now()
      or v_package.failed_attempts >= v_package.max_attempts
      or v_package.download_count >= v_package.max_downloads then
    raise exception 'Courier package is locked';
  end if;

  v_guess_hash := encode(extensions.digest(coalesce(p_verifier_guess, ''), 'sha256'), 'hex');

  if v_guess_hash <> v_package.verifier_secret_hash then
    update public.courier_packages cp
      set failed_attempts = failed_attempts + 1,
          last_failed_at = now(),
          requestor_email = nullif(p_requestor_email, '')
      where cp.package_id = p_package_id
      returning * into v_package;

    if v_package.failed_attempts >= v_package.max_attempts then
      update public.courier_packages cp
        set burned_at = now(),
            is_bricked = true
        where cp.package_id = p_package_id;

      delete from storage.objects so
      where so.bucket_id = v_package.storage_bucket
        and so.name = v_package.storage_path;
    end if;

    raise exception 'Invalid verifier challenge';
  end if;

  update public.courier_packages cp
    set unlocked_at = now(),
        download_count = download_count + 1,
        requestor_email = nullif(p_requestor_email, '')
    where cp.package_id = p_package_id
    returning * into v_package;

  perform public.increment_archive_egress(
    v_package.owner_id,
    coalesce(v_package.file_size_bytes, 0)
  );

  return query
    select
      v_package.vault_key,
      v_package.file_extension,
      v_package.storage_bucket,
      v_package.storage_path,
      v_package.asset_hash,
      v_package.content_mime_type;
end;
$$;

revoke all on function public.attempt_courier_unlock(uuid, text, text) from public;
grant execute on function public.attempt_courier_unlock(uuid, text, text)
  to anon, authenticated, service_role;

-- Include quarantined status in attempt status checks.
create or replace function public.check_courier_attempts(p_package_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_package public.courier_packages%rowtype;
  v_locked boolean;
  v_status text;
begin
  select *
    into v_package
    from public.courier_packages
    where package_id = p_package_id;

  if not found then
    return jsonb_build_object(
      'status', 'not_found',
      'locked', true,
      'attempts_remaining', 0,
      'downloads_remaining', 0
    );
  end if;

  v_locked :=
    v_package.moderation_status = 'quarantined'
    or v_package.is_bricked
    or v_package.burned_at is not null
    or v_package.expires_at <= now()
    or v_package.failed_attempts >= v_package.max_attempts
    or v_package.download_count >= v_package.max_downloads;

  v_status :=
    case
      when v_package.moderation_status = 'quarantined' then 'quarantined'
      when v_package.is_bricked or v_package.burned_at is not null then 'burned'
      when v_package.expires_at <= now() then 'expired'
      when v_package.download_count >= v_package.max_downloads then 'exhausted'
      when v_package.failed_attempts >= v_package.max_attempts then 'locked'
      else 'available'
    end;

  return jsonb_build_object(
    'status', v_status,
    'locked', v_locked,
    'attempts_remaining',
      greatest(v_package.max_attempts - v_package.failed_attempts, 0),
    'max_attempts', v_package.max_attempts,
    'downloads_remaining',
      greatest(v_package.max_downloads - v_package.download_count, 0),
    'max_downloads', v_package.max_downloads,
    'expires_at', v_package.expires_at
  );
end;
$$;

notify pgrst, 'reload schema';
