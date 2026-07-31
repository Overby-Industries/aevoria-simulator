"use server";

import { revalidatePath } from "next/cache";
import { getStripe } from "@/lib/stripe/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { requireAdmin } from "@/lib/admin";

// Shared by both human approval here (admin/review) and system auto-approval
// (creator/create/actions.ts) -- no requireAdmin() call of its own, since
// the caller is responsible for deciding whether this is authorized (a
// human admin click, or the system approving a procedural skin whose
// content-safety is structurally guaranteed by the shader, not reviewed).
// Always runs through the service-role admin client: RLS on `skins` only
// lets the *creator* write their own row, and this is exactly the case
// where something other than the creator needs to.
export async function approveSkinRecord(skinId: string): Promise<void> {
  const admin = createAdminClient();
  const { data: skin, error } = await admin
    .from("skins")
    .select("*")
    .eq("id", skinId)
    .single();

  if (error || !skin) {
    throw new Error("Skin not found");
  }

  // Personal-use (is_public = false) skins never get sold, so there's
  // nothing for Stripe to price -- approve the row without ever creating
  // a product/price for it.
  if (!skin.is_public) {
    await admin.from("skins").update({ status: "approved" }).eq("id", skinId);
    return;
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
}

export async function approveSkin(formData: FormData) {
  await requireAdmin();
  const skinId = formData.get("skinId") as string;
  await approveSkinRecord(skinId);
  revalidatePath("/admin/review");
  revalidatePath("/marketplace");
}

export async function rejectSkin(formData: FormData) {
  await requireAdmin();
  const skinId = formData.get("skinId") as string;

  const admin = createAdminClient();
  await admin.from("skins").update({ status: "rejected" }).eq("id", skinId);

  revalidatePath("/admin/review");
  revalidatePath("/marketplace");
}
