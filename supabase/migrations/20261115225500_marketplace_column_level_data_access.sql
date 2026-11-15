-- Restrict public and authenticated column access to safe Marketplace fields.
-- RLS controls rows; column grants additionally protect private contact and moderation data.
revoke select, insert, update on public.marketplace_sellers from anon, authenticated;
grant select (id,user_id,display_name,seller_type,institution,campus,bio,status,created_at)
on public.marketplace_sellers to anon, authenticated;
grant insert (user_id,display_name,seller_type,institution,campus,bio)
on public.marketplace_sellers to authenticated;
grant update (display_name,seller_type,institution,campus,contact_method,public_contact,bio,status,reviewed_by,reviewed_at,review_note)
on public.marketplace_sellers to authenticated;

revoke select, insert, update on public.marketplace_listings from anon, authenticated;
grant select (id,seller_id,category_id,title,description,listing_type,item_condition,price_ngn,negotiable,location_label,institution,campus,image_urls,status,created_at,published_at)
on public.marketplace_listings to anon, authenticated;
grant insert (seller_id,category_id,title,description,listing_type,item_condition,price_ngn,negotiable,location_label,institution,campus,image_urls,status)
on public.marketplace_listings to authenticated;
grant update (seller_id,category_id,title,description,listing_type,item_condition,price_ngn,negotiable,location_label,institution,campus,image_urls,status,moderation_note,reviewed_by,reviewed_at,published_at)
on public.marketplace_listings to authenticated;
