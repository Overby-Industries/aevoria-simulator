import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { logout } from "@/app/auth/actions";

export default async function AccountPage() {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("username, is_creator, stripe_connect_account_id")
    .eq("id", user.id)
    .single();

  return (
    <main style={styles.main}>
      <div style={styles.card}>
        <h1 style={styles.heading}>Welcome, {profile?.username ?? user.email}</h1>
        <p style={styles.text}>Signed in as {user.email}</p>
        <p style={styles.text}>
          Creator status:{" "}
          {profile?.is_creator
            ? "Creator (Stripe Connect linked)"
            : "Not yet a creator"}
        </p>
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
