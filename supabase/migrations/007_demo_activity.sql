-- Sample social activity for the demo circle.
-- These are feed posts, not wallet transfers, so they do not change balances.

with sample_posts(email, post_type, caption, merchant, shared_amount) as (
  values
    ('gabesprenger@pacifica.demo', 'purchase', 'Movie night', 'AMC', 18.00),
    ('summermalik@pacifica.demo', 'purchase', 'Trader Joe''s — groceries', 'Trader Joe''s', 54.20),
    ('kevenleon@pacifica.demo', 'debt_payment', 'Paid $75 toward student debt', null, 75.00),
    ('raeassepha@pacifica.demo', 'purchase', 'Dunkin — iced coffee', 'Dunkin', 6.20),
    ('josephposas@pacifca.demo', 'purchase', 'Starbucks — coffee run', 'Starbucks', 8.75)
)
insert into public.feed_posts (
  user_id,
  post_type,
  caption,
  merchant,
  shared_amount,
  visibility
)
select
  users.id,
  sample_posts.post_type,
  sample_posts.caption,
  sample_posts.merchant,
  sample_posts.shared_amount,
  'circle'
from sample_posts
join auth.users users on users.email = sample_posts.email
where not exists (
  select 1
  from public.feed_posts existing
  where existing.user_id = users.id
    and existing.caption = sample_posts.caption
);
