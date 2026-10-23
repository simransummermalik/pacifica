-- Swift UUID strings can contain uppercase letters. Storage paths are text,
-- so compare both sides in lowercase.

insert into storage.buckets (id, name, public)
values ('daily-selfies', 'daily-selfies', false)
on conflict (id) do nothing;

drop policy if exists "Users can upload their own selfie files" on storage.objects;
create policy "Users can upload their own selfie files"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'daily-selfies'
  and lower((storage.foldername(name))[1]) = lower((select auth.uid()::text))
);

drop policy if exists "Users can view their own selfie files" on storage.objects;
create policy "Users can view their own selfie files"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'daily-selfies'
  and lower((storage.foldername(name))[1]) = lower((select auth.uid()::text))
);

drop policy if exists "Users can delete their own selfie files" on storage.objects;
create policy "Users can delete their own selfie files"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'daily-selfies'
  and lower((storage.foldername(name))[1]) = lower((select auth.uid()::text))
);
