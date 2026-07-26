-- Generalizes `purchases` to also cover Tier 1 (official first-party store
-- items, e.g. livery packs), which aren't rows in `skins` — those are
-- creator-submitted Tier 2 marketplace listings. Run in the SQL Editor
-- after 0001_init.sql.

alter table public.purchases
  alter column skin_id drop not null,
  add column stripe_product_id text,
  add column stripe_price_id text;

-- Every purchase must identify what was bought, one way or the other.
alter table public.purchases
  add constraint purchases_identifies_item
  check (skin_id is not null or stripe_price_id is not null);
