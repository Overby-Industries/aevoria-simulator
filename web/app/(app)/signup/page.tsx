import { signup } from "@/app/auth/actions";
import { FactionSelector } from "@/components/FactionSelector";

export default async function SignupPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string; check_email?: string }>;
}) {
  const params = await searchParams;

  if (params.check_email) {
    return (
      <main style={styles.main}>
        <div style={styles.card}>
          <h1 style={styles.heading}>Check your email</h1>
          <p style={styles.text}>
            We sent you a confirmation link. Click it to activate your
            Aevoric Commonwealth account.
          </p>
        </div>
      </main>
    );
  }

  return (
    <main style={styles.main}>
      <form action={signup} style={styles.card}>
        <h1 style={styles.heading}>Create an account</h1>
        {params.error && <p style={styles.error}>{params.error}</p>}

        <label style={styles.label}>
          Username
          <input style={styles.input} name="username" type="text" required />
        </label>

        <label style={styles.label}>
          Email
          <input style={styles.input} name="email" type="email" required />
        </label>

        <label style={styles.label}>
          Password
          <input
            style={styles.input}
            name="password"
            type="password"
            minLength={6}
            required
          />
        </label>

        <FactionSelector />

        <button style={styles.button} type="submit">
          Sign up
        </button>

        <p style={styles.text}>
          Already have an account? <a href="/login">Log in</a>
        </p>
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
  text: { fontSize: "0.85rem", color: "#9aa2b0" },
  error: { color: "#e2786b", fontSize: "0.85rem", margin: 0 },
};
