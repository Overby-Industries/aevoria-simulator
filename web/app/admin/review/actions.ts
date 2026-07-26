"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { stripe } from "@/lib/stripe/server";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";

// TEMPORARY admin gate — checks the caller's own authenticated email
// against a single hardcoded address. This is a placeholder for a real
// roles/permissions system and should not be treated as a durable access
// control model; it's here only so review has *some* gate before the
// marketplace has real moderators.
const ADMIN_EMAIL = "founder@overbyindustries.space";

async function requireAdmin() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user || user.email !== ADMIN_EMAIL) {
    redirect("/");
  }
  return user;
}

export async function approveSkin(formData: FormData) {
  await requireAdmin();
  const skinId = formData.get("skinId") as string;

  // Admin actions use the service-role client deliberately: RLS on `skins`
  // only lets the *creator* update their own listing, and approval is
  // exactly the case where someone other than the creator needs to write
  // to it. The requireAdmin() check above is what keeps this safe, not
  // the database policy.
  const admin = createAdminClient();
  const { data: skin, error } = await admin
    .from("skins")
    .select("*")
    .eq("id", skinId)
    .single();

  if (error || !skin) {
    throw new Error("Skin not found");
  }

  const product = await stripe.products.create({
    name: skin.title,
    description: skin.description ?? undefined,
    metadata: { skin_id: skin.id, creator_id: skin.creator_id },
  });

  const price = await stripe.prices.create({
    product: product.id,
    unit_amount: skin.price_cents,
    currency: "usd",
  });

  await admin
    .from("skins")
    .update({
      status: "approved",
      stripe_product_id: product.id,
      stripe_price_id: price.id,
    })
    .eq("id", skinId);

  revalidatePath("/admin/review");
}

export async function rejectSkin(formData: FormData) {
  await requireAdmin();
  const skinId = formData.get("skinId") as string;

  const admin = createAdminClient();
  await admin.from("skins").update({ status: "rejected" }).eq("id", skinId);

  revalidatePath("/admin/review");
}
