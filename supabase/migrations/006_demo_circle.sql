-- Demo circle: connect every Pacifica demo account to every other demo account.
-- In Pacifica, accepted friendships are the current implementation of a circle.

with demo_users as (
  select id
  from auth.users
  where email like '%@pacifica.demo'
), pairs as (
  select
    a.id as requester_id,
    b.id as recipient_id
  from demo_users a
  join demo_users b on a.id < b.id
)
insert into public.friendships (requester_id, recipient_id, status)
select pairs.requester_id, pairs.recipient_id, 'accepted'
from pairs
where exists (
  select 1
  from public.profiles p
  where p.id = pairs.requester_id
)
and exists (
  select 1
  from public.profiles p
  where p.id = pairs.recipient_id
)
and not exists (
  select 1
  from public.friendships f
  where least(f.requester_id, f.recipient_id) = pairs.requester_id
    and greatest(f.requester_id, f.recipient_id) = pairs.recipient_id
);
