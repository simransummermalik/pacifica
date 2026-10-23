-- Make the selfie insert policy match the authenticated Supabase session.

alter table public.daily_selfies enable row level security;

drop policy if exists "Users can add their own selfies" on public.daily_selfies;
create policy "Users can add their own selfies"
on public.daily_selfies
for insert
to authenticated
with check ((select auth.uid()) = user_id);
