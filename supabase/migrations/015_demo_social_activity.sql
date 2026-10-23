-- Give the Activity page a fuller social demo using the five Pacifica accounts.
-- These are feed posts only; they do not change wallet balances.

with demo_names(email, display_name, username) as (
  values
    ('josephposas@pacifica.demo', 'Joseph Posas', 'josephposas'),
    ('gabesprenger@pacifica.demo', 'Gabe Sprenger', 'gabesprenger'),
    ('summermalik@pacifica.demo', 'Summer Malik', 'summermalik'),
    ('kevenleon@pacifica.demo', 'Keven Leon', 'kevenleon'),
    ('raeassepha@pacifica.demo', 'Rae Assepha', 'raeassepha')
)
update public.profiles p
set display_name = demo_names.display_name,
    username = demo_names.username
from auth.users u
join demo_names on demo_names.email = u.email
where p.id = u.id;

with sample_posts(email, post_type, caption, merchant, shared_amount) as (
  values
    ('josephposas@pacifica.demo', 'purchase', 'Coffee run with the circle', 'Starbucks', 8.75),
    ('gabesprenger@pacifica.demo', 'purchase', 'Weekend movie with friends', 'AMC', 18.00),
    ('summermalik@pacifica.demo', 'purchase', 'Groceries for the week', 'Trader Joe''s', 54.20),
    ('kevenleon@pacifica.demo', 'debt_payment', 'Made progress on student debt', null, 75.00),
    ('raeassepha@pacifica.demo', 'purchase', 'Stayed under my coffee budget', 'Dunkin', 6.20),
    ('gabesprenger@pacifica.demo', 'purchase', 'Concert tickets are secured', 'Ticketmaster', 42.00),
    ('summermalik@pacifica.demo', 'purchase', 'Meal prep supplies', 'Whole Foods', 31.40),
    ('kevenleon@pacifica.demo', 'purchase', 'Lunch between classes', 'Chipotle', 14.80),
    ('raeassepha@pacifica.demo', 'purchase', 'Found a thrifted jacket', 'Goodwill', 22.50),
    ('josephposas@pacifica.demo', 'debt_payment', 'Put money toward my savings goal', null, 100.00)
)
insert into public.feed_posts (user_id, post_type, caption, merchant, shared_amount, visibility)
select u.id, s.post_type, s.caption, s.merchant, s.shared_amount, 'circle'
from sample_posts s
join auth.users u on u.email = s.email
where not exists (
  select 1 from public.feed_posts existing
  where existing.user_id = u.id
    and existing.caption = s.caption
);

with sample_comments(email, caption, body) as (
  values
    ('summermalik@pacifica.demo', 'Coffee run with the circle', 'That order is so valid.'),
    ('gabesprenger@pacifica.demo', 'Coffee run with the circle', 'I want in next time.'),
    ('raeassepha@pacifica.demo', 'Weekend movie with friends', 'Worth every dollar.'),
    ('josephposas@pacifica.demo', 'Groceries for the week', 'Trader Joe''s always wins.'),
    ('kevenleon@pacifica.demo', 'Stayed under my coffee budget', 'Huge win.'),
    ('summermalik@pacifica.demo', 'Made progress on student debt', 'Keep going!'),
    ('josephposas@pacifica.demo', 'Concert tickets are secured', 'Send the date.'),
    ('raeassepha@pacifica.demo', 'Meal prep supplies', 'That is a very responsible haul.')
)
insert into public.activity_comments (post_id, user_id, body)
select post.id, commenter.id, sample.body
from sample_comments sample
join auth.users commenter on commenter.email = sample.email
join public.feed_posts post on post.caption = sample.caption
where not exists (
  select 1 from public.activity_comments existing
  where existing.post_id = post.id
    and existing.user_id = commenter.id
    and existing.body = sample.body
);

with sample_reactions(rater_email, post_caption, reaction_type) as (
  values
    ('summermalik@pacifica.demo', 'Coffee run with the circle', 'upvote'),
    ('gabesprenger@pacifica.demo', 'Coffee run with the circle', 'upvote'),
    ('raeassepha@pacifica.demo', 'Weekend movie with friends', 'upvote'),
    ('josephposas@pacifica.demo', 'Weekend movie with friends', 'upvote'),
    ('josephposas@pacifica.demo', 'Groceries for the week', 'upvote'),
    ('kevenleon@pacifica.demo', 'Groceries for the week', 'upvote'),
    ('summermalik@pacifica.demo', 'Made progress on student debt', 'upvote'),
    ('raeassepha@pacifica.demo', 'Meal prep supplies', 'downvote'),
    ('gabesprenger@pacifica.demo', 'Concert tickets are secured', 'upvote'),
    ('kevenleon@pacifica.demo', 'Found a thrifted jacket', 'upvote')
)
insert into public.reactions (post_id, user_id, reaction_type)
select post.id, rater.id, sample.reaction_type
from sample_reactions sample
join auth.users rater on rater.email = sample.rater_email
join public.feed_posts post on post.caption = sample.post_caption
where not exists (
  select 1 from public.reactions existing
  where existing.post_id = post.id
    and existing.user_id = rater.id
);
