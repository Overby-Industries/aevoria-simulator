import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { logout } from "@/app/auth/actions";

const FACTION_NAMES: Record<string, string> = {
  commonwealth: "Aevoric Commonwealth",
  syndicate: "Oligarch Syndicate",
  nomads: "Nomads",
};

export default async function AccountPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string; franchise_created?: string }>;
}) {
  const params = await searchParams;
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("username, is_creator, faction, linked_primary_id")
    .eq("id", user.id)
    .single();

  const { data: linkedAlt } = await supabase
    .from("profiles")
    .select("username, faction")
    .eq("linked_primary_id", user.id)
    .maybeSingle();

  const { data: primaryAccount } = profile?.linked_primary_id
    ? await supabase
        .from("profiles")
        .select("username, faction")
        .eq("id", profile.linked_primary_id)
        .single()
    : { data: null };

  return (
    <main style={styles.main}>
      <div style={styles.card}>
        <h1 style={styles.heading}>Welcome, {profile?.username ?? user.email}</h1>
        <p style={styles.text}>Signed in as {user.email}</p>

        {params.error && <p style={styles.error}>{params.error}</p>}
        {params.franchise_created && (
          <p style={styles.success}>
            Independent Franchise account created — log in with its own
            credentials to play as it.
          </p>
        )}

        <p style={styles.text}>
          Creator status:{" "}
          {profile?.is_creator ? "Creator (Stripe Connect linked)" : "Not yet a creator"}
        </p>

        {profile?.faction ? (
          <p style={styles.text}>
            Faction: <strong style={{ color: "#e7e6e1" }}>{FACTION_NAMES[profile.faction]}</strong>
          </p>
        ) : (
          <p style={styles.text}>
            No faction chosen yet — <a href="/account/choose-faction">choose one</a>.
          </p>
        )}

        {primaryAccount && (
          <p style={styles.text}>
            Independent Franchise of <strong style={{ color: "#e7e6e1" }}>{primaryAccount.username}</strong>{" "}
            ({FACTION_NAMES[primaryAccount.faction as string]})
          </p>
        )}

        {linkedAlt && (
          <p style={styles.text}>
            Your Independent Franchise: <strong style={{ color: "#e7e6e1" }}>{linkedAlt.username}</strong>{" "}
            ({FACTION_NAMES[linkedAlt.faction as string]})
          </p>
        )}

        {profile?.faction && !profile.linked_primary_id && !linkedAlt && (
          <a href="/account/link-franchise" style={styles.link}>
            Register an Independent Franchise account
          </a>
        )}

        {!profile?.is_creator && (
          <a href="/creator/onboard" style={styles.link}>
            Become a Creator
          </a>
        )}

        <form action={logout}>
          <button style={styles.button} type="submit">
            Log out
          </button>
        </form>
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
  link: { fontSize: "0.85rem", color: "#8db0e0", marginTop: "4px" },
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
  success: { color: "#69c096", fontSize: "0.85rem", margin: 0 },
};
