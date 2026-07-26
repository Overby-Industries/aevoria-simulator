"use server";

import { revalidatePath } from "next/cache";
import { createAdminClient } from "@/lib/supabase/admin";
import { requireAdmin } from "@/lib/admin";

export async function resolveFlag(formData: FormData) {
  const adminUser = await requireAdmin();
  const flagId = formData.get("flagId") as string;
  const status = formData.get("status") as string;

  if (status !== "actioned" && status !== "dismissed") {
    throw new Error("Invalid status");
  }

  const admin = createAdminClient();
  await admin
    .from("integrity_flags")
    .update({
      status,
      reviewed_at: new Date().toISOString(),
      reviewed_by: adminUser.id,
    })
    .eq("id", flagId);

  revalidatePath("/admin/flags");
}
