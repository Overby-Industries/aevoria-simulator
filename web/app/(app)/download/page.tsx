import Link from "next/link";

export default function DownloadPage() {
  return (
    <main style={styles.main}>
      <div style={styles.card}>
        <span style={styles.badge}>Alpha — In Development</span>
        <h1 style={styles.heading}>Download Aevoria</h1>
        <p style={styles.text}>
          The simulator isn&apos;t packaged for public download yet — the governance and
          compliance backend is still being built and wired into the game engine. There&apos;s
          nothing playable to hand out yet, so we&apos;d rather tell you that plainly than point
          you at a broken link.
        </p>
        <p style={styles.text}>
          When a build is ready, it will be distributed through{" "}
          <span style={styles.itch}>itch.io</span>. This page will turn into a real download
          button the moment that happens — no separate announcement needed, just check back.
        </p>
        <div style={styles.divider} />
        <p style={styles.text}>
          In the meantime, create your account so you&apos;re ready to go the moment the
          Commonwealth opens its gates — pick your faction now and your citizenship is waiting
          for you at launch.
        </p>
        <Link href="/signup" style={styles.ctaButton}>
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
  itch: { color: "#e7e6e1", fontWeight: 600 },
  divider: {
    height: "1px",
    background: "#2a2f3a",
    margin: "24px 0",
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
};
