import { createAdminClient } from "@/lib/supabase/admin";
import { requireAdmin } from "@/lib/admin";
import { approveSkin, rejectSkin } from "./actions";

const IMAGE_EXTENSIONS = [".png", ".jpg", ".jpeg", ".webp"];

export default async function AdminReviewPage() {
  await requireAdmin();
  // RLS on `skins` only lets a row be read by its own creator or once
  // approved (see 0001_init.sql), and the matching storage.objects read
  // policy has the same shape -- neither has a carve-out for an admin
  // reading someone else's still-pending row/file. Use the service-role
  // client for both the query and the signed URLs, same as
  // approveSkin/rejectSkin already do; requireAdmin() above is what keeps
  // this safe, not the DB policy.
  const admin = createAdminClient();

  const { data: pending } = await admin
    .from("skins")
    .select("id, title, description, price_cents, storage_path, preview_image_path, recipe, creator_id, created_at")
    .eq("status", "pending_review")
    .order("created_at", { ascending: true });

  const items = await Promise.all(
    (pending ?? []).map(async (skin) => {
      // Procedural skins (recipe set) always have a rendered PNG preview;
      // uploaded files only get a preview image if the file itself is one.
      const isImage =
        !!skin.recipe ||
        (!!skin.storage_path && IMAGE_EXTENSIONS.some((ext) => skin.storage_path!.toLowerCase().endsWith(ext)));
      const previewPath = skin.preview_image_path ?? skin.storage_path;

      let previewUrl: string | null = null;
      if (isImage && previewPath) {
        const { data } = await admin.storage.from("skins").createSignedUrl(previewPath, 60 * 10);
        previewUrl = data?.signedUrl ?? null;
      }
      return { ...skin, previewUrl };
    })
  );

  return (
    <main style={styles.main}>
      <div style={{ display: "flex", justifyContent: "center", alignItems: "center", gap: "20px", maxWidth: "600px", margin: "0 auto 32px" }}>
        <h1 style={{ ...styles.heading, marginBottom: 0 }}>Pending review</h1>
        <a href="/admin/flags" style={{ fontSize: "0.85rem", color: "#8db0e0" }}>
          Integrity flags →
        </a>
      </div>
      <div style={styles.list}>
        {items.map((skin) => (
          <div key={skin.id} style={styles.card}>
            {skin.previewUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={skin.previewUrl} alt={skin.title} style={styles.previewImage} />
            ) : (
              <p style={styles.text}>(3D asset — {skin.storage_path})</p>
            )}
            <h2 style={styles.title}>{skin.title}</h2>
            <p style={styles.text}>{skin.description}</p>
            <p style={styles.text}>
              ${(skin.price_cents / 100).toFixed(2)} {skin.recipe ? "— procedural" : ""}
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
        {items.length === 0 && (
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
  previewImage: { width: "100%", maxWidth: "160px", aspectRatio: "1", objectFit: "cover", borderRadius: "8px", marginBottom: "8px" },
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
