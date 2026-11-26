-- Prevent seller payouts before the buyer's payment is confirmed.
-- A payout record represents a completed full settlement for one seller/order pair.
create or replace function public.marketplace_admin_record_seller_payout(
  p_seller_id uuid,
  p_order_id uuid,
  p_amount_ngn integer,
  p_transfer_reference text,
  p_admin_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_order_status text;
  v_payment_status text;
  v_verified_at timestamptz;
  v_gross bigint;
  v_payout uuid;
begin
  if auth.uid() is null or not coalesce(public.is_admin(), false) then
    raise exception 'Only marketplace administrators can record seller payouts';
  end if;
  if p_amount_ngn is null or p_amount_ngn < 1 then
    raise exception 'Enter a payout amount greater than zero';
  end if;
  if char_length(trim(coalesce(p_transfer_reference, ''))) not between 2 and 120 then
    raise exception 'Enter the bank transfer reference';
  end if;
  if p_admin_note is not null and char_length(p_admin_note) > 500 then
    raise exception 'Payout note is too long';
  end if;

  select status, payment_status
    into v_order_status, v_payment_status
  from public.marketplace_orders
  where id = p_order_id
  for update;

  if v_order_status is distinct from 'delivered' then
    raise exception 'Seller payout can only be recorded after the order is fully delivered';
  end if;
  if v_payment_status is distinct from 'confirmed' then
    raise exception 'Buyer payment must be confirmed before seller payout';
  end if;

  select verified_at
    into v_verified_at
  from public.marketplace_seller_payout_accounts
  where seller_id = p_seller_id
  for update;
  if v_verified_at is null then
    raise exception 'Verify the seller payout account before recording payment';
  end if;

  select coalesce(sum(line_total_ngn), 0)
    into v_gross
  from public.marketplace_order_items
  where order_id = p_order_id
    and seller_id = p_seller_id;

  if v_gross < 1 then
    raise exception 'No payable seller items were found for this order';
  end if;
  if p_amount_ngn::bigint <> v_gross then
    raise exception 'Payout must equal the full seller item total of ₦%', v_gross;
  end if;

  insert into public.marketplace_seller_payouts(
    seller_id, order_id, amount_ngn, transfer_reference, admin_note, created_by
  )
  values (
    p_seller_id, p_order_id, p_amount_ngn, trim(p_transfer_reference),
    nullif(trim(coalesce(p_admin_note, '')), ''), auth.uid()
  )
  returning id into v_payout;

  return v_payout;
exception
  when unique_violation then
    raise exception 'A payout has already been recorded for this seller and order';
end;
$function$;
