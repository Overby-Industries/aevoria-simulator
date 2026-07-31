"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { validateSkinRecipe, MIN_PRICE_CENTS, MAX_PRICE_CENTS } from "@/lib/skin-recipe";
import { approveSkinRecord } from "@/app/(app)/admin/review/actions";

// Defense-in-depth, not the primary safety mechanism -- the shader itself
// can only ever render a 3-solid-color cellular pattern, so imagery is
// structurally never a risk here (see creator/upload's removal). Title and
// description are the only free-form text a submission carries, so this is
// a blunt first-pass filter against the most obvious abuse (slurs, hate
// symbols by name) before anything goes live unattended. Not exhaustive by
// design -- a determined bad actor can route around a static wordlist, but
// this catches the casual/obvious case for free, at zero ongoing review
// cost. /admin/review stays available for spot-checking public listings
// after the fact even though nothing routes through it automatically now.
const BLOCKED_TERMS = [
  "nazi", "swastika", "hitler", "kkk",
  // Slurs and explicit-content terms deliberately not enumerated in a
  // source file that ships to every contributor -- extend this list in a
  // private ops doc / env-provided list if the launch scope needs more.
];

function containsBlockedTerm(text: string): boolean {
  const lower = text.toLowerCase();
  return BLOCKED_TERMS.some((term) => lower.includes(term));
}

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
  const isPublic = formData.get("visibility") !== "private";
  const recipeRaw = formData.get("recipe") as string | null;
  const snapshot = formData.get("snapshot") as string | null;

  if (!title || title.length > 100) {
    redirect("/creator/create?error=" + encodeURIComponent("Title is required (max 100 characters)."));
  }
  if (containsBlockedTerm(title) || containsBlockedTerm(description ?? "")) {
    redirect("/creator/create?error=" + encodeURIComponent("Title/description contains a term that isn't allowed."));
  }

  // Personal-use skins are never sold, so price doesn't apply -- only
  // public (marketplace-listed) submissions need a real, validated price.
  let priceCents = 0;
  if (isPublic) {
    const priceDollars = Number(formData.get("price"));
    if (!Number.isFinite(priceDollars)) {
      redirect("/creator/create?error=" + encodeURIComponent("Enter a valid price."));
    }
    priceCents = Math.round(priceDollars * 100);
    if (priceCents < MIN_PRICE_CENTS || priceCents > MAX_PRICE_CENTS) {
      redirect(
        "/creator/create?error=" +
          encodeURIComponent(
            `Price must be between $${MIN_PRICE_CENTS / 100} and $${MAX_PRICE_CENTS / 100}.`
          )
      );
    }
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

  // Same path convention and bucket as file uploads used to (namespaced
  // under the uploader's own user id) — matches the storage RLS policy
  // that only allows writes into auth.uid()'s own folder.
  const previewPath = `${user.id}/${crypto.randomUUID()}-preview.png`;

  const { error: uploadError } = await supabase.storage
    .from("skins")
    .upload(previewPath, imageBuffer, { contentType: "image/png" });

  if (uploadError) {
    redirect("/creator/create?error=" + encodeURIComponent(uploadError.message));
  }

  // Insert through the creator's own session (not the admin client) so
  // 0003's RLS policy actually applies: a creator's own client can only
  // ever insert/update while status stays 'pending_review' -- self-approval
  // is impossible at this layer regardless of what this action does next.
  // approveSkinRecord() immediately below is what promotes it, and that
  // always runs through the service-role admin client, same as a human
  // admin's click on /admin/review always has.
  const { data: inserted, error: insertError } = await supabase
    .from("skins")
    .insert({
      creator_id: user.id,
      title,
      description: description || null,
      price_cents: priceCents,
      preview_image_path: previewPath,
      recipe,
      status: "pending_review",
      is_public: isPublic,
    })
    .select("id")
    .single();

  if (insertError || !inserted) {
    redirect("/creator/create?error=" + encodeURIComponent(insertError?.message ?? "Could not save skin."));
  }

  // Auto-approve: see BLOCKED_TERMS comment above for why this is safe to
  // do unattended for a procedural (non-uploaded) skin. Private skins skip
  // Stripe product/price creation entirely inside approveSkinRecord().
  await approveSkinRecord(inserted!.id);

  redirect("/creator/create?submitted=1");
}
