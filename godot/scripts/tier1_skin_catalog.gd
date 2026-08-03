extends RefCounted

## Bridges Tier 1 store purchases (web/scripts/create-tier1-products.mjs)
## into the same equip pipeline Tier 2 marketplace skins already use.
## Tier 1 purchases have no `skins` row (skin_id is null on purpose, see
## 0002_store_purchases.sql) -- there's nothing for the account/assembly UI
## to join against. Instead, each known product name maps to a fixed
## skin_recipe (+ optional decal_path / special_effect) baked in here, so
## "bought the Stardust Vanguard pack" reliably unlocks the same look for
## everyone rather than needing a per-purchase DB row.
##
## Keyed by exact Stripe product name -- matches what actions.ts now writes
## into checkout metadata and the webhook copies into purchases.product_name.
## Product name is more portable than stripe_product_id across dev/live
## Stripe catalogs, which have entirely separate product IDs for the same
## logical item.

const CATALOG = {
	'The Commonwealth "Stardust Vanguard" Livery Pack': {
		"skin_recipe": {
			"seed": 1001, "frequency": 0.05,
			"dark_color": "#d9dde2", "base_color": "#f4f6f8", "highlight_color": "#ffffff",
		},
		# "Zero-waste" particle exhaust effect from the product description --
		# handled entirely in GDScript (assembly_bay.gd), not stored on
		# AssemblyBlueprint, since it's a cosmetic trail effect, not part of
		# the ship's actual rendered geometry/texture.
		"special_effect": "zero_waste_exhaust",
	},
	'The Syndicate "Shadow Broker" Stealth Pack': {
		"skin_recipe": {
			"seed": 2002, "frequency": 0.12,
			"dark_color": "#0d0d0f", "base_color": "#1c1c20", "highlight_color": "#7a1414",
		},
	},
	'The "Founding Citizen" Commemorative Bundle': {
		"skin_recipe": {
			"seed": 3003, "frequency": 0.07,
			"dark_color": "#2a2e36", "base_color": "#5a5f68", "highlight_color": "#b8862b",
		},
		"decal_path": "res://assets/badges/founding_citizen_badge.png",
	},
}

static func get_reward(product_name: String) -> Dictionary:
	return CATALOG.get(product_name, {})
