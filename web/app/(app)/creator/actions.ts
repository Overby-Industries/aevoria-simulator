"use server";

import { redirect } from "next/navigation";
import { headers } from "next/headers";
import { getStripe } from "@/lib/stripe/server";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";

export async function startCreatorOnboarding() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login?next=/account");
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("stripe_connect_account_id")
    .eq("id", user.id)
    .single();

  let accountId = profile?.stripe_connect_account_id;

  // Stripe Connect calls have no try/catch of their own upstream of this --
  // a raw throw here (e.g. Connect not yet enabled on this Stripe account's
  // dashboard, or a live/test key mismatch between the platform key and
  // this account's mode) used to hit Next.js's generic error boundary,
  // which shows no detail on a deployed build. That reads as "nothing
  // happens when I click the button." Surfacing the real Stripe message via
  // the same ?error= redirect pattern creator/create/actions.ts already
  // uses makes the actual cause visible instead.
  try {
    if (!accountId) {
      const account = await getStripe().accounts.create({
        type: "express",
        email: user.email,
        metadata: { supabase_user_id: user.id },
      });
      accountId = account.id;

      // Must use the service-role client — a DB trigger blocks writes to
      // stripe_connect_account_id from any regular user session, precisely
      // so this value can't be self-assigned outside this verified flow.
      // user.id (not client input) is still what scopes the write.
      const admin = createAdminClient();
      await admin
        .from("profiles")
        .update({ stripe_connect_account_id: accountId })
        .eq("id", user.id);
    }

    const origin = (await headers()).get("origin");

    const accountLink = await getStripe().accountLinks.create({
      account: accountId,
      refresh_url: `${origin}/creator/onboard`,
      return_url: `${origin}/creator/onboard/complete`,
      type: "account_onboarding",
    });

    redirect(accountLink.url);
  } catch (err) {
    // redirect() itself throws (Next.js's mechanism for it) -- rethrow that
    // untouched, only intercept real Stripe/DB failures.
    if (err && typeof err === "object" && "digest" in err) {
      throw err;
    }
    const message = err instanceof Error ? err.message : "Stripe onboarding failed.";
    redirect("/creator/onboard?error=" + encodeURIComponent(message));
  }
}
