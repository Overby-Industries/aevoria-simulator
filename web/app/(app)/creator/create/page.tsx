import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import SkinCustomizerWrapper from "@/components/SkinCustomizerWrapper";
import SkinVisibilityAndSubmit from "@/components/SkinVisibilityAndSubmit";
import { createProceduralSkin } from "./actions";
import { MIN_PRICE_CENTS, MAX_PRICE_CENTS } from "@/lib/skin-recipe";

export default async function CreatorCreatePage({
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
    redirect("/login?next=/creator/create");
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
      <form action={createProceduralSkin} style={styles.card}>
        <h1 style={styles.heading}>Create a procedural skin</h1>
        <p style={styles.text}>
          Design a pattern with the live preview below. Every skin here is generated
          from color/pattern controls, not an uploaded image or file -- that's a
          deliberate content-safety choice, not a missing feature. Public submissions
          go live on the Marketplace right away (no waiting on manual review); private
          ones are just for you.
        </p>
        {params.error && <p style={styles.error}>{params.error}</p>}
        {params.submitted && (
          <p style={styles.success}>
            Saved! Public skins are already live on the Marketplace; private ones are
            ready to use in the simulator now.
          </p>
        )}

        <SkinCustomizerWrapper />

        <label style={styles.label}>
          Title
          <input style={styles.input} name="title" type="text" required maxLength={100} />
        </label>

        <label style={styles.label}>
          Description
          <textarea style={styles.textarea} name="description" rows={3} />
        </label>

        <SkinVisibilityAndSubmit minPrice={MIN_PRICE_CENTS} maxPrice={MAX_PRICE_CENTS} />
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
  link: { color: "#8db0e0" },
  error: { color: "#e2786b", fontSize: "0.85rem", margin: 0 },
  success: { color: "#69c096", fontSize: "0.85rem", margin: 0 },
};
