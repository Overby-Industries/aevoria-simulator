"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { getClientIp, recordSignupSignalAndFlag } from "@/lib/integrity";

const VALID_FACTIONS = ["commonwealth", "syndicate", "nomads"];

export async function createFranchiseAccount(formData: FormData) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login?next=/account/link-franchise");
  }

  const { data: primaryProfile } = await supabase
    .from("profiles")
    .select("faction, linked_primary_id")
    .eq("id", user.id)
    .single();

  if (!primaryProfile?.faction) {
    redirect("/account?error=" + encodeURIComponent("Choose your own faction first."));
  }
  if (primaryProfile.linked_primary_id) {
    redirect(
      "/account?error=" +
        encodeURIComponent("An Independent Franchise account can't itself create another.")
    );
  }

  const admin = createAdminClient();

  // Re-check server-side rather than trusting the page's own eligibility
  // check — enforces "one alt per primary" even under a race.
  const { data: existingAlt } = await admin
    .from("profiles")
    .select("id")
    .eq("linked_primary_id", user.id)
    .maybeSingle();

  if (existingAlt) {
    redirect(
      "/account?error=" + encodeURIComponent("You already have an Independent Franchise account.")
    );
  }

  const email = formData.get("email") as string;
  const password = formData.get("password") as string;
  const username = formData.get("username") as string;
  const faction = formData.get("faction") as string;

  if (!VALID_FACTIONS.includes(faction) || faction === primaryProfile.faction) {
    redirect(
      "/account/link-franchise?error=" +
        encodeURIComponent("Choose a faction different from your Primary account's.")
    );
  }

  // Auto-confirmed: the Primary's own authenticated session is what's
  // vouching for this account, so there's no separate email to confirm.
  const { data: created, error } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: {
      username,
      faction,
      linked_primary_id: user.id,
    },
  });

  if (error || !created.user) {
    redirect(
      "/account/link-franchise?error=" + encodeURIComponent(error?.message ?? "Failed to create account.")
    );
  }

  try {
    const ip = await getClientIp();
    await recordSignupSignalAndFlag(created.user!.id, faction, ip);
  } catch (err) {
    console.error("Failed to record franchise signup signal:", err);
  }

  redirect("/account?franchise_created=1");
}
