-- Tier 1 store purchases only ever carried opaque Stripe IDs
-- (stripe_product_id/stripe_price_id) -- fine for records, but the Godot
-- client needs a stable, human-readable way to recognize "this purchase
-- is the Stardust Vanguard Livery Pack" so it can unlock the matching
-- fixed skin recipe (see aevoria-simulator/scripts/tier1_skin_catalog.gd).
-- Storing the product name at purchase time is simpler and more portable
-- across dev/live Stripe catalogs (which have different product IDs) than
-- hardcoding IDs on the Godot side.
alter table public.purchases
  add column product_name text;
