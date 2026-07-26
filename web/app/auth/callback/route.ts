import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

// Handles the redirect after a user clicks the confirmation link in the
// signup email — exchanges the one-time code for a real session.
export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  const next = searchParams.get("next") ?? "/account";

  if (code) {
    const supabase = await createClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) {
      return NextResponse.redirect(`${origin}${next}`);
    }
  }

  return NextResponse.redirect(`${origin}/login?error=Could not confirm email`);
}
