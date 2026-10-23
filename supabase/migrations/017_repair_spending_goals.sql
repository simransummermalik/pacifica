-- Repair an older spending_goals table created before social goals were added.
-- CREATE TABLE IF NOT EXISTS does not change an existing table's columns.

alter table public.spending_goals
  add column if not exists title text,
  add column if not exists merchant text,
  add column if not exists weekly_limit numeric(12,2);

update public.spending_goals
set title = coalesce(nullif(title, ''), 'Spending goal'),
    merchant = coalesce(nullif(merchant, ''), 'Other'),
    weekly_limit = coalesce(weekly_limit, 25.00)
where title is null
   or title = ''
   or merchant is null
   or merchant = ''
   or weekly_limit is null;

create index if not exists spending_goals_user_idx
on public.spending_goals(user_id);
