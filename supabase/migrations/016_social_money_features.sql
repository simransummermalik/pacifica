-- Demo-only social money features for the Pacifica hackathon.
-- These tables record goals, challenge stakes, and bill-pool pledges.
-- They do not move real money.

create table if not exists public.spending_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 80),
  merchant text not null check (char_length(trim(merchant)) between 1 and 80),
  weekly_limit numeric(12,2) not null check (weekly_limit > 0),
  created_at timestamptz not null default now()
);

create table if not exists public.money_pools (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 80),
  purpose text not null check (char_length(trim(purpose)) between 1 and 160),
  target_amount numeric(12,2) not null check (target_amount > 0),
  status text not null default 'open' check (status in ('open', 'closed')),
  created_at timestamptz not null default now()
);

create table if not exists public.money_pool_members (
  pool_id uuid not null references public.money_pools(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  pledged_amount numeric(12,2) not null default 0 check (pledged_amount >= 0),
  created_at timestamptz not null default now(),
  primary key (pool_id, user_id)
);

create table if not exists public.spending_challenges (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 120),
  merchant text not null check (char_length(trim(merchant)) between 1 and 80),
  stake_amount numeric(12,2) not null default 2.00 check (stake_amount = 2.00),
  week_start date not null default date_trunc('week', current_date)::date,
  status text not null default 'open' check (status in ('open', 'resolved', 'cancelled')),
  winner_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.challenge_entries (
  challenge_id uuid not null references public.spending_challenges(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  prediction text not null check (char_length(trim(prediction)) between 1 and 140),
  stake_amount numeric(12,2) not null default 2.00 check (stake_amount = 2.00),
  created_at timestamptz not null default now(),
  primary key (challenge_id, user_id)
);

create index if not exists spending_goals_user_idx on public.spending_goals(user_id);
create index if not exists money_pools_status_idx on public.money_pools(status, created_at);
create index if not exists challenge_entries_challenge_idx on public.challenge_entries(challenge_id);

alter table public.spending_goals enable row level security;
alter table public.money_pools enable row level security;
alter table public.money_pool_members enable row level security;
alter table public.spending_challenges enable row level security;
alter table public.challenge_entries enable row level security;

drop policy if exists "Users can view their own goals" on public.spending_goals;
create policy "Users can view their own goals"
on public.spending_goals for select to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "Users can create their own goals" on public.spending_goals;
create policy "Users can create their own goals"
on public.spending_goals for insert to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists "Users can update their own goals" on public.spending_goals;
create policy "Users can update their own goals"
on public.spending_goals for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

drop policy if exists "Users can delete their own goals" on public.spending_goals;
create policy "Users can delete their own goals"
on public.spending_goals for delete to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "Circle members can view pools" on public.money_pools;
create policy "Circle members can view pools"
on public.money_pools for select to authenticated using (true);

drop policy if exists "Users can create pools" on public.money_pools;
create policy "Users can create pools"
on public.money_pools for insert to authenticated
with check (creator_id = (select auth.uid()));

drop policy if exists "Creators can update pools" on public.money_pools;
create policy "Creators can update pools"
on public.money_pools for update to authenticated
using (creator_id = (select auth.uid()))
with check (creator_id = (select auth.uid()));

drop policy if exists "Circle members can view pool pledges" on public.money_pool_members;
create policy "Circle members can view pool pledges"
on public.money_pool_members for select to authenticated using (true);

drop policy if exists "Users can pledge to pools" on public.money_pool_members;
create policy "Users can pledge to pools"
on public.money_pool_members for insert to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists "Users can update their pool pledges" on public.money_pool_members;
create policy "Users can update their pool pledges"
on public.money_pool_members for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

drop policy if exists "Circle members can view challenges" on public.spending_challenges;
create policy "Circle members can view challenges"
on public.spending_challenges for select to authenticated using (true);

drop policy if exists "Users can create challenges" on public.spending_challenges;
create policy "Users can create challenges"
on public.spending_challenges for insert to authenticated
with check (creator_id = (select auth.uid()));

drop policy if exists "Circle members can view challenge entries" on public.challenge_entries;
create policy "Circle members can view challenge entries"
on public.challenge_entries for select to authenticated using (true);

drop policy if exists "Users can join challenges" on public.challenge_entries;
create policy "Users can join challenges"
on public.challenge_entries for insert to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists "Users can update their challenge entries" on public.challenge_entries;
create policy "Users can update their challenge entries"
on public.challenge_entries for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

-- Seed one challenge and one pool for the five demo accounts.
insert into public.spending_challenges (creator_id, title, merchant, stake_amount)
select u.id, 'Who is buying coffee this week?', 'Starbucks', 2.00
from auth.users u
where u.email = 'gabesprenger@pacifica.demo'
and not exists (
  select 1 from public.spending_challenges
  where title = 'Who is buying coffee this week?'
);

insert into public.money_pools (creator_id, title, purpose, target_amount)
select u.id, 'Friday dinner pool', 'Chip in for the group dinner.', 60.00
from auth.users u
where u.email = 'summermalik@pacifica.demo'
and not exists (
  select 1 from public.money_pools
  where title = 'Friday dinner pool'
);
