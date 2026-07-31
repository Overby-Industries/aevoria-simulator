import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { logout } from "@/app/auth/actions";
import { isAdmin } from "@/lib/admin";

export default async function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  // Creator/Admin links only ever render for the exact user they apply to
  // -- is_creator is read fresh per request (not cached client state), and
  // isAdmin() is the same allowlist requireAdmin() enforces server-side on
  // /admin/review itself, so a link never appears for someone who'd just
  // get redirected away anyway.
  let showCreatorLink = false;
  if (user) {
    const { data: profile } = await supabase
      .from("profiles")
      .select("is_creator")
      .eq("id", user.id)
      .single();
    showCreatorLink = !!profile?.is_creator;
  }
  const showAdminLink = await isAdmin(user?.email);

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
              {showCreatorLink && (
                <Link href="/creator/create" style={styles.navLink}>
                  Creator
                </Link>
              )}
              {showAdminLink && (
                <Link href="/admin/review" style={styles.navLink}>
                  Admin
                </Link>
              )}
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
