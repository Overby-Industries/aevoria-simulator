// One-off: updates the already-created "Shadow Broker" product's
// description to drop the "smuggler's cache UI theme" promise (no such
// feature exists or is planned -- see docs/GRAPHICS_GUIDE.md's scope
// notes). Only ever run against a test key; the live product needs the
// same edit made by hand in the Stripe dashboard, or this script rerun
// with STRIPE_SECRET_KEY temporarily set to the live key by whoever's
// comfortable handling that credential directly.
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

const NAME = 'The Syndicate "Shadow Broker" Stealth Pack';
const NEW_DESCRIPTION =
  "For the Fringe Nomad or Oligarch Franchise account. Includes matte-black radar-absorbent hull textures and crimson warning lights.";

const existing = await stripe.products.list({ active: true, limit: 100 });
const product = existing.data.find((p) => p.name === NAME);

if (!product) {
  console.error("Could not find product:", NAME);
  process.exit(1);
}

await stripe.products.update(product.id, { description: NEW_DESCRIPTION });
console.log("Updated:", product.id, "->", NEW_DESCRIPTION);
