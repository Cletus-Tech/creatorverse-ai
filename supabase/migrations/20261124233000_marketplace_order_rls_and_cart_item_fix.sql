-- Repair marketplace order RLS helper execution and make cart mutations target owned cart-item IDs.
create or replace function private.marketplace_user_is_order_participant(p_order_id uuid, p_user_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select p_user_id = auth.uid() and (
    exists (select 1 from public.marketplace_orders o where o.id=p_order_id and o.buyer_id=auth.uid())
    or exists (
      select 1 from public.marketplace_order_items oi
      join public.marketplace_sellers s on s.id=oi.seller_id
      where oi.order_id=p_order_id and s.user_id=auth.uid()
    )
  );
$$;
create or replace function private.marketplace_user_owns_order_item(p_order_id uuid,p_seller_id uuid,p_user_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select p_user_id = auth.uid() and (
    exists (select 1 from public.marketplace_orders o where o.id=p_order_id and o.buyer_id=auth.uid())
    or exists (select 1 from public.marketplace_sellers s where s.id=p_seller_id and s.user_id=auth.uid())
  );
$$;
grant usage on schema private to authenticated;
grant execute on function private.marketplace_user_is_order_participant(uuid,uuid) to authenticated;
grant execute on function private.marketplace_user_owns_order_item(uuid,uuid,uuid) to authenticated;

create or replace function public.marketplace_update_cart_item(p_cart_item_id uuid,p_quantity integer)
returns void language plpgsql security definer set search_path = ''
as $$
declare v_user uuid:=auth.uid(); v_stock integer; v_listing uuid;
begin
  if v_user is null then raise exception 'Sign in first'; end if;
  if p_quantity is null or p_quantity<1 or p_quantity>99 then raise exception 'Quantity must be between 1 and 99'; end if;
  select ci.listing_id,l.quantity_available into v_listing,v_stock
  from public.marketplace_cart_items ci
  join public.marketplace_carts c on c.id=ci.cart_id
  join public.marketplace_listings l on l.id=ci.listing_id
  where ci.id=p_cart_item_id and c.user_id=v_user and l.status='published'
  for update of ci;
  if v_listing is null then raise exception 'This cart item is no longer available. Refresh your cart.'; end if;
  if p_quantity>v_stock then raise exception 'Only % item(s) are currently available',v_stock; end if;
  update public.marketplace_cart_items set quantity=p_quantity,updated_at=now() where id=p_cart_item_id;
end;
$$;
create or replace function public.marketplace_remove_cart_item(p_cart_item_id uuid)
returns void language plpgsql security definer set search_path = ''
as $$
declare v_user uuid:=auth.uid();
begin
  if v_user is null then raise exception 'Sign in first'; end if;
  delete from public.marketplace_cart_items ci using public.marketplace_carts c
  where ci.cart_id=c.id and ci.id=p_cart_item_id and c.user_id=v_user;
  if not found then raise exception 'This cart item is no longer in your cart. Refresh and try again.'; end if;
end;
$$;
grant execute on function public.marketplace_update_cart_item(uuid,integer) to authenticated;
grant execute on function public.marketplace_remove_cart_item(uuid) to authenticated;

revoke execute on function public.marketplace_update_cart_item(uuid,integer) from public, anon;
revoke execute on function public.marketplace_remove_cart_item(uuid) from public, anon;
grant execute on function public.marketplace_update_cart_item(uuid,integer) to authenticated;
grant execute on function public.marketplace_remove_cart_item(uuid) to authenticated;
