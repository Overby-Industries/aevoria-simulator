"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { validateSkinRecipe } from "@/lib/skin-recipe";

const MIN_PRICE_CENTS = 50; // $0.50
const MAX_PRICE_CENTS = 50000; // $500.00 — sanity ceiling, not a business rule

export async function createProceduralSkin(formData: FormData) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login?next=/creator/create");
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("is_creator")
    .eq("id", user.id)
    .single();

  if (!profile?.is_creator) {
    redirect("/creator/onboard");
  }

  const title = (formData.get("title") as string)?.trim();
  const description = (formData.get("description") as string)?.trim();
  const priceDollars = Number(formData.get("price"));
  const recipeRaw = formData.get("recipe") as string | null;
  const snapshot = formData.get("snapshot") as string | null;

  if (!title || title.length > 100) {
    redirect("/creator/create?error=" + encodeURIComponent("Title is required (max 100 characters)."));
  }
  if (!Number.isFinite(priceDollars)) {
    redirect("/creator/create?error=" + encodeURIComponent("Enter a valid price."));
  }
  const priceCents = Math.round(priceDollars * 100);
  if (priceCents < MIN_PRICE_CENTS || priceCents > MAX_PRICE_CENTS) {
    redirect(
      "/creator/create?error=" +
        encodeURIComponent(
          `Price must be between $${MIN_PRICE_CENTS / 100} and $${MAX_PRICE_CENTS / 100}.`
        )
    );
  }

  // Never trust the client's own validation — re-parse and re-check the
  // recipe shape server-side regardless of what the customizer UI enforced.
  let recipe: unknown;
  try {
    recipe = JSON.parse(recipeRaw ?? "");
  } catch {
    redirect("/creator/create?error=" + encodeURIComponent("Invalid recipe data."));
  }
  if (!validateSkinRecipe(recipe)) {
    redirect("/creator/create?error=" + encodeURIComponent("Invalid recipe data."));
  }

  if (!snapshot || !snapshot.startsWith("data:image/png;base64,")) {
    redirect("/creator/create?error=" + encodeURIComponent("Missing preview snapshot — please wait for the preview to load before saving."));
  }

  const base64Data = snapshot!.slice("data:image/png;base64,".length);
  const imageBuffer = Buffer.from(base64Data, "base64");

  // Same path convention and bucket as file uploads (creator/upload/actions.ts)
  // — namespaced under the uploader's own user id, matching the storage RLS
  // policy that only allows writes into auth.uid()'s own folder.
  const previewPath = `${user.id}/${crypto.randomUUID()}-preview.png`;

  const { error: uploadError } = await supabase.storage
    .from("skins")
    .upload(previewPath, imageBuffer, { contentType: "image/png" });

  if (uploadError) {
    redirect("/creator/create?error=" + encodeURIComponent(uploadError.message));
  }

  const { error: insertError } = await supabase.from("skins").insert({
    creator_id: user.id,
    title,
    description: description || null,
    price_cents: priceCents,
    preview_image_path: previewPath,
    recipe,
    status: "pending_review",
  });

  if (insertError) {
    redirect("/creator/create?error=" + encodeURIComponent(insertError.message));
  }

  redirect("/creator/create?submitted=1");
}
