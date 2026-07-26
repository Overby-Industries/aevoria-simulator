import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { uploadSkin } from "./actions";

export default async function CreatorUploadPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string; submitted?: string }>;
}) {
  const params = await searchParams;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login?next=/creator/upload");
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("is_creator")
    .eq("id", user.id)
    .single();

  if (!profile?.is_creator) {
    redirect("/creator/onboard");
  }

  return (
    <main style={styles.main}>
      <form
        action={uploadSkin}
        encType="multipart/form-data"
        style={styles.card}
      >
        <h1 style={styles.heading}>Upload a skin</h1>
        <p style={styles.text}>
          Submitted skins go to review before appearing in the marketplace.
        </p>
        {params.error && <p style={styles.error}>{params.error}</p>}
        {params.submitted && (
          <p style={styles.success}>
            Submitted! We'll review it and let you know once it's approved.
          </p>
        )}

        <label style={styles.label}>
          Title
          <input style={styles.input} name="title" type="text" required maxLength={100} />
        </label>

        <label style={styles.label}>
          Description
          <textarea style={styles.textarea} name="description" rows={3} />
        </label>

        <label style={styles.label}>
          Price (USD)
          <input
            style={styles.input}
            name="price"
            type="number"
            step="0.01"
            min="0.50"
            max="500"
            required
          />
        </label>

        <label style={styles.label}>
          File (PNG, JPG, WEBP, GLB, GLTF — max 25 MB)
          <input
            style={styles.input}
            name="file"
            type="file"
            accept=".png,.jpg,.jpeg,.webp,.glb,.gltf"
            required
          />
        </label>

        <button style={styles.button} type="submit">
          Submit for review
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
  textarea: {
    padding: "10px 12px",
    borderRadius: "6px",
    border: "1px solid #2a2f3a",
    background: "#0b0d10",
    color: "#e7e6e1",
    fontSize: "1rem",
    resize: "vertical",
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
  success: { color: "#69c096", fontSize: "0.85rem", margin: 0 },
};
