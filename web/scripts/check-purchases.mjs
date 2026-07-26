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
const { data, error } = await admin
  .from("purchases")
  .select("*")
  .order("created_at", { ascending: false })
  .limit(5);

console.log(JSON.stringify({ data, error }, null, 2));
