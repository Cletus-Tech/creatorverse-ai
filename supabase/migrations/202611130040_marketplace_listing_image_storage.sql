-- Public listing photos; only authenticated owners may upload/delete within
-- their own UUID folder. Public read is intentional because published listing
-- images are public catalogue content, not private identity documents.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'marketplace-listing-images',
  'marketplace-listing-images',
  true,
  5242880,
  array['image/jpeg','image/png','image/webp','image/avif']
)
on conflict (id) do nothing;

drop policy if exists "Marketplace listing images are publicly readable" on storage.objects;
create policy "Marketplace listing images are publicly readable"
on storage.objects for select
to public
using (bucket_id = 'marketplace-listing-images');

drop policy if exists "Sellers upload images to their own folder" on storage.objects;
create policy "Sellers upload images to their own folder"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'marketplace-listing-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "Sellers delete images from their own folder" on storage.objects;
create policy "Sellers delete images from their own folder"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'marketplace-listing-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
