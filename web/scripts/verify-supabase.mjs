// One-off verification script — not part of the app. Confirms the
// Supabase project is reachable, auth works, and the migration's
// auto-profile trigger actually fired. Safe to delete after running.
import { createClient } from "@supabase/supabase-js";
import { readFileSync } from "fs";
import WebSocket from "ws";

// Polyfill for Node 20 (project targets Node 22+, but this standalone
// script runs under whatever's on PATH locally).
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

const url = env.NEXT_PUBLIC_SUPABASE_URL;
const anonKey = env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY;

const testEmail = `founder@overbyindustries.space`;
const testPassword = "verify-test-password-123";

console.log("1. Signing up test user via anon client:", testEmail);
const anon = createClient(url, anonKey);
const { data: signUpData, error: signUpError } = await anon.auth.signUp({
  email: testEmail,
  password: testPassword,
  options: { data: { username: "verify_test_user" } },
});

if (signUpError) {
  console.error("SIGNUP FAILED:", signUpError.message);
  process.exit(1);
}
console.log("   OK — user id:", signUpData.user?.id);

console.log("2. Checking that the auto-profile trigger created a row...");
const admin = createClient(url, serviceKey);
const { data: profile, error: profileError } = await admin
  .from("profiles")
  .select("*")
  .eq("id", signUpData.user.id)
  .single();

if (profileError) {
  console.error("PROFILE LOOKUP FAILED:", profileError.message);
  console.error(
    "   -> Most likely cause: the migration (0001_init.sql) hasn't been run in the Supabase SQL Editor yet."
  );
  process.exit(1);
}
console.log("   OK — profile row:", profile);

console.log("3. Cleaning up test user...");
await admin.auth.admin.deleteUser(signUpData.user.id);
console.log("   OK — deleted.");

console.log("\nAll checks passed: keys are valid, auth works, migration/trigger confirmed working.");
