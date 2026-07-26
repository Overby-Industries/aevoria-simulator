import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { startCreatorOnboarding } from "@/app/creator/actions";

export default async function CreatorOnboardPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login?next=/creator/onboard");
  }

  return (
    <main style={styles.main}>
      <form action={startCreatorOnboarding} style={styles.card}>
        <h1 style={styles.heading}>Become a Creator</h1>
        <p style={styles.text}>
          Join the Modder's Cooperative. You'll be redirected to Stripe to
          set up payouts — creators keep 85% of every sale.
        </p>
        <button style={styles.button} type="submit">
          Start onboarding with Stripe
        </button>
      </form>
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
  button: {
    marginTop: "8px",
    padding: "10px 12px",
    borderRadius: "6px",
    border: "none",
    background: "#2e4a73",
    color: "white",
    fontSize: "1rem",
    cursor: "pointer",
  },
};
