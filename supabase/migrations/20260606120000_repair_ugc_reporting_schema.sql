-- Repair hosted drift: UGC reporting tables and RPCs missing despite
-- 20260605120000 recorded in migration history. Idempotent re-apply.

-- Content reports (append-only, anon/auth INSERT only).
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

grant insert on table public.courier_content_reports to anon, authenticated;

drop policy if exists "Anon and auth insert courier content reports"
  on public.courier_content_reports;

create policy "Anon and auth insert courier content reports"
  on public.courier_content_reports
  for insert
  to anon, authenticated
  with check (true);

-- Sender blocks (RPC-only client path).
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

-- Fingerprint helper.
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

-- Report RPC: flag package when distinct report count reaches threshold (3).
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
  v_report_count integer;
  v_flag_threshold constant integer := 3;
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

  select count(*)::integer into v_report_count
  from public.courier_content_reports
  where package_id = p_package_id;

  if v_report_count >= v_flag_threshold then
    update public.courier_packages
    set moderation_status = 'flagged',
        updated_at = now()
    where package_id = p_package_id
      and moderation_status in ('pending_scan', 'cleared');
  end if;

  return jsonb_build_object(
    'report_id', v_report_id,
    'status', 'received',
    'message', 'Report submitted. Our team will review within 24 hours.'
  );
end;
$$;

grant execute on function public.report_courier_package(uuid, text, text, text)
  to anon, authenticated;

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

notify pgrst, 'reload schema';
