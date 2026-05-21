-- Identity lifecycle: wallet lineage ledger, proof_ledger EVM origin tracking,
-- and cascade-safe account burn (App Store Guideline 5.1.1).

begin;

-- Historical EVM signing keys retained when profiles.evm_address rotates.
create table if not exists public.wallet_history (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  wallet_address text not null check (wallet_address ~ '^0x[a-fA-F0-9]{40}$'),
  archived_at timestamptz not null default timezone('utc'::text, now())
);

alter table public.wallet_history enable row level security;

drop policy if exists "Users can look up their own history keys"
  on public.wallet_history;

create policy "Users can look up their own history keys"
  on public.wallet_history
  for select
  to authenticated
  using (auth.uid() = owner_id);

create index if not exists idx_wallet_history_owner
  on public.wallet_history (owner_id);

-- Signing-origin key captured at seal time (distinct from profiles.wallet_id).
alter table public.proof_ledger
  add column if not exists evm_address text;

create index if not exists idx_proof_ledger_evm_address
  on public.proof_ledger (evm_address)
  where evm_address is not null;

create or replace function public.archive_rotated_evm_address()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE'
     and old.evm_address is not null
     and new.evm_address is not null
     and lower(old.evm_address) <> lower(new.evm_address) then
    insert into public.wallet_history (owner_id, wallet_address)
    values (old.id, lower(old.evm_address));
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_archive_rotated_evm_address on public.profiles;

create trigger profiles_archive_rotated_evm_address
  before update of evm_address on public.profiles
  for each row
  execute function public.archive_rotated_evm_address();

-- App Store account deletion: purge courier blobs then auth identity (cascade).
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
    raise exception 'Authentication context missing';
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

commit;

notify pgrst, 'reload schema';
