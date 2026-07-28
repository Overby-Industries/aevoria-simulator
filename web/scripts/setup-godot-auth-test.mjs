// One-off: creates a pre-confirmed test account plus a fake purchase row
// (bypassing Stripe) against an existing approved skin, so the Godot
// client's AevoriaAuth login + fetch_owned_skins() can be verified against
// the real live Supabase project. Prints credentials + ids for the Godot
// test script and for cleanup. Safe to delete after use.
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
const testEmail = `test-godot-auth-${runId}@gmail.com`;
const testPassword = "test-password-123";

const { data: created, error: createErr } = await admin.auth.admin.createUser({
  email: testEmail,
  password: testPassword,
  email_confirm: true,
  user_metadata: { username: `test_godot_${runId}` },
});
if (createErr) {
  console.error("createUser failed:", createErr.message);
  process.exit(1);
}
const userId = created.user.id;

// Create the creator profile + skin directly via service role (bypassing
// the whole submit/review flow) -- this test only cares that an approved
// skin exists to purchase, not how it got approved.
const { data: creatorUser, error: creatorErr } = await admin.auth.admin.createUser({
  email: `test-godot-creator-${runId}@gmail.com`,
  password: testPassword,
  email_confirm: true,
  user_metadata: { username: `test_godot_creator_${runId}` },
});
if (creatorErr) {
  console.error("creator createUser failed:", creatorErr.message);
  process.exit(1);
}

const { data: approvedSkin, error: skinErr } = await admin
  .from("skins")
  .insert({
    creator_id: creatorUser.user.id,
    title: `Godot Auth Test Skin ${runId}`,
    price_cents: 150,
    recipe: { pattern: "cellular", seed: 1, frequency: 0.08, darkColor: "#26201a", baseColor: "#8a8f96", highlightColor: "#c7ccd1" },
    status: "approved",
  })
  .select("id, title")
  .single();
if (skinErr || !approvedSkin) {
  console.error("test skin insert failed:", skinErr?.message);
  process.exit(1);
}

const { error: purchaseErr } = await admin.from("purchases").insert({
  buyer_id: userId,
  skin_id: approvedSkin.id,
  stripe_payment_intent_id: `pi_test_${runId}`,
  amount_cents: 150,
  platform_fee_cents: 15,
  creator_payout_cents: 135,
});
if (purchaseErr) {
  console.error("purchase insert failed:", purchaseErr.message);
  process.exit(1);
}

console.log(JSON.stringify({
  email: testEmail,
  password: testPassword,
  userId,
  creatorUserId: creatorUser.user.id,
  skinId: approvedSkin.id,
  skinTitle: approvedSkin.title,
}));
