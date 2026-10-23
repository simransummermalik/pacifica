-- Activity access repairs for the current app branch.
-- This migration is safe to run after migrations 001–018.

-- Older projects created spending_goals before the social-goals columns existed.
alter table public.spending_goals
  add column if not exists merchant_or_category text,
  add column if not exists goal_type text default 'merchant',
  add column if not exists target_amount numeric(12,2),
  add column if not exists start_date date,
  add column if not exists end_date date,
  add column if not exists active boolean default true,
  add column if not exists merchant text,
  add column if not exists weekly_limit numeric(12,2);

update public.spending_goals
set merchant_or_category = coalesce(nullif(merchant_or_category, ''), nullif(merchant, ''), 'Other'),
    goal_type = coalesce(nullif(goal_type, ''), 'merchant'),
    target_amount = coalesce(target_amount, weekly_limit, 25.00),
    start_date = coalesce(start_date, current_date),
    end_date = coalesce(end_date, current_date + 7),
    active = coalesce(active, true),
    merchant = coalesce(nullif(merchant, ''), nullif(merchant_or_category, ''), 'Other'),
    weekly_limit = coalesce(weekly_limit, target_amount, 25.00)
where merchant is null
   or merchant = ''
   or weekly_limit is null
   or merchant_or_category is null
   or goal_type is null
   or target_amount is null
   or start_date is null
   or end_date is null
   or active is null;

-- Goals are visible to the circle; only the owner can create/change/delete one.
alter table public.spending_goals enable row level security;

drop policy if exists "Users can view their spending goals" on public.spending_goals;
drop policy if exists "Users can view their own goals" on public.spending_goals;
drop policy if exists "Circle members can view goals" on public.spending_goals;
create policy "Circle members can view goals"
on public.spending_goals for select to authenticated
using (true);

drop policy if exists "Users can create their spending goals" on public.spending_goals;
drop policy if exists "Users can create their own goals" on public.spending_goals;
create policy "Users can create their own goals"
on public.spending_goals for insert to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists "Users can update their spending goals" on public.spending_goals;
drop policy if exists "Users can update their own goals" on public.spending_goals;
create policy "Users can update their own goals"
on public.spending_goals for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

drop policy if exists "Users can delete their spending goals" on public.spending_goals;
drop policy if exists "Users can delete their own goals" on public.spending_goals;
create policy "Users can delete their own goals"
on public.spending_goals for delete to authenticated
using (user_id = (select auth.uid()));

-- The app reads active selfies for fish avatars. Keep this scoped to the circle.
drop policy if exists "Friends can view active selfies" on public.daily_selfies;
create policy "Friends can view active selfies"
on public.daily_selfies for select to authenticated
using (
  expires_at > now()
  and (
    user_id = (select auth.uid())
    or exists (
      select 1
      from public.friendships f
      where f.status = 'accepted'
        and (
          (f.requester_id = (select auth.uid()) and f.recipient_id = daily_selfies.user_id)
          or
          (f.recipient_id = (select auth.uid()) and f.requester_id = daily_selfies.user_id)
        )
    )
  )
);
