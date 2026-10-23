-- Pacifica database schema
-- Apply this migration to a fresh Supabase project.
-- The current project was created manually in the Supabase SQL Editor;
-- this file keeps the same schema in the repository for reproducibility.

create extension if not exists pgcrypto;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  display_name text not null,
  avatar_path text,
  fish_color text not null default '#4B9FB8',
  fish_type text not null default 'clownfish',
  created_at timestamptz not null default now()
);

create table public.wallets (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  demo_balance numeric(12,2) not null default 0 check (demo_balance >= 0),
  updated_at timestamptz not null default now()
);

create table public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  check (requester_id <> recipient_id)
);

create unique index friendships_one_pair
on public.friendships (
  least(requester_id, recipient_id),
  greatest(requester_id, recipient_id)
);

create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id),
  recipient_id uuid not null references public.profiles(id),
  amount numeric(12,2) not null check (amount > 0),
  note text,
  status text not null default 'completed'
    check (status in ('pending', 'completed', 'declined', 'failed')),
  transaction_type text not null default 'payment',
  idempotency_key uuid not null default gen_random_uuid() unique,
  created_at timestamptz not null default now(),
  check (sender_id <> recipient_id)
);

create table public.spending_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  merchant_or_category text,
  goal_type text not null default 'merchant'
    check (goal_type in ('merchant', 'category', 'general')),
  target_amount numeric(12,2)
    check (target_amount is null or target_amount >= 0),
  start_date date not null,
  end_date date not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  check (end_date >= start_date)
);

create table public.feed_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  transaction_id uuid references public.transactions(id) on delete set null,
  spending_goal_id uuid references public.spending_goals(id) on delete set null,
  post_type text not null default 'transaction',
  caption text,
  merchant text,
  shared_amount numeric(12,2),
  hide_amount boolean not null default false,
  hide_merchant boolean not null default false,
  visibility text not null default 'circle'
    check (visibility in ('circle', 'private')),
  created_at timestamptz not null default now()
);

create table public.reactions (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.feed_posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  reaction_type text not null
    check (reaction_type in ('upvote', 'downvote')),
  created_at timestamptz not null default now(),
  unique (post_id, user_id)
);

create table public.debts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  debt_type text not null,
  starting_balance numeric(12,2) not null check (starting_balance > 0),
  remaining_balance numeric(12,2) not null check (remaining_balance >= 0),
  annual_interest_rate numeric(5,2) not null default 0,
  created_at timestamptz not null default now(),
  check (remaining_balance <= starting_balance)
);

create table public.debt_payments (
  id uuid primary key default gen_random_uuid(),
  debt_id uuid not null references public.debts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  amount numeric(12,2) not null check (amount > 0),
  idempotency_key uuid not null default gen_random_uuid() unique,
  created_at timestamptz not null default now()
);

create table public.daily_selfies (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  storage_path text not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  check (expires_at > created_at)
);

create index daily_selfies_user_expiry_idx
on public.daily_selfies(user_id, expires_at);

create table public.payment_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  amount numeric(12,2) not null check (amount > 0),
  note text,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined', 'cancelled')),
  idempotency_key uuid not null default gen_random_uuid() unique,
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  check (requester_id <> recipient_id)
);

create table public.financial_data_cache (
  id uuid primary key default gen_random_uuid(),
  source text not null,
  series_id text not null,
  observed_period text not null,
  value numeric not null,
  fetched_at timestamptz not null default now(),
  unique (source, series_id, observed_period)
);

-- Create a profile and empty wallet whenever a new Auth user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  generated_username text;
  generated_display_name text;
begin
  generated_username := coalesce(
    nullif(new.raw_user_meta_data->>'username', ''),
    'user_' || substr(new.id::text, 1, 8)
  );

  generated_display_name := coalesce(
    nullif(new.raw_user_meta_data->>'display_name', ''),
    split_part(coalesce(new.email, 'user'), '@', 1)
  );

  insert into public.profiles (id, username, display_name)
  values (new.id, generated_username, generated_display_name);

  insert into public.wallets (user_id, demo_balance)
  values (new.id, 0);

  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Row Level Security
alter table public.profiles enable row level security;
alter table public.wallets enable row level security;
alter table public.friendships enable row level security;
alter table public.transactions enable row level security;
alter table public.spending_goals enable row level security;
alter table public.feed_posts enable row level security;
alter table public.reactions enable row level security;
alter table public.debts enable row level security;
alter table public.debt_payments enable row level security;
alter table public.daily_selfies enable row level security;
alter table public.payment_requests enable row level security;
alter table public.financial_data_cache enable row level security;

create policy "Profiles are searchable by signed in users"
on public.profiles for select to authenticated using (true);

create policy "Users can create their own profile"
on public.profiles for insert to authenticated
with check ((select auth.uid()) = id);

create policy "Users can update their own profile"
on public.profiles for update to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

create policy "Users can view their own wallet"
on public.wallets for select to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can view their friendships"
on public.friendships for select to authenticated
using ((select auth.uid()) in (requester_id, recipient_id));

create policy "Users can send friend requests"
on public.friendships for insert to authenticated
with check ((select auth.uid()) = requester_id);

create policy "Recipients can respond to friend requests"
on public.friendships for update to authenticated
using ((select auth.uid()) = recipient_id)
with check ((select auth.uid()) = recipient_id);

create policy "Users can remove their friendships"
on public.friendships for delete to authenticated
using ((select auth.uid()) in (requester_id, recipient_id));

create policy "Users can view their transactions"
on public.transactions for select to authenticated
using ((select auth.uid()) in (sender_id, recipient_id));

create policy "Users can view their spending goals"
on public.spending_goals for select to authenticated
using (user_id = (select auth.uid()));

create policy "Users can create their spending goals"
on public.spending_goals for insert to authenticated
with check (user_id = (select auth.uid()));

create policy "Users can update their spending goals"
on public.spending_goals for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy "Users can delete their spending goals"
on public.spending_goals for delete to authenticated
using (user_id = (select auth.uid()));

create policy "Users can view allowed feed posts"
on public.feed_posts for select to authenticated
using (
  user_id = (select auth.uid())
  or (
    visibility = 'circle'
    and exists (
      select 1
      from public.friendships f
      where f.status = 'accepted'
        and (
          (f.requester_id = (select auth.uid()) and f.recipient_id = feed_posts.user_id)
          or
          (f.recipient_id = (select auth.uid()) and f.requester_id = feed_posts.user_id)
        )
    )
  )
);

create policy "Users can create their own feed posts"
on public.feed_posts for insert to authenticated
with check (user_id = (select auth.uid()));

create policy "Users can update their own feed posts"
on public.feed_posts for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy "Users can delete their own feed posts"
on public.feed_posts for delete to authenticated
using (user_id = (select auth.uid()));

create policy "Users can view reactions on visible posts"
on public.reactions for select to authenticated
using (
  exists (
    select 1 from public.feed_posts fp
    where fp.id = reactions.post_id
  )
);

create policy "Users can create their own reactions"
on public.reactions for insert to authenticated
with check (user_id = (select auth.uid()));

create policy "Users can update their own reactions"
on public.reactions for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy "Users can delete their own reactions"
on public.reactions for delete to authenticated
using (user_id = (select auth.uid()));

create policy "Users can view their debts"
on public.debts for select to authenticated
using (user_id = (select auth.uid()));

create policy "Users can create their debts"
on public.debts for insert to authenticated
with check (user_id = (select auth.uid()));

create policy "Users can delete their debts"
on public.debts for delete to authenticated
using (user_id = (select auth.uid()));

create policy "Users can view their debt payments"
on public.debt_payments for select to authenticated
using (user_id = (select auth.uid()));

create policy "Users can view their own selfies"
on public.daily_selfies for select to authenticated
using (user_id = (select auth.uid()));

create policy "Friends can view active selfies"
on public.daily_selfies for select to authenticated
using (
  expires_at > now()
  and exists (
    select 1
    from public.friendships f
    where f.status = 'accepted'
      and (
        (f.requester_id = (select auth.uid()) and f.recipient_id = daily_selfies.user_id)
        or
        (f.recipient_id = (select auth.uid()) and f.requester_id = daily_selfies.user_id)
      )
  )
);

create policy "Users can add their own selfies"
on public.daily_selfies for insert to authenticated
with check (user_id = (select auth.uid()));

create policy "Users can delete their own selfies"
on public.daily_selfies for delete to authenticated
using (user_id = (select auth.uid()));

create policy "Users can view their payment requests"
on public.payment_requests for select to authenticated
using ((select auth.uid()) in (requester_id, recipient_id));

create policy "Users can create payment requests"
on public.payment_requests for insert to authenticated
with check (requester_id = (select auth.uid()));

create policy "Users can update their payment requests"
on public.payment_requests for update to authenticated
using ((select auth.uid()) in (requester_id, recipient_id))
with check ((select auth.uid()) in (requester_id, recipient_id));

create policy "Users can delete their payment requests"
on public.payment_requests for delete to authenticated
using ((select auth.uid()) in (requester_id, recipient_id));

create policy "Signed in users can view financial data"
on public.financial_data_cache for select to authenticated using (true);

create policy "Signed in users can save financial data"
on public.financial_data_cache for insert to authenticated with check (true);

create policy "Signed in users can update financial data"
on public.financial_data_cache for update to authenticated
using (true) with check (true);

-- Atomic simulated money transfer.
create or replace function public.send_money(
  p_recipient_id uuid,
  p_amount numeric,
  p_note text default null,
  p_idempotency_key uuid default gen_random_uuid()
)
returns public.transactions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_sender_id uuid := auth.uid();
  v_sender_balance numeric(12,2);
  v_transaction public.transactions;
begin
  if v_sender_id is null then raise exception 'You must be signed in'; end if;
  if p_amount is null or p_amount <= 0 or p_amount <> round(p_amount, 2) then
    raise exception 'Enter a valid amount';
  end if;
  if p_recipient_id = v_sender_id then
    raise exception 'You cannot send money to yourself';
  end if;
  if not exists (select 1 from public.profiles where id = p_recipient_id) then
    raise exception 'Recipient not found';
  end if;
  if not exists (select 1 from public.wallets where user_id = v_sender_id)
     or not exists (select 1 from public.wallets where user_id = p_recipient_id) then
    raise exception 'Wallet not found';
  end if;

  select * into v_transaction
  from public.transactions
  where idempotency_key = p_idempotency_key and sender_id = v_sender_id;
  if found then return v_transaction; end if;

  perform 1 from public.wallets
  where user_id in (v_sender_id, p_recipient_id)
  order by user_id
  for update;

  select demo_balance into v_sender_balance
  from public.wallets where user_id = v_sender_id;
  if v_sender_balance < p_amount then raise exception 'Insufficient funds'; end if;

  update public.wallets
  set demo_balance = demo_balance - p_amount, updated_at = now()
  where user_id = v_sender_id;
  update public.wallets
  set demo_balance = demo_balance + p_amount, updated_at = now()
  where user_id = p_recipient_id;

  insert into public.transactions (
    sender_id, recipient_id, amount, note, status, transaction_type, idempotency_key
  ) values (
    v_sender_id, p_recipient_id, p_amount, p_note, 'completed', 'payment', p_idempotency_key
  ) returning * into v_transaction;
  return v_transaction;
end;
$$;

revoke all on function public.send_money(uuid, numeric, text, uuid) from public;
grant execute on function public.send_money(uuid, numeric, text, uuid) to authenticated;

-- Atomic simulated debt payment.
create or replace function public.record_debt_payment(
  p_debt_id uuid,
  p_amount numeric,
  p_idempotency_key uuid default gen_random_uuid()
)
returns public.debt_payments
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_remaining_balance numeric(12,2);
  v_payment public.debt_payments;
begin
  if v_user_id is null then raise exception 'You must be signed in'; end if;
  if p_amount is null or p_amount <= 0 or p_amount <> round(p_amount, 2) then
    raise exception 'Enter a valid payment amount';
  end if;

  select * into v_payment
  from public.debt_payments
  where idempotency_key = p_idempotency_key and user_id = v_user_id;
  if found then return v_payment; end if;

  select remaining_balance into v_remaining_balance
  from public.debts
  where id = p_debt_id and user_id = v_user_id
  for update;
  if not found then raise exception 'Debt not found'; end if;
  if p_amount > v_remaining_balance then
    raise exception 'Payment is larger than the remaining debt';
  end if;

  update public.debts
  set remaining_balance = remaining_balance - p_amount
  where id = p_debt_id;

  insert into public.debt_payments (debt_id, user_id, amount, idempotency_key)
  values (p_debt_id, v_user_id, p_amount, p_idempotency_key)
  returning * into v_payment;
  return v_payment;
end;
$$;

revoke all on function public.record_debt_payment(uuid, numeric, uuid) from public;
grant execute on function public.record_debt_payment(uuid, numeric, uuid) to authenticated;

-- The daily-selfies bucket is private and should be created in Supabase Storage.
-- Store files as: <user UUID>/<unique filename>.
create policy "Users can upload their own selfie files"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'daily-selfies'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy "Users can view their own selfie files"
on storage.objects for select to authenticated
using (
  bucket_id = 'daily-selfies'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy "Friends can view active selfie files"
on storage.objects for select to authenticated
using (
  bucket_id = 'daily-selfies'
  and exists (
    select 1
    from public.daily_selfies ds
    join public.friendships f on f.status = 'accepted'
    where ds.storage_path = storage.objects.name
      and ds.expires_at > now()
      and (
        (f.requester_id = (select auth.uid()) and f.recipient_id = ds.user_id)
        or
        (f.recipient_id = (select auth.uid()) and f.requester_id = ds.user_id)
      )
  )
);

create policy "Users can delete their own selfie files"
on storage.objects for delete to authenticated
using (
  bucket_id = 'daily-selfies'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
