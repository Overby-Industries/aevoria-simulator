import "server-only";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

// TEMPORARY admin gate — checks the caller's own authenticated email
// against a short allowlist. This is a placeholder for a real
// roles/permissions system, not a durable access control model; it's
// here only so admin actions have *some* gate before there are real
// moderators.
const ADMIN_EMAILS = ["founder@overbyindustries.space", "founder@aevoria.space"];

export async function requireAdmin() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user || !ADMIN_EMAILS.includes(user.email ?? "")) {
    redirect("/");
  }
  return user;
}

export async function isAdmin(email: string | null | undefined) {
  return !!email && ADMIN_EMAILS.includes(email);
}
