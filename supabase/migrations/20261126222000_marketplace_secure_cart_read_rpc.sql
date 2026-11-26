create or replace function public.marketplace_get_cart()
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid := auth.uid();
  v_cart uuid;
  v_items jsonb;
begin
  if v_user is null then raise exception 'Sign in to access your cart'; end if;
  select c.id into v_cart from public.marketplace_carts c where c.user_id = v_user;
  if v_cart is null then return '[]'::jsonb; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',l.id,'title',l.title,'price_ngn',l.price_ngn,'listing_type',l.listing_type,
    'image_urls',l.image_urls,'quantity_available',l.quantity_available,'status',l.status,
    'seller_id',l.seller_id,'cart_item_id',ci.id,'listing_id',ci.listing_id,'quantity',ci.quantity
  ) order by ci.created_at),'[]'::jsonb)
  into v_items
  from public.marketplace_cart_items ci
  join public.marketplace_listings l on l.id=ci.listing_id
  where ci.cart_id=v_cart;
  return v_items;
end;
$function$;
revoke all on function public.marketplace_get_cart() from public, anon;
grant execute on function public.marketplace_get_cart() to authenticated;
