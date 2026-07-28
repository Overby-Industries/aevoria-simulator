// One-off — manually confirms a user's email via the Admin API, bypassing
// the need for Supabase to actually send (and you to click) a
// confirmation email. Usage: node scripts/confirm-user.mjs <email>
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

const targetEmail = process.argv[2];
if (!targetEmail) {
  console.error("Usage: node scripts/confirm-user.mjs <email>");
  process.exit(1);
}

const admin = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);

// Admin API lists users rather than looking up by email directly.
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
  console.error(`No user found with email ${targetEmail}`);
  process.exit(1);
}

if (user.email_confirmed_at) {
  console.log(`${targetEmail} is already confirmed (since ${user.email_confirmed_at}).`);
  process.exit(0);
}

const { error: updateErr } = await admin.auth.admin.updateUserById(user.id, {
  email_confirm: true,
});
if (updateErr) throw updateErr;

console.log(`Confirmed: ${targetEmail} (user id ${user.id}). You can log in now.`);
