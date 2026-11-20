-- Published future slides must be readable by the display so it can schedule their start.
drop policy if exists "Public can read active billboard items" on public.billboard_items;
create policy "Public can read published billboard items"
  on public.billboard_items for select to anon, authenticated
  using (is_published = true and (ends_at is null or ends_at > now()));
