import { NextResponse } from "next/server";
import type Stripe from "stripe";
import { getStripe } from "@/lib/stripe/server";
import { createAdminClient } from "@/lib/supabase/admin";

export async function POST(request: Request) {
  // Raw body is required for signature verification — Next.js App Router
  // route handlers don't auto-parse the body, so request.text() gives us
  // the exact bytes Stripe signed.
  const rawBody = await request.text();
  const signature = request.headers.get("stripe-signature");

  if (!signature) {
    return NextResponse.json({ error: "Missing signature" }, { status: 400 });
  }

  let event: Stripe.Event;
  try {
    event = getStripe().webhooks.constructEvent(
      rawBody,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch (err) {
    console.error("Webhook signature verification failed:", err);
    return NextResponse.json({ error: "Invalid signature" }, { status: 400 });
  }

  if (event.type === "checkout.session.completed") {
    const session = event.data.object as Stripe.Checkout.Session;
    await handleCheckoutCompleted(session);
  }

  return NextResponse.json({ received: true });
}

async function handleCheckoutCompleted(session: Stripe.Checkout.Session) {
  const kind = session.metadata?.kind;
  const buyerId = session.metadata?.buyer_id;
  const paymentIntentId =
    typeof session.payment_intent === "string"
      ? session.payment_intent
      : session.payment_intent?.id;

  if (!buyerId || !paymentIntentId) {
    console.error("Webhook missing buyer_id or payment_intent", session.id);
    return;
  }

  const amountCents = session.amount_total ?? 0;
  const admin = createAdminClient();

  let purchaseRow: Record<string, unknown>;

  if (kind === "tier1_store_item") {
    // Official first-party store items — no creator split, full amount is
    // platform revenue.
    purchaseRow = {
      buyer_id: buyerId,
      skin_id: null,
      stripe_payment_intent_id: paymentIntentId,
      amount_cents: amountCents,
      platform_fee_cents: amountCents,
      creator_payout_cents: 0,
      stripe_product_id: session.metadata?.stripe_product_id ?? null,
      stripe_price_id: session.metadata?.stripe_price_id ?? null,
    };
  } else if (kind === "tier2_skin_purchase") {
    const skinId = session.metadata?.skin_id;
    if (!skinId) {
      console.error("Tier 2 webhook missing skin_id", session.id);
      return;
    }

    // Read the actual application fee off the PaymentIntent rather than
    // recomputing it — this is what Stripe actually charged, the
    // authoritative source rather than our own remembered intent.
    const paymentIntent = await getStripe().paymentIntents.retrieve(paymentIntentId);
    const platformFeeCents = paymentIntent.application_fee_amount ?? 0;

    purchaseRow = {
      buyer_id: buyerId,
      skin_id: skinId,
      stripe_payment_intent_id: paymentIntentId,
      amount_cents: amountCents,
      platform_fee_cents: platformFeeCents,
      creator_payout_cents: amountCents - platformFeeCents,
    };
  } else {
    console.error("Unknown checkout kind in webhook metadata:", kind, session.id);
    return;
  }

  const { error } = await admin.from("purchases").insert(purchaseRow);

  if (error) {
    // Unique violation on stripe_payment_intent_id means this event was
    // already processed (Stripe retries webhooks on any non-2xx response,
    // or on network hiccups) — that's a successful no-op, not a failure.
    if (error.code === "23505") {
      return;
    }
    console.error("Failed to record purchase:", error);
    throw error; // Non-duplicate errors should make Stripe retry.
  }
}
