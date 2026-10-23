-- Complete repair for selfie uploads: bucket, file policy, and database row policy.

insert into storage.buckets (id, name, public)
values ('daily-selfies', 'daily-selfies', false)
on conflict (id) do nothing;

alter table public.daily_selfies enable row level security;

drop policy if exists "Users can add their own selfies" on public.daily_selfies;
create policy "Users can add their own selfies"
on public.daily_selfies
for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "Users can upload their own selfie files" on storage.objects;
create policy "Users can upload their own selfie files"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'daily-selfies'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists "Users can view their own selfie files" on storage.objects;
create policy "Users can view their own selfie files"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'daily-selfies'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists "Users can delete their own selfie files" on storage.objects;
create policy "Users can delete their own selfie files"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'daily-selfies'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
