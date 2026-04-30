-- SnapSeal foundation schema.
-- Polygon remains the durable proof layer; this Supabase ledger is an
-- active-wallet replica for assets still connected to active app wallets.

create schema if not exists private;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  wallet_id uuid not null unique default gen_random_uuid(),
  created_at timestamptz not null default now()
);

create table public.seal_ledger (
  asset_fingerprint text primary key,
  wallet_id uuid not null references public.profiles(wallet_id) on delete cascade,
  polygon_tx_hash text,
  sealed_at timestamptz not null default now()
);

create index seal_ledger_wallet_id_idx
  on public.seal_ledger (wallet_id);

alter table public.profiles enable row level security;
alter table public.seal_ledger enable row level security;

create policy "Users view own profile"
  on public.profiles
  for select
  to authenticated
  using (auth.uid() = id);

create policy "Public read of active wallet ledger"
  on public.seal_ledger
  for select
  using (true);

create policy "Users insert own active wallet ledger rows"
  on public.seal_ledger
  for insert
  to authenticated
  with check (
    wallet_id = (
      select profiles.wallet_id
      from public.profiles
      where profiles.id = auth.uid()
    )
  );

create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do update
    set email = excluded.email;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

create or replace function private.unlink_active_wallet(target_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.profiles
  where profiles.id = target_user_id;
end;
$$;
