// One-off fix-up — the initial 3 Tier 1 products were created before the
// `tier: "store"` allow-list metadata existed (security review fix). Adds
// it retroactively so the existing test-mode products still work with
// the now-stricter store/actions.ts check. Safe to re-run.
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

const stripe = new Stripe(env.STRIPE_SECRET_KEY, { apiVersion: "2026-06-24.dahlia" });

const TIER1_NAMES = [
  'The Commonwealth "Stardust Vanguard" Livery Pack',
  'The Syndicate "Shadow Broker" Stealth Pack',
  'The "Founding Citizen" Commemorative Bundle',
];

const products = await stripe.products.list({ active: true, limit: 100 });

for (const product of products.data) {
  if (!TIER1_NAMES.includes(product.name)) continue; // don't touch anything else
  if (product.metadata?.tier === "store") {
    console.log("Already tagged:", product.name);
    continue;
  }
  await stripe.products.update(product.id, { metadata: { tier: "store" } });
  console.log("Tagged:", product.name, "->", product.id);
}

console.log("\nDone.");
