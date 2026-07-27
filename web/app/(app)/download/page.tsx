import Link from "next/link";

const ITCH_URL = "https://aevoria-simulator.itch.io/aevoria-simulator-per-avia-ad-astra";

export default function DownloadPage() {
  return (
    <main style={styles.main}>
      <div style={styles.card}>
        <span style={styles.badge}>Alpha — Available on itch.io</span>
        <h1 style={styles.heading}>Download Aevoria</h1>
        <p style={styles.text}>
          The simulator is early — the governance and compliance backend is still being built
          out — but there&apos;s a real build you can run. Grab it on itch.io.
        </p>
        <a href={ITCH_URL} target="_blank" rel="noopener noreferrer" style={styles.ctaButton}>
          Download on itch.io
        </a>
        <p style={styles.warningNote}>
          Windows will likely show a &quot;Windows protected your PC&quot; SmartScreen warning —
          that&apos;s normal for a small, unsigned indie build like this one, not a sign of a
          problem. Click <strong>More info</strong>, then <strong>Run anyway</strong>.
        </p>
        <div style={styles.divider} />
        <p style={styles.text}>
          Playing under your Commonwealth citizenship — creator marketplace purchases, faction
          alignment — needs an account here first.
        </p>
        <Link href="/signup" style={styles.secondaryLink}>
          Create your account
        </Link>
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
    display: "flex",
    justifyContent: "center",
  },
  card: {
    background: "#14181f",
    border: "1px solid #2a2f3a",
    borderRadius: "12px",
    padding: "40px",
    maxWidth: "560px",
    width: "100%",
    textAlign: "center",
  },
  badge: {
    display: "inline-block",
    fontSize: "0.7rem",
    letterSpacing: "2px",
    textTransform: "uppercase",
    fontFamily: "monospace",
    color: "#e0ac3f",
    border: "1px solid rgba(224, 172, 63, 0.4)",
    borderRadius: "999px",
    padding: "4px 14px",
    marginBottom: "20px",
  },
  heading: { margin: "0 0 20px" },
  text: {
    fontSize: "0.95rem",
    lineHeight: 1.6,
    color: "#9aa2b0",
    margin: "0 0 16px",
    textAlign: "left",
  },
  divider: {
    height: "1px",
    background: "#2a2f3a",
    margin: "24px 0",
  },
  warningNote: {
    fontSize: "0.8rem",
    lineHeight: 1.5,
    color: "#8a8f9c",
    margin: "14px 0 0",
    textAlign: "left",
  },
  ctaButton: {
    display: "inline-block",
    marginTop: "8px",
    padding: "12px 28px",
    borderRadius: "6px",
    background: "#2e4a73",
    color: "white",
    fontWeight: 600,
    textDecoration: "none",
  },
  secondaryLink: {
    display: "inline-block",
    marginTop: "4px",
    color: "#8db0e0",
    fontSize: "0.9rem",
    textDecoration: "none",
  },
};
