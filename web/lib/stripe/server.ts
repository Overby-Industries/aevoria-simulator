import "server-only";
import Stripe from "stripe";

// Server-only — importing "server-only" makes it a build error to
// accidentally pull this into a Client Component and leak the secret key.
export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: "2026-06-24.dahlia",
  typescript: true,
});
