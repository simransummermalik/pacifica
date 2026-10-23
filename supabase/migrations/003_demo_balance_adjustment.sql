-- Run after 001_pacifica_schema.sql.
-- Keeps demo balance changes atomic and limited to the signed-in user's wallet.

create or replace function public.adjust_demo_balance(p_delta numeric)
returns public.wallets
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_wallet public.wallets;
begin
  if v_user_id is null then
    raise exception 'You must be signed in';
  end if;

  if p_delta is null or p_delta = 0 or p_delta <> round(p_delta, 2) then
    raise exception 'Enter a valid amount';
  end if;

  select * into v_wallet
  from public.wallets
  where user_id = v_user_id
  for update;

  if not found then
    raise exception 'Wallet not found';
  end if;

  if v_wallet.demo_balance + p_delta < 0 then
    raise exception 'Insufficient demo funds';
  end if;

  update public.wallets
  set demo_balance = demo_balance + p_delta, updated_at = now()
  where user_id = v_user_id
  returning * into v_wallet;

  return v_wallet;
end;
$$;

revoke all on function public.adjust_demo_balance(numeric) from public;
grant execute on function public.adjust_demo_balance(numeric) to authenticated;
