// One-off setup script — creates the Tier 1 store products (from
// docs/MONETIZATION_STRATEGY.md) in whichever Stripe mode the configured
// key points to. Safe to re-run; skips any product that already exists
// with the same name.
import Stripe from "stripe";
import { readFileSync } from "fs";

const env = Object.fromEntries(
  readFileSync(new URL("../.env.local", import.meta.url), "utf8")
    .split("\n")
    .filter((l) => l.includes("=") && !l.trim().startsWith("#"))
    .map((l) => {
      const i = l.indexOf("=");
      return [l.slice(0, i).trim(), l.slice(i + 1).trim()];
    })
);

if (!env.STRIPE_SECRET_KEY?.startsWith("sk_test_")) {
  console.error("Refusing to run: STRIPE_SECRET_KEY is not a sk_test_ key.");
  process.exit(1);
}

const stripe = new Stripe(env.STRIPE_SECRET_KEY, {
  apiVersion: "2026-06-24.dahlia",
});

const PRODUCTS = [
  {
    name: 'The Commonwealth "Stardust Vanguard" Livery Pack',
    description:
      "A pristine, high-visibility aesthetic for the Aevoric Commonwealth. Includes pearlescent white hull coatings, gold-trimmed miner pod decals, and a subtle \"zero-waste\" particle exhaust effect.",
    priceCents: 499,
  },
  {
    name: 'The Syndicate "Shadow Broker" Stealth Pack',
    description:
      "For the Fringe Nomad or Oligarch Franchise account. Includes matte-black radar-absorbent hull textures and crimson warning lights.",
    priceCents: 499,
  },
  {
    name: 'The "Founding Citizen" Commemorative Bundle',
    description:
      'Limited-edition bundle available only during the Alpha/Beta phase. Includes a unique "Overby Industries Prototype" hull badge, a custom SSTO Starlifter decal, and your name etched into the Founders Monument loading screen.',
    priceCents: 999,
  },
];

const existing = await stripe.products.list({ active: true, limit: 100 });

for (const item of PRODUCTS) {
  if (existing.data.some((p) => p.name === item.name)) {
    console.log("SKIP (already exists):", item.name);
    continue;
  }

  const product = await stripe.products.create({
    name: item.name,
    description: item.description,
    // Positive allow-list marker checked by web/app/store/actions.ts —
    // only prices on products carrying this are purchasable through the
    // Tier 1 store flow.
    metadata: { tier: "store" },
  });

  const price = await stripe.prices.create({
    product: product.id,
    unit_amount: item.priceCents,
    currency: "usd",
  });

  await stripe.products.update(product.id, { default_price: price.id });

  console.log("CREATED:", item.name, "->", product.id, price.id);
}

console.log("\nDone.");
