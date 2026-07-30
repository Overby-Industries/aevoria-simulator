// One-off, DEV-ONLY -- marks a profile as creator-enabled directly,
// bypassing Stripe Connect onboarding entirely. is_creator and
// stripe_connect_account_id are server-only fields (see
// supabase/migrations/0004_factions_and_integrity.sql's
// prevent_creator_field_self_update trigger) -- only a service-role
// write can set them, which is exactly what this does.
//
// This intentionally does NOT set stripe_connect_account_id, so it's
// only for reaching /creator/create and /creator/upload to test the
// listing flow -- a real payout transfer on an actual sale still needs
// real (test-mode) Stripe Connect onboarding, since there's no fake
// Connect account id that Stripe would accept a transfer to. Fine for
// browsing/demoing the marketplace; not a full substitute for testing
// the payout leg specifically.
//
// Usage:
//   DEV_SUPABASE_URL=https://<dev-project-ref>.supabase.co \
//   DEV_SUPABASE_SERVICE_ROLE_KEY=<dev-service-role-key> \
//   node scripts/dev-grant-creator.mjs <email>
//
// Deliberately does NOT read .env.local -- that file currently points at
// PRODUCTION (NEXT_PUBLIC_SUPABASE_URL there is the prod project), and
// this must never run against it. Refuses to run against anything that
// looks like the production project ref as a guard against copy-paste
// mistakes.
import { createClient } from "@supabase/supabase-js";
import WebSocket from "ws";
globalThis.WebSocket = WebSocket;

const PROD_PROJECT_REF = "hpskqefglvjmdegkptfl";

const url = process.env.DEV_SUPABASE_URL;
const serviceRoleKey = process.env.DEV_SUPABASE_SERVICE_ROLE_KEY;
const targetEmail = process.argv[2];

if (!url || !serviceRoleKey || !targetEmail) {
  console.error(
    "Usage: DEV_SUPABASE_URL=... DEV_SUPABASE_SERVICE_ROLE_KEY=... node scripts/dev-grant-creator.mjs <email>"
  );
  process.exit(1);
}

if (url.includes(PROD_PROJECT_REF)) {
  console.error(`Refusing to run: ${url} looks like the PRODUCTION project. This script is dev-only.`);
  process.exit(1);
}

const admin = createClient(url, serviceRoleKey);

// Admin API lists users rather than looking up by email directly (same
// approach as scripts/confirm-user.mjs).
let user;
let page = 1;
while (!user) {
  const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 200 });
  if (error) throw error;
  user = data.users.find((u) => u.email === targetEmail);
  if (data.users.length < 200) break;
  page++;
}

if (!user) {
  console.error(`No user found with email ${targetEmail} on ${url}`);
  process.exit(1);
}

const { error: updateErr } = await admin.from("profiles").update({ is_creator: true }).eq("id", user.id);
if (updateErr) throw updateErr;

console.log(`Done: ${targetEmail} (${user.id}) is now creator-enabled on ${url}.`);
console.log("You can now reach /creator/create and /creator/upload directly.");
console.log("Note: stripe_connect_account_id was NOT set, so a real sale's payout");
console.log("transfer still needs actual (test-mode) Stripe Connect onboarding --");
console.log("this only unlocks the listing/browsing side for testing and demos.");
