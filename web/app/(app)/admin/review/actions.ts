"use server";

import { revalidatePath } from "next/cache";
import { getStripe } from "@/lib/stripe/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { requireAdmin } from "@/lib/admin";

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

  const product = await getStripe().products.create({
    name: skin.title,
    description: skin.description ?? undefined,
    metadata: { skin_id: skin.id, creator_id: skin.creator_id },
  });

  const price = await getStripe().prices.create({
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
