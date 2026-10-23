-- Safe standalone installation of the simulated friend-to-friend transfer RPC.
-- Run this after 001_pacifica_schema.sql if the app reports that send_money
-- cannot be found in the Supabase schema cache.

create or replace function public.send_money(
  p_recipient_id uuid,
  p_amount numeric,
  p_note text default null,
  p_idempotency_key uuid default gen_random_uuid()
)
returns public.transactions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_sender_id uuid := auth.uid();
  v_sender_balance numeric(12,2);
  v_transaction public.transactions;
begin
  if v_sender_id is null then
    raise exception 'You must be signed in';
  end if;

  if p_amount is null or p_amount <= 0 or p_amount <> round(p_amount, 2) then
    raise exception 'Enter a valid amount';
  end if;

  if p_recipient_id = v_sender_id then
    raise exception 'You cannot send money to yourself';
  end if;

  if not exists (select 1 from public.profiles where id = p_recipient_id) then
    raise exception 'Recipient not found';
  end if;

  if not exists (select 1 from public.wallets where user_id = v_sender_id)
     or not exists (select 1 from public.wallets where user_id = p_recipient_id) then
    raise exception 'Wallet not found';
  end if;

  select * into v_transaction
  from public.transactions
  where idempotency_key = p_idempotency_key
    and sender_id = v_sender_id;
  if found then
    return v_transaction;
  end if;

  perform 1 from public.wallets
  where user_id in (v_sender_id, p_recipient_id)
  order by user_id
  for update;

  select demo_balance into v_sender_balance
  from public.wallets
  where user_id = v_sender_id;

  if v_sender_balance < p_amount then
    raise exception 'Insufficient funds';
  end if;

  update public.wallets
  set demo_balance = demo_balance - p_amount, updated_at = now()
  where user_id = v_sender_id;

  update public.wallets
  set demo_balance = demo_balance + p_amount, updated_at = now()
  where user_id = p_recipient_id;

  insert into public.transactions (
    sender_id,
    recipient_id,
    amount,
    note,
    status,
    transaction_type,
    idempotency_key
  ) values (
    v_sender_id,
    p_recipient_id,
    p_amount,
    p_note,
    'completed',
    'payment',
    p_idempotency_key
  )
  returning * into v_transaction;

  return v_transaction;
end;
$$;

revoke all on function public.send_money(uuid, numeric, text, uuid) from public;
grant execute on function public.send_money(uuid, numeric, text, uuid) to authenticated;
