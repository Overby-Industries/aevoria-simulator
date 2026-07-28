import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { FactionSelector } from "@/components/FactionSelector";
import { chooseFaction } from "./actions";

export default async function ChooseFactionPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>;
}) {
  const params = await searchParams;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login?next=/account/choose-faction");
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("faction")
    .eq("id", user.id)
    .single();

  if (profile?.faction) {
    redirect("/account");
  }

  return (
    <main style={styles.main}>
      <form action={chooseFaction} style={styles.card}>
        <h1 style={styles.heading}>Choose your faction</h1>
        <p style={styles.text}>
          This is permanent for this account — it can't be changed
          afterward.
        </p>
        {params.error && <p style={styles.error}>{params.error}</p>}

        <FactionSelector />

        <button style={styles.button} type="submit">
          Confirm
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
  text: { fontSize: "0.85rem", color: "#9aa2b0", margin: 0 },
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
  error: { color: "#e2786b", fontSize: "0.85rem", margin: 0 },
};
