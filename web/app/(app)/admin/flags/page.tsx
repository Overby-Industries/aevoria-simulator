import { requireAdmin } from "@/lib/admin";
import { createAdminClient } from "@/lib/supabase/admin";
import { resolveFlag } from "./actions";

const FACTION_NAMES: Record<string, string> = {
  commonwealth: "Aevoric Commonwealth",
  syndicate: "Oligarch Syndicate",
  nomads: "Nomads",
};

export default async function AdminFlagsPage() {
  await requireAdmin();
  const admin = createAdminClient();

  const { data: flags } = await admin
    .from("integrity_flags")
    .select("id, flag_type, details, status, created_at, flagged_profile_id, related_profile_id")
    .eq("status", "open")
    .order("created_at", { ascending: true });

  const profileIds = [
    ...new Set(
      (flags ?? []).flatMap((f) => [f.flagged_profile_id, f.related_profile_id].filter(Boolean))
    ),
  ] as string[];

  const { data: profiles } = profileIds.length
    ? await admin.from("profiles").select("id, username, faction").in("id", profileIds)
    : { data: [] };

  const profileById = new Map((profiles ?? []).map((p) => [p.id, p]));

  return (
    <main style={styles.main}>
      <div style={styles.headerRow}>
        <h1 style={styles.heading}>Integrity flags</h1>
        <a href="/admin/review" style={styles.navLink}>
          Skin review →
        </a>
      </div>
      <div style={styles.list}>
        {(flags ?? []).map((flag) => {
          const flagged = profileById.get(flag.flagged_profile_id);
          const related = flag.related_profile_id ? profileById.get(flag.related_profile_id) : null;
          return (
            <div key={flag.id} style={styles.card}>
              <p style={styles.type}>{flag.flag_type}</p>
              <p style={styles.text}>
                <strong style={{ color: "#e7e6e1" }}>{flagged?.username ?? flag.flagged_profile_id}</strong>{" "}
                ({flagged?.faction ? FACTION_NAMES[flagged.faction] : "no faction"})
              </p>
              {related && (
                <p style={styles.text}>
                  Matches:{" "}
                  <strong style={{ color: "#e7e6e1" }}>{related.username}</strong> (
                  {related.faction ? FACTION_NAMES[related.faction] : "no faction"})
                </p>
              )}
              {flag.details && (
                <p style={styles.detail}>{JSON.stringify(flag.details)}</p>
              )}
              <p style={styles.detail}>{new Date(flag.created_at).toLocaleString()}</p>
              <div style={styles.actions}>
                <form action={resolveFlag}>
                  <input type="hidden" name="flagId" value={flag.id} />
                  <input type="hidden" name="status" value="actioned" />
                  <button style={styles.actionButton} type="submit">
                    Mark actioned
                  </button>
                </form>
                <form action={resolveFlag}>
                  <input type="hidden" name="flagId" value={flag.id} />
                  <input type="hidden" name="status" value="dismissed" />
                  <button style={styles.dismissButton} type="submit">
                    Dismiss
                  </button>
                </form>
              </div>
            </div>
          );
        })}
        {(!flags || flags.length === 0) && <p style={styles.text}>No open flags.</p>}
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
  headerRow: {
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
    gap: "20px",
    marginBottom: "32px",
    maxWidth: "600px",
    margin: "0 auto 32px",
  },
  heading: { margin: 0 },
  navLink: { fontSize: "0.85rem", color: "#8db0e0" },
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
  type: {
    fontSize: "0.75rem",
    letterSpacing: "1px",
    textTransform: "uppercase",
    color: "#e0ac3f",
    margin: "0 0 8px",
    fontFamily: "monospace",
  },
  text: { fontSize: "0.9rem", color: "#9aa2b0", margin: "0 0 4px" },
  detail: { fontSize: "0.75rem", color: "#6d7482", margin: "4px 0", fontFamily: "monospace" },
  actions: { display: "flex", gap: "8px", marginTop: "12px" },
  actionButton: {
    padding: "8px 16px",
    borderRadius: "6px",
    border: "none",
    background: "#b3811f",
    color: "white",
    cursor: "pointer",
  },
  dismissButton: {
    padding: "8px 16px",
    borderRadius: "6px",
    border: "none",
    background: "#2a2f3a",
    color: "white",
    cursor: "pointer",
  },
};
