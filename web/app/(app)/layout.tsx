import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { logout } from "@/app/auth/actions";

export default async function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  return (
    <div style={{ minHeight: "100vh", background: "#0b0d10" }}>
      <header style={styles.header}>
        <Link href="/" style={styles.logo}>
          AEVORIA
        </Link>
        <nav style={styles.nav}>
          <Link href="/download" style={styles.navLink}>
            Download
          </Link>
          <Link href="/store" style={styles.navLink}>
            Store
          </Link>
          <Link href="/marketplace" style={styles.navLink}>
            Marketplace
          </Link>
          {user ? (
            <>
              <Link href="/account" style={styles.navLink}>
                Account
              </Link>
              <form action={logout}>
                <button style={styles.logoutButton} type="submit">
                  Log Out
                </button>
              </form>
            </>
          ) : (
            <>
              <Link href="/login" style={styles.navLink}>
                Log In
              </Link>
              <Link href="/signup" style={styles.navLink}>
                Sign Up
              </Link>
            </>
          )}
        </nav>
      </header>
      {children}
    </div>
  );
}

const styles: Record<string, React.CSSProperties> = {
  header: {
    display: "flex",
    flexWrap: "wrap",
    alignItems: "center",
    justifyContent: "space-between",
    gap: "12px",
    padding: "18px 24px",
    borderBottom: "1px solid rgba(100, 150, 255, 0.15)",
    background: "rgba(11, 13, 16, 0.9)",
  },
  logo: {
    fontSize: "18px",
    fontWeight: 300,
    letterSpacing: "4px",
    color: "#ffffff",
    textDecoration: "none",
    fontFamily: "'Segoe UI', system-ui, sans-serif",
  },
  nav: {
    display: "flex",
    flexWrap: "wrap",
    alignItems: "center",
    gap: "16px",
  },
  navLink: {
    fontSize: "12px",
    letterSpacing: "2px",
    color: "rgba(220, 230, 255, 0.75)",
    fontFamily: "monospace",
    textTransform: "uppercase",
    textDecoration: "none",
  },
  logoutButton: {
    fontSize: "12px",
    letterSpacing: "2px",
    color: "rgba(220, 230, 255, 0.75)",
    fontFamily: "monospace",
    textTransform: "uppercase",
    background: "none",
    border: "none",
    cursor: "pointer",
    padding: 0,
  },
};
