import "server-only";
import Stripe from "stripe";

// Server-only — importing "server-only" makes it a build error to
// accidentally pull this into a Client Component and leak the secret key.
//
// Lazily constructed on first use rather than at module load. Next.js
// evaluates route modules during the build's "Collecting page data" step,
// which can run before/without the runtime env vars being available —
// constructing the client eagerly at the top level turns a missing
// STRIPE_SECRET_KEY into a build failure for the whole app instead of a
// runtime error scoped to whichever request actually needed it.
let _stripe: Stripe | undefined;

export function getStripe(): Stripe {
  if (!_stripe) {
    _stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
      apiVersion: "2026-06-24.dahlia",
      typescript: true,
    });
  }
  return _stripe;
}
