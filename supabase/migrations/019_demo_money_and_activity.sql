-- Rich demo money and activity for the five Pacifica accounts.
-- These are simulated balances and shared feed posts, not real bank funds.

with demo_balances(email, balance) as (
  values
    ('josephposas@pacifica.demo', 1240.50),
    ('gabesprenger@pacifica.demo', 835.25),
    ('summermalik@pacifica.demo', 650.00),
    ('kevenleon@pacifica.demo', 420.75),
    ('raeassepha@pacifica.demo', 1075.10)
)
insert into public.wallets (user_id, demo_balance)
select users.id, demo_balances.balance
from demo_balances
join auth.users users on users.email = demo_balances.email
on conflict (user_id) do update
set demo_balance = excluded.demo_balance,
    updated_at = now();

with demo_posts(email, post_type, caption, merchant, shared_amount) as (
  values
    ('josephposas@pacifica.demo', 'purchase', 'Coffee and pastry before class', 'Starbucks', 12.40),
    ('josephposas@pacifica.demo', 'purchase', 'Ramen night with the circle', 'Wagamama', 24.00),
    ('josephposas@pacifica.demo', 'purchase', 'Monthly transit pass', 'MTA', 72.00),
    ('josephposas@pacifica.demo', 'debt_payment', 'Paid down my credit card', null, 180.00),

    ('gabesprenger@pacifica.demo', 'purchase', 'Movie tickets for everyone', 'AMC', 22.00),
    ('gabesprenger@pacifica.demo', 'purchase', 'Birthday dinner', 'KBBQ', 48.50),
    ('gabesprenger@pacifica.demo', 'purchase', 'Concert merch', 'A24 Store', 35.00),
    ('gabesprenger@pacifica.demo', 'debt_payment', 'Moved money into savings', null, 100.00),

    ('summermalik@pacifica.demo', 'purchase', 'Emergency iced coffee', 'Starbucks', 7.95),
    ('summermalik@pacifica.demo', 'purchase', 'Apartment supplies', 'Target', 38.12),
    ('summermalik@pacifica.demo', 'purchase', 'Big grocery restock', 'Trader Joe''s', 62.30),
    ('summermalik@pacifica.demo', 'debt_payment', 'Paid toward student loans', null, 125.00),

    ('kevenleon@pacifica.demo', 'purchase', 'Lunch between classes', 'Chipotle', 16.75),
    ('kevenleon@pacifica.demo', 'purchase', 'New textbooks', 'Bookstore', 89.99),
    ('kevenleon@pacifica.demo', 'purchase', 'Laundry and supplies', 'Laundry', 14.00),
    ('kevenleon@pacifica.demo', 'debt_payment', 'Student debt payment', null, 210.00),

    ('raeassepha@pacifica.demo', 'purchase', 'Dunkin run for the group', 'Dunkin', 7.15),
    ('raeassepha@pacifica.demo', 'purchase', 'Thrifted jacket', 'Goodwill', 31.00),
    ('raeassepha@pacifica.demo', 'purchase', 'Ride home after dinner', 'Uber', 21.50),
    ('raeassepha@pacifica.demo', 'debt_payment', 'Added to my rainy day fund', null, 150.00)
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
  demo_posts.post_type,
  demo_posts.caption,
  demo_posts.merchant,
  demo_posts.shared_amount,
  'circle'
from demo_posts
join auth.users users on users.email = demo_posts.email
where not exists (
  select 1
  from public.feed_posts existing
  where existing.user_id = users.id
    and existing.caption = demo_posts.caption
);

with demo_comments(email, post_caption, body) as (
  values
    ('gabesprenger@pacifica.demo', 'Coffee and pastry before class', 'That coffee order is dangerous 😂'),
    ('summermalik@pacifica.demo', 'Birthday dinner', 'Worth it for a birthday.'),
    ('josephposas@pacifica.demo', 'Big grocery restock', 'Meal prep win.'),
    ('raeassepha@pacifica.demo', 'New textbooks', 'Academic weapon behavior.'),
    ('kevenleon@pacifica.demo', 'Thrifted jacket', 'Show us the fit!'),
    ('summermalik@pacifica.demo', 'Student debt payment', 'Huge progress.')
)
insert into public.activity_comments (post_id, user_id, body)
select post.id, commenters.id, demo_comments.body
from demo_comments
join auth.users commenters on commenters.email = demo_comments.email
join public.feed_posts post on post.caption = demo_comments.post_caption
where not exists (
  select 1
  from public.activity_comments existing
  where existing.post_id = post.id
    and existing.user_id = commenters.id
    and existing.body = demo_comments.body
);

with demo_reactions(email, post_caption, reaction_type) as (
  values
    ('summermalik@pacifica.demo', 'Coffee and pastry before class', 'upvote'),
    ('raeassepha@pacifica.demo', 'Coffee and pastry before class', 'downvote'),
    ('josephposas@pacifica.demo', 'Birthday dinner', 'upvote'),
    ('kevenleon@pacifica.demo', 'Big grocery restock', 'upvote'),
    ('gabesprenger@pacifica.demo', 'Big grocery restock', 'upvote'),
    ('summermalik@pacifica.demo', 'New textbooks', 'upvote'),
    ('josephposas@pacifica.demo', 'Thrifted jacket', 'upvote'),
    ('gabesprenger@pacifica.demo', 'Dunkin run for the group', 'downvote')
)
insert into public.reactions (post_id, user_id, reaction_type)
select post.id, raters.id, demo_reactions.reaction_type
from demo_reactions
join auth.users raters on raters.email = demo_reactions.email
join public.feed_posts post on post.caption = demo_reactions.post_caption
where not exists (
  select 1
  from public.reactions existing
  where existing.post_id = post.id
    and existing.user_id = raters.id
);
