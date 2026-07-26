"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

const MAX_FILE_BYTES = 25 * 1024 * 1024; // 25 MB
const ALLOWED_EXTENSIONS = [".png", ".jpg", ".jpeg", ".webp", ".glb", ".gltf"];
const MIN_PRICE_CENTS = 50; // $0.50
const MAX_PRICE_CENTS = 50000; // $500.00 — sanity ceiling, not a business rule

function hasAllowedExtension(filename: string) {
  const lower = filename.toLowerCase();
  return ALLOWED_EXTENSIONS.some((ext) => lower.endsWith(ext));
}

export async function uploadSkin(formData: FormData) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login?next=/creator/upload");
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
  const file = formData.get("file") as File | null;

  if (!title || title.length > 100) {
    redirect("/creator/upload?error=" + encodeURIComponent("Title is required (max 100 characters)."));
  }
  if (!Number.isFinite(priceDollars)) {
    redirect("/creator/upload?error=" + encodeURIComponent("Enter a valid price."));
  }
  const priceCents = Math.round(priceDollars * 100);
  if (priceCents < MIN_PRICE_CENTS || priceCents > MAX_PRICE_CENTS) {
    redirect(
      "/creator/upload?error=" +
        encodeURIComponent(
          `Price must be between $${MIN_PRICE_CENTS / 100} and $${MAX_PRICE_CENTS / 100}.`
        )
    );
  }
  if (!file || file.size === 0) {
    redirect("/creator/upload?error=" + encodeURIComponent("Please choose a file."));
  }
  if (file!.size > MAX_FILE_BYTES) {
    redirect("/creator/upload?error=" + encodeURIComponent("File is too large (max 25 MB)."));
  }
  if (!hasAllowedExtension(file!.name)) {
    redirect(
      "/creator/upload?error=" +
        encodeURIComponent("Allowed file types: PNG, JPG, WEBP, GLB, GLTF.")
    );
  }

  // Path is namespaced under the uploader's own user id — this matches the
  // storage RLS policy, which only allows writes into auth.uid()'s own
  // folder. Even a compromised/buggy client couldn't write elsewhere; the
  // database enforces it independently of this code.
  const safeName = file!.name.replace(/[^a-zA-Z0-9.\-_]/g, "_");
  const storagePath = `${user.id}/${crypto.randomUUID()}-${safeName}`;

  const { error: uploadError } = await supabase.storage
    .from("skins")
    .upload(storagePath, file!);

  if (uploadError) {
    redirect("/creator/upload?error=" + encodeURIComponent(uploadError.message));
  }

  const { error: insertError } = await supabase.from("skins").insert({
    creator_id: user.id,
    title,
    description: description || null,
    price_cents: priceCents,
    storage_path: storagePath,
    status: "pending_review",
  });

  if (insertError) {
    redirect("/creator/upload?error=" + encodeURIComponent(insertError.message));
  }

  redirect("/creator/upload?submitted=1");
}
