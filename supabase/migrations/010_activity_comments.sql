-- Comments for shared circle activity.

create table if not exists public.activity_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.feed_posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(trim(body)) between 1 and 280),
  created_at timestamptz not null default now()
);

create index if not exists activity_comments_post_created_idx
on public.activity_comments(post_id, created_at);

alter table public.activity_comments enable row level security;

drop policy if exists "Users can view circle comments" on public.activity_comments;
create policy "Users can view circle comments"
on public.activity_comments for select to authenticated
using (
  exists (
    select 1
    from public.feed_posts p
    where p.id = activity_comments.post_id
      and p.visibility = 'circle'
  )
);

drop policy if exists "Users can add their own comments" on public.activity_comments;
create policy "Users can add their own comments"
on public.activity_comments for insert to authenticated
with check (
  user_id = auth.uid()
  and exists (
    select 1
    from public.feed_posts p
    where p.id = activity_comments.post_id
      and p.visibility = 'circle'
  )
);

drop policy if exists "Users can delete their own comments" on public.activity_comments;
create policy "Users can delete their own comments"
on public.activity_comments for delete to authenticated
using (user_id = auth.uid());
