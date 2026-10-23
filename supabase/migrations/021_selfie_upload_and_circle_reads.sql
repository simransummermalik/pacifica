-- Make selfie uploads reliable and allow active circle selfies to appear on
-- the matching fish in the Activity reef.

insert into storage.buckets (id, name, public)
values ('daily-selfies', 'daily-selfies', false)
on conflict (id) do nothing;

alter table public.daily_selfies enable row level security;

drop policy if exists "Users can add their own selfies" on public.daily_selfies;
create policy "Users can add their own selfies"
on public.daily_selfies
for insert to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "Users can view their own selfies" on public.daily_selfies;
drop policy if exists "Friends can view active selfies" on public.daily_selfies;
drop policy if exists "Circle members can view active selfies" on public.daily_selfies;
create policy "Circle members can view active selfies"
on public.daily_selfies
for select to authenticated
using (
  expires_at > now()
  and user_id is not null
);

drop policy if exists "Users can delete their own selfies" on public.daily_selfies;
create policy "Users can delete their own selfies"
on public.daily_selfies
for delete to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Users can upload their own selfie files" on storage.objects;
create policy "Users can upload their own selfie files"
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'daily-selfies'
  and lower((storage.foldername(name))[1]) = lower((select auth.uid()::text))
);

drop policy if exists "Users can view their own selfie files" on storage.objects;
drop policy if exists "Friends can view active selfie files" on storage.objects;
drop policy if exists "Circle members can view active selfie files" on storage.objects;
create policy "Circle members can view active selfie files"
on storage.objects
for select to authenticated
using (
  bucket_id = 'daily-selfies'
  and exists (
    select 1
    from public.daily_selfies ds
    where ds.storage_path = storage.objects.name
      and ds.expires_at > now()
  )
);

drop policy if exists "Users can delete their own selfie files" on storage.objects;
create policy "Users can delete their own selfie files"
on storage.objects
for delete to authenticated
using (
  bucket_id = 'daily-selfies'
  and lower((storage.foldername(name))[1]) = lower((select auth.uid()::text))
);
