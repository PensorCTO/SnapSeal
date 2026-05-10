-- Historic auth.users rows may lack public.profiles if signup predated the trigger
-- or the trigger failed once. simulate_chain_notarize and ledger inserts require profiles.wallet_id.

insert into public.profiles (id, email)
select u.id, coalesce(u.email::text, '')
from auth.users u
where not exists (select 1 from public.profiles p where p.id = u.id)
on conflict (id) do update set email = excluded.email;

update public.profiles
set wallet_id = gen_random_uuid()
where wallet_id is null;
