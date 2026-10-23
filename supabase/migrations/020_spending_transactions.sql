-- Real spending records for the Activity reef.
-- public.transactions is reserved for wallet-to-wallet transfers. These records
-- are purchases such as Starbucks, groceries, movies, and shopping.

create table if not exists public.spending_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  merchant text not null check (char_length(trim(merchant)) between 1 and 100),
  amount numeric(12,2) not null check (amount > 0),
  category text not null check (category in ('food', 'fun', 'shopping', 'transport', 'subscriptions')),
  spent_at timestamptz not null default now(),
  visibility text not null default 'circle' check (visibility in ('circle', 'private')),
  source_feed_post_id uuid unique references public.feed_posts(id) on delete set null,
  external_id text unique,
  created_at timestamptz not null default now()
);

create index if not exists spending_transactions_user_category_idx
on public.spending_transactions(user_id, category, spent_at desc);

alter table public.spending_transactions enable row level security;

drop policy if exists "Circle members can view spending transactions" on public.spending_transactions;
create policy "Circle members can view spending transactions"
on public.spending_transactions for select to authenticated
using (
  visibility = 'circle'
  or user_id = (select auth.uid())
);

drop policy if exists "Users can create their spending transactions" on public.spending_transactions;
create policy "Users can create their spending transactions"
on public.spending_transactions for insert to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists "Users can update their spending transactions" on public.spending_transactions;
create policy "Users can update their spending transactions"
on public.spending_transactions for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

drop policy if exists "Users can delete their spending transactions" on public.spending_transactions;
create policy "Users can delete their spending transactions"
on public.spending_transactions for delete to authenticated
using (user_id = (select auth.uid()));

create or replace function public.category_for_merchant(p_merchant text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when lower(coalesce(p_merchant, '')) ~ '(starbucks|dunkin|chipotle|trader joe|whole foods|restaurant|coffee|grocery|food)' then 'food'
    when lower(coalesce(p_merchant, '')) ~ '(amc|ticketmaster|concert|movie|a24|game|entertainment)' then 'fun'
    when lower(coalesce(p_merchant, '')) ~ '(uber|lyft|mta|metro|transit|gas|train)' then 'transport'
    when lower(coalesce(p_merchant, '')) ~ '(netflix|spotify|hulu|icloud|subscription)' then 'subscriptions'
    else 'shopping'
  end;
$$;

-- Any shared purchase post automatically gets a real spending record.
create or replace function public.sync_spending_transaction_from_post()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.post_type = 'purchase'
     and new.merchant is not null
     and new.shared_amount is not null
     and new.shared_amount > 0 then
    insert into public.spending_transactions (
      user_id,
      merchant,
      amount,
      category,
      spent_at,
      visibility,
      source_feed_post_id
    ) values (
      new.user_id,
      new.merchant,
      new.shared_amount,
      public.category_for_merchant(new.merchant),
      new.created_at,
      new.visibility,
      new.id
    )
    on conflict (source_feed_post_id) do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists feed_posts_spending_transaction_trigger on public.feed_posts;
create trigger feed_posts_spending_transaction_trigger
after insert on public.feed_posts
for each row
execute function public.sync_spending_transaction_from_post();

-- Backfill all existing shared purchase posts.
insert into public.spending_transactions (
  user_id,
  merchant,
  amount,
  category,
  spent_at,
  visibility,
  source_feed_post_id
)
select
  p.user_id,
  p.merchant,
  p.shared_amount,
  public.category_for_merchant(p.merchant),
  p.created_at,
  p.visibility,
  p.id
from public.feed_posts p
where p.post_type = 'purchase'
  and p.merchant is not null
  and p.shared_amount > 0
on conflict (source_feed_post_id) do nothing;

-- Fresh demo spend makes the category reef immediately visible in the hackathon.
with demo_spend(email, external_id, merchant, amount, category, days_ago) as (
  values
    ('josephposas@pacifica.demo', 'demo-joseph-food-1', 'Starbucks', 8.75, 'food', 1),
    ('josephposas@pacifica.demo', 'demo-joseph-fun-1', 'AMC', 18.00, 'fun', 2),
    ('gabesprenger@pacifica.demo', 'demo-gabe-fun-1', 'Ticketmaster', 42.00, 'fun', 1),
    ('gabesprenger@pacifica.demo', 'demo-gabe-shopping-1', 'Target', 35.00, 'shopping', 3),
    ('summermalik@pacifica.demo', 'demo-summer-food-1', 'Trader Joe''s', 54.20, 'food', 1),
    ('summermalik@pacifica.demo', 'demo-summer-shopping-1', 'Whole Foods', 31.40, 'shopping', 4),
    ('kevenleon@pacifica.demo', 'demo-keven-food-1', 'Chipotle', 14.80, 'food', 2),
    ('kevenleon@pacifica.demo', 'demo-keven-transport-1', 'MTA', 12.00, 'transport', 3),
    ('raeassepha@pacifica.demo', 'demo-rae-food-1', 'Dunkin', 6.20, 'food', 1),
    ('raeassepha@pacifica.demo', 'demo-rae-shopping-1', 'Goodwill', 22.50, 'shopping', 5)
)
insert into public.spending_transactions (
  user_id,
  merchant,
  amount,
  category,
  spent_at,
  visibility,
  external_id
)
select
  u.id,
  d.merchant,
  d.amount,
  d.category,
  now() - make_interval(days => d.days_ago),
  'circle',
  d.external_id
from demo_spend d
join auth.users u on u.email = d.email
on conflict (external_id) do update
set merchant = excluded.merchant,
    amount = excluded.amount,
    category = excluded.category,
    spent_at = excluded.spent_at,
    visibility = excluded.visibility;

-- Also support the original demo pair used by the first Pacifica prototype.
with demo_profiles(username, external_id, merchant, amount, category, days_ago) as (
  values
    ('alex', 'demo-alex-food-1', 'Starbucks', 12.50, 'food', 1),
    ('alex', 'demo-alex-shopping-1', 'Target', 28.00, 'shopping', 3),
    ('johndoe', 'demo-john-food-1', 'Dunkin', 7.25, 'food', 2),
    ('johndoe', 'demo-john-fun-1', 'AMC', 16.00, 'fun', 4)
)
insert into public.spending_transactions (
  user_id,
  merchant,
  amount,
  category,
  spent_at,
  visibility,
  external_id
)
select
  p.id,
  d.merchant,
  d.amount,
  d.category,
  now() - make_interval(days => d.days_ago),
  'circle',
  d.external_id
from demo_profiles d
join public.profiles p on lower(p.username) = lower(d.username)
on conflict (external_id) do update
set merchant = excluded.merchant,
    amount = excluded.amount,
    category = excluded.category,
    spent_at = excluded.spent_at,
    visibility = excluded.visibility;
