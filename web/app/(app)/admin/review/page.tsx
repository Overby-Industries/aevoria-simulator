import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { approveSkin, rejectSkin } from "./actions";

const ADMIN_EMAIL = "founder@overbyindustries.space";

export default async function AdminReviewPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user || user.email !== ADMIN_EMAIL) {
    redirect("/");
  }

  const { data: pending } = await supabase
    .from("skins")
    .select("id, title, description, price_cents, storage_path, creator_id, created_at")
    .eq("status", "pending_review")
    .order("created_at", { ascending: true });

  return (
    <main style={styles.main}>
      <h1 style={styles.heading}>Pending review</h1>
      <div style={styles.list}>
        {(pending ?? []).map((skin) => (
          <div key={skin.id} style={styles.card}>
            <h2 style={styles.title}>{skin.title}</h2>
            <p style={styles.text}>{skin.description}</p>
            <p style={styles.text}>
              ${(skin.price_cents / 100).toFixed(2)} — {skin.storage_path}
            </p>
            <div style={styles.actions}>
              <form action={approveSkin}>
                <input type="hidden" name="skinId" value={skin.id} />
                <button style={styles.approveButton} type="submit">
                  Approve
                </button>
              </form>
              <form action={rejectSkin}>
                <input type="hidden" name="skinId" value={skin.id} />
                <button style={styles.rejectButton} type="submit">
                  Reject
                </button>
              </form>
            </div>
          </div>
        ))}
        {(!pending || pending.length === 0) && (
          <p style={styles.text}>Nothing waiting on review.</p>
        )}
      </div>
    </main>
  );
}

const styles: Record<string, React.CSSProperties> = {
  main: {
    minHeight: "100vh",
    background: "#0b0d10",
    color: "#e7e6e1",
    fontFamily: "system-ui, sans-serif",
    padding: "48px 24px",
  },
  heading: { textAlign: "center", marginBottom: "32px" },
  list: {
    display: "flex",
    flexDirection: "column",
    gap: "16px",
    maxWidth: "600px",
    margin: "0 auto",
  },
  card: {
    background: "#14181f",
    border: "1px solid #2a2f3a",
    borderRadius: "12px",
    padding: "20px",
  },
  title: { margin: "0 0 8px" },
  text: { fontSize: "0.85rem", color: "#9aa2b0", margin: "0 0 8px" },
  actions: { display: "flex", gap: "8px" },
  approveButton: {
    padding: "8px 16px",
    borderRadius: "6px",
    border: "none",
    background: "#2f7d55",
    color: "white",
    cursor: "pointer",
  },
  rejectButton: {
    padding: "8px 16px",
    borderRadius: "6px",
    border: "none",
    background: "#b23b2e",
    color: "white",
    cursor: "pointer",
  },
};
