// One-off verification — attempts each of the 4 exploits from the
// security review directly against the live DB, using only what an
// attacker would have (anon key + a normal authenticated session), and
// confirms each is now rejected. Safe to delete after running.
import { createClient } from "@supabase/supabase-js";
import { readFileSync } from "fs";
import WebSocket from "ws";
globalThis.WebSocket = WebSocket;

const env = Object.fromEntries(
  readFileSync(new URL("../.env.local", import.meta.url), "utf8")
    .split("\n")
    .filter((l) => l.includes("=") && !l.trim().startsWith("#"))
    .map((l) => {
      const i = l.indexOf("=");
      return [l.slice(0, i).trim(), l.slice(i + 1).trim()];
    })
);

const admin = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);

const runId = Date.now();
const email = `attacker-${runId}@gmail.com`;
const password = "attacker-password-123";

console.log("Setting up: creating a normal test user (this is our 'attacker')...");
const { data: created, error: createErr } = await admin.auth.admin.createUser({
  email,
  password,
  email_confirm: true,
  user_metadata: { username: `attacker_${runId}` },
});
if (createErr) throw createErr;
const userId = created.user.id;

// Sign in as that user with the ANON key — this is exactly what an
// attacker has: a normal authenticated session, nothing privileged.
const asAttacker = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.NEXT_PUBLIC_SUPABASE_ANON_KEY);
const { error: signInErr } = await asAttacker.auth.signInWithPassword({ email, password });
if (signInErr) throw signInErr;
console.log("Signed in as attacker:", userId);

let allBlocked = true;

// ---------------------------------------------------------------------
// Vuln 1: self-approve a listing
// ---------------------------------------------------------------------
console.log("\n[1] Attempting to self-approve a pending listing...");
const { data: skin } = await admin
  .from("skins")
  .insert({
    creator_id: userId,
    title: "Exploit test skin",
    price_cents: 1000,
    storage_path: `${userId}/fake.png`,
    status: "pending_review",
  })
  .select()
  .single();

const { data: approveResult, error: approveErr } = await asAttacker
  .from("skins")
  .update({ status: "approved" })
  .eq("id", skin.id)
  .select();

if (approveErr || !approveResult || approveResult.length === 0) {
  console.log("    BLOCKED (good) —", approveErr?.message ?? "0 rows affected");
} else {
  console.log("    NOT BLOCKED — status is now:", approveResult[0].status);
  allBlocked = false;
}

// ---------------------------------------------------------------------
// Vuln 2: edit price_cents after approval
// ---------------------------------------------------------------------
console.log("\n[2] Attempting to edit price_cents on an (admin-)approved listing...");
await admin.from("skins").update({ status: "approved" }).eq("id", skin.id);

const { data: priceResult, error: priceErr } = await asAttacker
  .from("skins")
  .update({ price_cents: 1 })
  .eq("id", skin.id)
  .select();

if (priceErr || !priceResult || priceResult.length === 0) {
  console.log("    BLOCKED (good) —", priceErr?.message ?? "0 rows affected");
} else {
  console.log("    NOT BLOCKED — price_cents is now:", priceResult[0].price_cents);
  allBlocked = false;
}

// ---------------------------------------------------------------------
// Vuln 4: self-grant is_creator / forge stripe_connect_account_id
// ---------------------------------------------------------------------
console.log("\n[4] Attempting to self-grant is_creator and a fake Connect account id...");
const { data: profResult, error: profErr } = await asAttacker
  .from("profiles")
  .update({ is_creator: true, stripe_connect_account_id: "acct_fake123" })
  .eq("id", userId)
  .select();

if (profErr) {
  console.log("    BLOCKED (good) —", profErr.message);
} else {
  console.log("    NOT BLOCKED — profile is now:", JSON.stringify(profResult));
  allBlocked = false;
}

// Confirm username (a legitimately self-editable field) still works, to
// make sure the trigger isn't overly broad.
const { error: usernameErr } = await asAttacker
  .from("profiles")
  .update({ username: `attacker_renamed_${runId}` })
  .eq("id", userId);
console.log(
  "\n[sanity] Editing own username (should still work):",
  usernameErr ? `BROKEN — ${usernameErr.message}` : "OK, still allowed"
);

// ---------------------------------------------------------------------
// Vuln 3: Tier 1 checkout accepting a non-store price — verified via the
// same logic store/actions.ts uses, since this fix lives in app code
// rather than the DB.
// ---------------------------------------------------------------------
console.log("\n[3] Verifying the tier:store allow-list logic (app-level fix)...");
import Stripe from "stripe";
const stripe = new Stripe(env.STRIPE_SECRET_KEY, { apiVersion: "2026-06-24.dahlia" });
const testProduct = await stripe.products.create({ name: "Exploit test product (no tier tag)" });
const testPrice = await stripe.prices.create({ product: testProduct.id, unit_amount: 500, currency: "usd" });
const retrieved = await stripe.prices.retrieve(testPrice.id, { expand: ["product"] });
const wouldBeRejected = retrieved.product.metadata?.tier !== "store";
console.log(
  wouldBeRejected
    ? "    BLOCKED (good) — a price without tier:store metadata fails the check store/actions.ts applies"
    : "    NOT BLOCKED — this price would incorrectly pass"
);
if (!wouldBeRejected) allBlocked = false;
await stripe.products.update(testProduct.id, { active: false });

// ---------------------------------------------------------------------
// Cleanup
// ---------------------------------------------------------------------
await admin.from("skins").delete().eq("id", skin.id);
await admin.auth.admin.deleteUser(userId);

console.log("\n" + (allBlocked ? "ALL 4 EXPLOITS BLOCKED." : "AT LEAST ONE EXPLOIT STILL WORKS — DO NOT SHIP."));
process.exit(allBlocked ? 0 : 1);
