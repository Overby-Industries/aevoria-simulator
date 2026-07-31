"use server";

import { redirect } from "next/navigation";
import { headers } from "next/headers";
import { getStripe } from "@/lib/stripe/server";
import { createClient } from "@/lib/supabase/server";

// Creators keep 85% of gross (per MONETIZATION_STRATEGY.md); Stripe's own
// processing fee comes out of the platform's 15% cut, not the creator's.
const PLATFORM_FEE_RATE = 0.15;

function errorRedirect(message: string): never {
  redirect("/marketplace?error=" + encodeURIComponent(message));
}

export async function createSkinCheckoutSession(formData: FormData) {
  const skinId = formData.get("skinId") as string;
  if (!skinId) errorRedirect("Missing item.");

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect(`/login?next=/marketplace`);
  }

  // Re-fetch the listing server-side rather than trusting anything about
  // it from the client — status and price come straight from the DB.
  const { data: skin } = await supabase
    .from("skins")
    .select("id, title, price_cents, status, stripe_price_id, creator_id")
    .eq("id", skinId)
    .single();

  // These used to be bare throw new Error(...) calls -- an uncaught throw
  // in a server action hits Next.js's generic error boundary, which shows
  // no detail on a deployed build (same failure mode as the Stripe Connect
  // onboarding bug fixed earlier). "Buy" appearing to do nothing was
  // exactly this: e.g. a creator clicking Buy on their own listing hit the
  // creator_id === user.id check below and threw, silently.
  if (!skin || skin.status !== "approved" || !skin.stripe_price_id) {
    errorRedirect("This item isn't available for purchase.");
  }

  if (skin.creator_id === user.id) {
    errorRedirect("You can't buy your own listing -- it's already yours. Find it under \"My Creations\" in the Assembly Bay, no purchase needed.");
  }

  const { data: creatorProfile } = await supabase
    .from("profiles")
    .select("stripe_connect_account_id")
    .eq("id", skin.creator_id)
    .single();

  if (!creatorProfile?.stripe_connect_account_id) {
    errorRedirect("This creator hasn't finished payout setup yet.");
  }

  // Compute the fee from the frozen Stripe Price's actual amount, not the
  // mutable skins.price_cents column — the two can drift (price_cents is
  // editable while a listing is pending review), and the buyer is always
  // charged whatever this Price says regardless of the DB column, so the
  // fee must be derived from the same source of truth.
  const stripePrice = await getStripe().prices.retrieve(skin.stripe_price_id);
  const actualAmountCents = stripePrice.unit_amount ?? 0;
  const applicationFeeCents = Math.round(actualAmountCents * PLATFORM_FEE_RATE);
  const origin = (await headers()).get("origin");

  const session = await getStripe().checkout.sessions.create({
    mode: "payment",
    line_items: [{ price: skin.stripe_price_id, quantity: 1 }],
    payment_intent_data: {
      application_fee_amount: applicationFeeCents,
      transfer_data: {
        destination: creatorProfile.stripe_connect_account_id,
      },
    },
    success_url: `${origin}/marketplace/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${origin}/marketplace`,
    client_reference_id: user.id,
    metadata: {
      kind: "tier2_skin_purchase",
      buyer_id: user.id,
      skin_id: skin.id,
    },
  });

  if (!session.url) {
    errorRedirect("Stripe did not return a checkout URL.");
  }

  redirect(session.url);
}
