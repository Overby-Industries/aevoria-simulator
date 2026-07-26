"use server";

import { redirect } from "next/navigation";
import { headers } from "next/headers";
import { stripe } from "@/lib/stripe/server";
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

  if (!accountId) {
    const account = await stripe.accounts.create({
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

  const accountLink = await stripe.accountLinks.create({
    account: accountId,
    refresh_url: `${origin}/creator/onboard`,
    return_url: `${origin}/creator/onboard/complete`,
    type: "account_onboarding",
  });

  redirect(accountLink.url);
}
