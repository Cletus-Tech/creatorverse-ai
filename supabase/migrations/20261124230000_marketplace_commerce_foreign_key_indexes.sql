-- Cover marketplace foreign keys used by joins, ownership checks and cleanup.
create index if not exists marketplace_cart_items_listing_idx on public.marketplace_cart_items(listing_id);
create index if not exists marketplace_order_events_actor_idx on public.marketplace_order_events(actor_id);
create index if not exists marketplace_order_items_listing_idx on public.marketplace_order_items(listing_id);
create index if not exists marketplace_returns_order_idx on public.marketplace_return_requests(order_id);
create index if not exists marketplace_returns_order_item_idx on public.marketplace_return_requests(order_item_id);
create index if not exists marketplace_reviews_buyer_idx on public.marketplace_reviews(buyer_id);
create index if not exists marketplace_reviews_order_idx on public.marketplace_reviews(order_id);
create index if not exists marketplace_reviews_seller_idx on public.marketplace_reviews(seller_id);
