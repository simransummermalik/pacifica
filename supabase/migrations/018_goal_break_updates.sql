-- Create a social activity update when a circle member crosses a spending goal.
-- This is demo-only: it reads shared feed posts and does not move wallet money.

alter table public.feed_posts
  add column if not exists goal_id uuid references public.spending_goals(id) on delete cascade,
  add column if not exists source_post_id uuid references public.feed_posts(id) on delete cascade;

create unique index if not exists feed_posts_goal_break_source_idx
on public.feed_posts(goal_id, source_post_id)
where post_type = 'goal_break';

create or replace function public.create_goal_break_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  goal_record record;
  previous_spent numeric;
  total_spent numeric;
begin
  if new.post_type <> 'purchase'
     or new.user_id is null
     or new.merchant is null
     or new.shared_amount is null
     or new.shared_amount <= 0 then
    return new;
  end if;

  for goal_record in
    select id, user_id, title, merchant, weekly_limit
    from public.spending_goals
    where user_id = new.user_id
      and new.merchant ilike '%' || merchant || '%'
  loop
    select coalesce(sum(p.shared_amount), 0)
    into previous_spent
    from public.feed_posts p
    where p.user_id = new.user_id
      and p.post_type = 'purchase'
      and p.id <> new.id
      and p.shared_amount > 0
      and p.merchant is not null
      and p.merchant ilike '%' || goal_record.merchant || '%'
      and p.created_at >= new.created_at - interval '7 days'
      and p.created_at <= new.created_at;

    total_spent := previous_spent + new.shared_amount;

    if previous_spent <= goal_record.weekly_limit
       and total_spent > goal_record.weekly_limit then
      insert into public.feed_posts (
        user_id,
        post_type,
        caption,
        merchant,
        shared_amount,
        visibility,
        goal_id,
        source_post_id
      ) values (
        new.user_id,
        'goal_break',
        format(
          'Broke "%s" — %s spent on %s this week (limit %s).',
          goal_record.title,
          to_char(total_spent, 'FM$999,999,990.00'),
          new.merchant,
          to_char(goal_record.weekly_limit, 'FM$999,999,990.00')
        ),
        new.merchant,
        total_spent,
        'circle',
        goal_record.id,
        new.id
      )
      on conflict do nothing;
    end if;
  end loop;

  return new;
end;
$$;

drop trigger if exists feed_posts_goal_break_trigger on public.feed_posts;
create trigger feed_posts_goal_break_trigger
after insert on public.feed_posts
for each row
execute function public.create_goal_break_update();

-- Backfill alerts for purchases that happened before a goal was created.
create or replace function public.sync_goal_break_updates()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  goal_record record;
  candidate record;
begin
  for goal_record in
    select id, user_id, title, merchant, weekly_limit
    from public.spending_goals
  loop
    select purchase.id, purchase.total_spent
    into candidate
    from (
      select
        p.id,
        p.created_at,
        sum(p.shared_amount) over (
          order by p.created_at, p.id
          rows between unbounded preceding and current row
        ) as total_spent,
        coalesce(
          sum(p.shared_amount) over (
            order by p.created_at, p.id
            rows between unbounded preceding and 1 preceding
          ),
          0
        ) as previous_spent
      from public.feed_posts p
      where p.user_id = goal_record.user_id
        and p.post_type = 'purchase'
        and p.shared_amount > 0
        and p.merchant is not null
        and p.merchant ilike '%' || goal_record.merchant || '%'
        and p.created_at >= now() - interval '7 days'
    ) as purchase
    where purchase.total_spent > goal_record.weekly_limit
      and purchase.previous_spent <= goal_record.weekly_limit
    order by purchase.created_at, purchase.id
    limit 1;

    if found then
      insert into public.feed_posts (
        user_id,
        post_type,
        caption,
        merchant,
        shared_amount,
        visibility,
        goal_id,
        source_post_id
      ) values (
        goal_record.user_id,
        'goal_break',
        format(
          'Broke "%s" — %s spent on %s this week (limit %s).',
          goal_record.title,
          to_char(candidate.total_spent, 'FM$999,999,990.00'),
          goal_record.merchant,
          to_char(goal_record.weekly_limit, 'FM$999,999,990.00')
        ),
        goal_record.merchant,
        candidate.total_spent,
        'circle',
        goal_record.id,
        candidate.id
      )
      on conflict do nothing;
    end if;
  end loop;
end;
$$;

revoke all on function public.create_goal_break_update() from public;
revoke all on function public.sync_goal_break_updates() from public;
grant execute on function public.sync_goal_break_updates() to authenticated;
