import { redirect } from "next/navigation";
import { getStripe } from "@/lib/stripe/server";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";

export default async function CreatorOnboardCompletePage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("stripe_connect_account_id")
    .eq("id", user.id)
    .single();

  let chargesEnabled = false;

  if (profile?.stripe_connect_account_id) {
    // Stripe is the source of truth for onboarding status — we re-check
    // directly rather than trusting that landing on this page means
    // onboarding actually finished (a user can navigate here manually).
    const account = await getStripe().accounts.retrieve(
      profile.stripe_connect_account_id
    );
    chargesEnabled = account.charges_enabled;

    if (chargesEnabled) {
      // Must use the service-role client — a DB trigger blocks writes to
      // is_creator from any regular user session, so this status can only
      // ever be granted through this Stripe-verified path.
      const admin = createAdminClient();
      await admin
        .from("profiles")
        .update({ is_creator: true })
        .eq("id", user.id);
    }
  }

  return (
    <main style={styles.main}>
      <div style={styles.card}>
        {chargesEnabled ? (
          <>
            <h1 style={styles.heading}>You're a creator now</h1>
            <p style={styles.text}>
              Stripe onboarding is complete. You can now upload skins to the
              Cooperative Exchange.
            </p>
            <a href="/creator/upload" style={styles.link}>
              Upload your first skin
            </a>
          </>
        ) : (
          <>
            <h1 style={styles.heading}>Onboarding isn't finished yet</h1>
            <p style={styles.text}>
              Stripe still needs a few more details before payouts can be
              enabled.
            </p>
            <a href="/creator/onboard" style={styles.link}>
              Resume onboarding
            </a>
          </>
        )}
      </div>
    </main>
  );
}

const styles: Record<string, React.CSSProperties> = {
  main: {
    minHeight: "100vh",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    background: "#0b0d10",
    color: "#e7e6e1",
    fontFamily: "system-ui, sans-serif",
    padding: "24px",
  },
  card: {
    width: "100%",
    maxWidth: "420px",
    textAlign: "center",
    display: "flex",
    flexDirection: "column",
    gap: "12px",
    background: "#14181f",
    padding: "32px",
    borderRadius: "12px",
    border: "1px solid #2a2f3a",
  },
  heading: { margin: 0, fontSize: "1.4rem" },
  text: { fontSize: "0.9rem", color: "#9aa2b0", margin: 0 },
  link: { color: "#8db0e0", marginTop: "8px" },
};
