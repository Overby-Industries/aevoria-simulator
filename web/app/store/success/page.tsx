import { stripe } from "@/lib/stripe/server";

// This page ONLY displays a friendly confirmation — it never grants a
// purchase itself. A visit here is an unauthenticated GET request that
// anyone could trigger manually with a guessed/old session_id, so the only
// thing this page is allowed to do is *show* status. The webhook (with a
// verified Stripe signature) is the sole source of truth for actually
// recording a purchase.
export default async function StoreSuccessPage({
  searchParams,
}: {
  searchParams: Promise<{ session_id?: string }>;
}) {
  const { session_id } = await searchParams;

  let status: "paid" | "pending" | "unknown" = "unknown";

  if (session_id) {
    try {
      const session = await stripe.checkout.sessions.retrieve(session_id);
      status = session.payment_status === "paid" ? "paid" : "pending";
    } catch {
      status = "unknown";
    }
  }

  return (
    <main style={styles.main}>
      <div style={styles.card}>
        {status === "paid" && (
          <>
            <h1 style={styles.heading}>Thank you!</h1>
            <p style={styles.text}>
              Your purchase is confirmed. It'll be linked to your account
              shortly.
            </p>
          </>
        )}
        {status === "pending" && (
          <>
            <h1 style={styles.heading}>Almost there</h1>
            <p style={styles.text}>
              We're still confirming your payment — check back in a moment.
            </p>
          </>
        )}
        {status === "unknown" && (
          <>
            <h1 style={styles.heading}>We couldn't confirm that</h1>
            <p style={styles.text}>
              If you completed checkout, your purchase will still be
              recorded — this page just couldn't verify it directly.
            </p>
          </>
        )}
        <a href="/store" style={styles.link}>
          Back to store
        </a>
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
    textAlign: "center",
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
  link: { color: "#8db0e0", marginTop: "8px" },
};
