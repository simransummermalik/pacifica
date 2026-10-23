-- Existing selfie rows were originally created with a 24-hour window.
-- Move active rows to the new five-hour check-in cadence.

update public.daily_selfies
set expires_at = created_at + interval '5 hours'
where expires_at > created_at + interval '5 hours';
