-- Daily selfie storage/table setup for the activitypage branch.
-- Run after the main Pacifica schema exists.

insert into storage.buckets (id, name, public)
values ('daily-selfies', 'daily-selfies', false)
on conflict (id) do nothing;

create table if not exists public.daily_selfies (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  storage_path text not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  check (expires_at > created_at)
);

create index if not exists daily_selfies_user_expiry_idx
on public.daily_selfies(user_id, expires_at);

alter table public.daily_selfies enable row level security;

drop policy if exists "Users can view their own selfies" on public.daily_selfies;
create policy "Users can view their own selfies"
on public.daily_selfies for select to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "Friends can view active selfies" on public.daily_selfies;
create policy "Friends can view active selfies"
on public.daily_selfies for select to authenticated
using (
  expires_at > now()
  and exists (
    select 1
    from public.friendships f
    where f.status = 'accepted'
      and (
        (f.requester_id = (select auth.uid()) and f.recipient_id = daily_selfies.user_id)
        or
        (f.recipient_id = (select auth.uid()) and f.requester_id = daily_selfies.user_id)
      )
  )
);

drop policy if exists "Users can add their own selfies" on public.daily_selfies;
create policy "Users can add their own selfies"
on public.daily_selfies for insert to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists "Users can delete their own selfies" on public.daily_selfies;
create policy "Users can delete their own selfies"
on public.daily_selfies for delete to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "Users can upload their own selfie files" on storage.objects;
create policy "Users can upload their own selfie files"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'daily-selfies'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists "Users can view their own selfie files" on storage.objects;
create policy "Users can view their own selfie files"
on storage.objects for select to authenticated
using (
  bucket_id = 'daily-selfies'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists "Friends can view active selfie files" on storage.objects;
create policy "Friends can view active selfie files"
on storage.objects for select to authenticated
using (
  bucket_id = 'daily-selfies'
  and exists (
    select 1
    from public.daily_selfies ds
    join public.friendships f on f.status = 'accepted'
    where ds.storage_path = storage.objects.name
      and ds.expires_at > now()
      and (
        (f.requester_id = (select auth.uid()) and f.recipient_id = ds.user_id)
        or
        (f.recipient_id = (select auth.uid()) and f.requester_id = ds.user_id)
      )
  )
);

drop policy if exists "Users can delete their own selfie files" on storage.objects;
create policy "Users can delete their own selfie files"
on storage.objects for delete to authenticated
using (
  bucket_id = 'daily-selfies'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
