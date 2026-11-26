revoke all on function public.marketplace_place_order(text,text,text,text,text,text,text,text) from public,anon,authenticated;
revoke all on function public.marketplace_remove_from_cart(uuid) from public,anon,authenticated;
revoke all on function public.marketplace_update_cart_quantity(uuid,integer) from public,anon,authenticated;
revoke all on function public.marketplace_submit_seller_application(text,text,text,text,text,text,text) from public,anon,authenticated;
revoke all on function public.marketplace_submit_listing(uuid) from public,anon,authenticated;
