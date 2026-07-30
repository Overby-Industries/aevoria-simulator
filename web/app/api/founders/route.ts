import { NextResponse } from "next/server";
import { createAdminClient } from "@/lib/supabase/admin";

// Public, unauthenticated on purpose -- the Godot client has no
// Supabase session of its own for this (see aevoria_auth.gd), and even if
// it did, purchases RLS only lets a buyer see their OWN purchases, not
// everyone's. The service-role client is the only way to build a public
// founders list; only usernames are ever returned, nothing sensitive.
export const dynamic = "force-dynamic";

const FOUNDING_CITIZEN_PRODUCT_NAME = 'The "Founding Citizen" Commemorative Bundle';

export async function GET() {
  const admin = createAdminClient();

  const { data, error } = await admin
    .from("purchases")
    .select("created_at, profiles(username)")
    .eq("product_name", FOUNDING_CITIZEN_PRODUCT_NAME)
    .order("created_at", { ascending: true });

  if (error) {
    return NextResponse.json({ error: "Could not load founders." }, { status: 500 });
  }

  // Dedupe -- someone buying the bundle more than once shouldn't appear
  // twice on the monument.
  const seen = new Set<string>();
  const founders: string[] = [];
  for (const row of data ?? []) {
    const username = (row.profiles as unknown as { username: string } | null)?.username;
    if (username && !seen.has(username)) {
      seen.add(username);
      founders.push(username);
    }
  }

  return NextResponse.json({ founders });
}
