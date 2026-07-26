"use server";

import { redirect } from "next/navigation";
import { headers } from "next/headers";
import type Stripe from "stripe";
import { stripe } from "@/lib/stripe/server";
import { createClient } from "@/lib/supabase/server";

export async function createCheckoutSession(formData: FormData) {
  const priceId = formData.get("priceId") as string;
  if (!priceId) {
    throw new Error("Missing priceId");
  }

  // Require a real account so the purchase can be tied to it. Never trust
  // a client-submitted user id — always read it from the authenticated
  // server-side session.
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect(`/login?next=/store`);
  }

  // Re-validate the price server-side rather than trusting the form value
  // blindly. This must confirm both that the price is active AND that it
  // actually belongs to the first-party store catalog (tier: "store" on
  // the product) — otherwise any active price in the account, including a
  // Tier 2 creator's approved skin, could be bought here with no revenue
  // split and no record of the sale reaching the creator.
  const price = await stripe.prices.retrieve(priceId, { expand: ["product"] });
  const product = price.product as Stripe.Product;
  if (!price.active || product.deleted || product.metadata?.tier !== "store") {
    throw new Error("This item isn't available in the store.");
  }

  const origin = (await headers()).get("origin");

  const session = await stripe.checkout.sessions.create({
    mode: "payment",
    line_items: [{ price: price.id, quantity: 1 }],
    success_url: `${origin}/store/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${origin}/store`,
    client_reference_id: user.id,
    metadata: {
      kind: "tier1_store_item",
      buyer_id: user.id,
      stripe_price_id: price.id,
      stripe_product_id: product.id,
    },
  });

  if (!session.url) {
    throw new Error("Stripe did not return a checkout URL.");
  }

  redirect(session.url);
}
