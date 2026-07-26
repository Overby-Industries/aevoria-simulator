"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getClientIp, recordSignupSignalAndFlag } from "@/lib/integrity";

const VALID_FACTIONS = ["commonwealth", "syndicate", "nomads"];

export async function login(formData: FormData) {
  const supabase = await createClient();

  const { error } = await supabase.auth.signInWithPassword({
    email: formData.get("email") as string,
    password: formData.get("password") as string,
  });

  if (error) {
    redirect(`/login?error=${encodeURIComponent(error.message)}`);
  }

  revalidatePath("/", "layout");
  redirect("/account");
}

export async function signup(formData: FormData) {
  const supabase = await createClient();

  const email = formData.get("email") as string;
  const password = formData.get("password") as string;
  const username = formData.get("username") as string;
  const faction = formData.get("faction") as string;

  if (!VALID_FACTIONS.includes(faction)) {
    redirect(`/signup?error=${encodeURIComponent("Please choose a faction.")}`);
  }

  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: { username, faction },
    },
  });

  if (error) {
    redirect(`/signup?error=${encodeURIComponent(error.message)}`);
  }

  // Best-effort — a signal-recording failure should never block signup.
  if (data.user) {
    try {
      const ip = await getClientIp();
      await recordSignupSignalAndFlag(data.user.id, faction, ip);
    } catch (err) {
      console.error("Failed to record signup signal:", err);
    }
  }

  redirect("/signup?check_email=1");
}

export async function logout() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  revalidatePath("/", "layout");
  redirect("/");
}
