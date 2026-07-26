import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { FactionSelector } from "@/components/FactionSelector";
import { createFranchiseAccount } from "./actions";

export default async function LinkFranchisePage({
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
    redirect("/login?next=/account/link-franchise");
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("faction, linked_primary_id")
    .eq("id", user.id)
    .single();

  if (!profile?.faction) {
    redirect("/account?error=" + encodeURIComponent("Choose your own faction first."));
  }
  if (profile.linked_primary_id) {
    redirect(
      "/account?error=" +
        encodeURIComponent("An Independent Franchise account can't itself create another.")
    );
  }

  const { data: existingAlt } = await supabase
    .from("profiles")
    .select("id")
    .eq("linked_primary_id", user.id)
    .maybeSingle();

  if (existingAlt) {
    redirect(
      "/account?error=" + encodeURIComponent("You already have an Independent Franchise account.")
    );
  }

  return (
    <main style={styles.main}>
      <form action={createFranchiseAccount} style={styles.card}>
        <h1 style={styles.heading}>Register an Independent Franchise</h1>
        <p style={styles.text}>
          Your Primary account is aligned with{" "}
          <strong style={{ color: "#e7e6e1" }}>{profile.faction}</strong>. Per the
          Dual-Entity Protocol, your Franchise must choose one of the two
          remaining factions.
        </p>
        {params.error && <p style={styles.error}>{params.error}</p>}

        <label style={styles.label}>
          Username
          <input style={styles.input} name="username" type="text" required />
        </label>

        <label style={styles.label}>
          Email
          <input style={styles.input} name="email" type="email" required />
        </label>

        <label style={styles.label}>
          Password
          <input
            style={styles.input}
            name="password"
            type="password"
            minLength={6}
            required
          />
        </label>

        <FactionSelector excludeFaction={profile.faction} />

        <button style={styles.button} type="submit">
          Create Franchise account
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
  label: { display: "flex", flexDirection: "column", gap: "4px", fontSize: "0.9rem" },
  input: {
    padding: "10px 12px",
    borderRadius: "6px",
    border: "1px solid #2a2f3a",
    background: "#0b0d10",
    color: "#e7e6e1",
    fontSize: "1rem",
  },
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
  text: { fontSize: "0.85rem", color: "#9aa2b0", margin: 0 },
  error: { color: "#e2786b", fontSize: "0.85rem", margin: 0 },
};
