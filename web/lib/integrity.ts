import "server-only";
import { headers } from "next/headers";
import { createAdminClient } from "@/lib/supabase/admin";

export async function getClientIp(): Promise<string | null> {
  const h = await headers();
  // x-forwarded-for can be a comma-separated chain (client, proxy1, proxy2...)
  const forwarded = h.get("x-forwarded-for");
  if (forwarded) return forwarded.split(",")[0].trim();
  return h.get("x-real-ip");
}

/**
 * Records the signup IP for a new account and flags it for human review
 * if another account already exists with the same IP AND the same
 * faction — this does not block anything or take any action itself; it
 * only surfaces a case in /admin/flags. Same-IP-different-faction (e.g.
 * a legitimately linked Primary + Independent Franchise) is expected and
 * never flagged.
 */
export async function recordSignupSignalAndFlag(
  profileId: string,
  faction: string | null,
  ip: string | null
) {
  if (!ip) return;

  const admin = createAdminClient();

  await admin.from("account_signals").insert({ profile_id: profileId, signup_ip: ip });

  if (!faction) return;

  const { data: sameIp } = await admin
    .from("account_signals")
    .select("profile_id")
    .eq("signup_ip", ip)
    .neq("profile_id", profileId);

  const candidateIds = [...new Set((sameIp ?? []).map((r) => r.profile_id))];
  if (candidateIds.length === 0) return;

  const { data: sameFaction } = await admin
    .from("profiles")
    .select("id")
    .in("id", candidateIds)
    .eq("faction", faction);

  for (const match of sameFaction ?? []) {
    await admin.from("integrity_flags").insert({
      flagged_profile_id: profileId,
      related_profile_id: match.id,
      flag_type: "same_ip_same_faction",
      details: { ip, faction },
    });
  }
}
