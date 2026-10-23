-- Run this migration after 001_pacifica_schema.sql.
-- Accepting a request moves simulated money atomically and records a transaction.

create or replace function public.respond_to_payment_request(
  p_request_id uuid,
  p_action text,
  p_idempotency_key uuid default gen_random_uuid()
)
returns public.payment_requests
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_request public.payment_requests;
  v_payer_balance numeric(12,2);
begin
  if v_user_id is null then
    raise exception 'You must be signed in';
  end if;

  if p_action not in ('accepted', 'declined') then
    raise exception 'Invalid payment request action';
  end if;

  select * into v_request
  from public.payment_requests
  where id = p_request_id
    and recipient_id = v_user_id
    and status = 'pending'
  for update;

  if not found then
    raise exception 'Pending payment request not found';
  end if;

  if p_action = 'declined' then
    update public.payment_requests
    set status = 'declined', responded_at = now()
    where id = p_request_id
    returning * into v_request;
    return v_request;
  end if;

  perform 1 from public.wallets
  where user_id in (v_request.recipient_id, v_request.requester_id)
  order by user_id
  for update;

  select demo_balance into v_payer_balance
  from public.wallets
  where user_id = v_request.recipient_id;

  if v_payer_balance < v_request.amount then
    raise exception 'Insufficient funds';
  end if;

  update public.wallets
  set demo_balance = demo_balance - v_request.amount, updated_at = now()
  where user_id = v_request.recipient_id;

  update public.wallets
  set demo_balance = demo_balance + v_request.amount, updated_at = now()
  where user_id = v_request.requester_id;

  insert into public.transactions (
    sender_id,
    recipient_id,
    amount,
    note,
    status,
    transaction_type,
    idempotency_key
  ) values (
    v_request.recipient_id,
    v_request.requester_id,
    v_request.amount,
    v_request.note,
    'completed',
    'payment_request',
    p_idempotency_key
  );

  update public.payment_requests
  set status = 'accepted', responded_at = now()
  where id = p_request_id
  returning * into v_request;

  return v_request;
end;
$$;

revoke all on function public.respond_to_payment_request(uuid, text, uuid) from public;
grant execute on function public.respond_to_payment_request(uuid, text, uuid) to authenticated;
