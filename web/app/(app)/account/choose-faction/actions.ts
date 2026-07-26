"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

const VALID_FACTIONS = ["commonwealth", "syndicate", "nomads"];

export async function chooseFaction(formData: FormData) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login?next=/account/choose-faction");
  }

  const faction = formData.get("faction") as string;
  if (!VALID_FACTIONS.includes(faction)) {
    redirect("/account/choose-faction?error=" + encodeURIComponent("Choose a faction."));
  }

  // Uses the regular per-user client deliberately — the DB trigger allows
  // setting faction exactly once (from NULL) this way, but rejects any
  // attempt to change it afterward, even from this same code path.
  const { error } = await supabase.from("profiles").update({ faction }).eq("id", user.id);

  if (error) {
    redirect("/account/choose-faction?error=" + encodeURIComponent(error.message));
  }

  redirect("/account");
}
