import { createClient } from "@/lib/supabase/server";
import { createSkinCheckoutSession } from "./actions";

const IMAGE_EXTENSIONS = [".png", ".jpg", ".jpeg", ".webp"];

export default async function MarketplacePage() {
  const supabase = await createClient();

  const { data: skins } = await supabase
    .from("skins")
    .select("id, title, description, price_cents, storage_path, preview_image_path, creator_id, profiles(username)")
    .eq("status", "approved")
    .order("created_at", { ascending: false });

  const items = await Promise.all(
    (skins ?? []).map(async (skin) => {
      // Procedural skins have no storage_path at all (see 0005_skin_recipes.sql)
      // — their only image is the rendered preview snapshot.
      const isImage =
        !!skin.storage_path &&
        IMAGE_EXTENSIONS.some((ext) => skin.storage_path!.toLowerCase().endsWith(ext));
      const previewPath = isImage ? skin.storage_path! : skin.preview_image_path;

      let previewUrl: string | null = null;
      if (previewPath) {
        const { data } = await supabase.storage
          .from("skins")
          .createSignedUrl(previewPath, 60 * 10); // 10 minutes
        previewUrl = data?.signedUrl ?? null;
      }
      return { ...skin, previewUrl };
    })
  );

  return (
    <main style={styles.main}>
      <h1 style={styles.heading}>Cooperative Exchange</h1>
      <div style={styles.grid}>
        {items.map((skin) => (
          <div key={skin.id} style={styles.card}>
            {skin.previewUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={skin.previewUrl} alt={skin.title} style={styles.image} />
            ) : (
              <div style={styles.filePlaceholder}>3D asset</div>
            )}
            <h2 style={styles.itemName}>{skin.title}</h2>
            <p style={styles.desc}>{skin.description}</p>
            <p style={styles.creator}>
              by {(skin.profiles as unknown as { username: string } | null)?.username ?? "unknown"}
            </p>
            <p style={styles.price}>${(skin.price_cents / 100).toFixed(2)}</p>
            <form action={createSkinCheckoutSession}>
              <input type="hidden" name="skinId" value={skin.id} />
              <button style={styles.button} type="submit">
                Buy
              </button>
            </form>
          </div>
        ))}
        {items.length === 0 && <p style={styles.desc}>No approved listings yet.</p>}
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
  grid: {
    display: "grid",
    gridTemplateColumns: "repeat(auto-fill, minmax(260px, 1fr))",
    gap: "20px",
    maxWidth: "1000px",
    margin: "0 auto",
  },
  card: {
    background: "#14181f",
    border: "1px solid #2a2f3a",
    borderRadius: "12px",
    padding: "20px",
    display: "flex",
    flexDirection: "column",
    gap: "8px",
  },
  image: { width: "100%", aspectRatio: "1", borderRadius: "8px", objectFit: "cover" },
  filePlaceholder: {
    width: "100%",
    aspectRatio: "1",
    borderRadius: "8px",
    background: "#0b0d10",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    color: "#6d7482",
    fontSize: "0.85rem",
  },
  itemName: { margin: 0, fontSize: "1.1rem" },
  desc: { fontSize: "0.85rem", color: "#9aa2b0", margin: 0 },
  creator: { fontSize: "0.8rem", color: "#6d7482", margin: 0 },
  price: { fontSize: "1.2rem", fontWeight: 700, margin: "4px 0" },
  button: {
    padding: "10px 12px",
    borderRadius: "6px",
    border: "none",
    background: "#2e4a73",
    color: "white",
    fontSize: "1rem",
    cursor: "pointer",
    width: "100%",
  },
};
