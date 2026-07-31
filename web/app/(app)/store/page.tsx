import type Stripe from "stripe";
import { getStripe } from "@/lib/stripe/server";
import { createCheckoutSession } from "./actions";

// Without this, Next.js has no reason to treat this page as dynamic (no
// cookies/auth touched here) and will prerender it once at build time —
// freezing the product list until the next deploy, even if prices or
// availability change in Stripe.
export const dynamic = "force-dynamic";

export default async function StorePage() {
  const prices = await getStripe().prices.list({
    active: true,
    expand: ["data.product"],
    limit: 50,
  });

  const items = prices.data
    .filter((price) => {
      const product = price.product;
      // Only ever list first-party store products here — the same
      // allow-list marker createCheckoutSession enforces, so nothing
      // shown here can ever be a Tier 2 creator listing.
      return (
        typeof product !== "string" &&
        !product.deleted &&
        product.active &&
        product.metadata?.tier === "store"
      );
    })
    .map((price) => {
      const product = price.product as Stripe.Product;
      return {
        priceId: price.id,
        name: product.name,
        description: product.description,
        image: product.images?.[0],
        amount: price.unit_amount,
        currency: price.currency,
      };
    });

  return (
    <main style={styles.main}>
      <h1 style={styles.heading}>Heritage Fleet Store</h1>
      <div style={styles.grid}>
        {items.map((item) => (
          <div key={item.priceId} style={styles.card}>
            {item.image && (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={item.image} alt={item.name} style={styles.image} />
            )}
            <h2 style={styles.itemName}>{item.name}</h2>
            {item.description && <p style={styles.desc}>{item.description}</p>}
            <p style={styles.price}>
              {item.amount != null
                ? `$${(item.amount / 100).toFixed(2)} ${item.currency.toUpperCase()}`
                : "—"}
            </p>
            <form action={createCheckoutSession}>
              <input type="hidden" name="priceId" value={item.priceId} />
              <button style={styles.button} type="submit">
                Buy
              </button>
            </form>
          </div>
        ))}
        {items.length === 0 && (
          <p style={styles.desc}>No items available yet.</p>
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
  grid: {
    display: "grid",
    gridTemplateColumns: "repeat(auto-fill, minmax(260px, 1fr))",
    gap: "20px",
    maxWidth: "1000px",
    margin: "0 auto",
  },
  card: {
    // CSS grid items stretch to the tallest item in their row by default,
    // but that only sets the *card's* height -- without height: "100%"
    // here the card's own content still only takes up as much room as it
    // needs, so a short-description card's Buy button sat higher than a
    // long-description card's. height: 100% + flex column + the button's
    // marginTop: "auto" below is what actually pins Buy to the bottom of
    // every card regardless of description length.
    height: "100%",
    background: "#14181f",
    border: "1px solid #2a2f3a",
    borderRadius: "12px",
    padding: "20px",
    display: "flex",
    flexDirection: "column",
    gap: "8px",
  },
  image: { width: "100%", borderRadius: "8px", objectFit: "cover" },
  itemName: { margin: 0, fontSize: "1.1rem" },
  desc: { fontSize: "0.85rem", color: "#9aa2b0", margin: 0 },
  // marginTop: "auto" here (not on the form below) pushes the price AND
  // everything after it -- the Buy button -- down together as one block,
  // so price+button land flush at the bottom of every card at the same
  // height regardless of how tall the description above them is. Putting
  // the auto margin on the form instead would leave the price sitting
  // wherever the description happened to end, still misaligned across
  // cards of different description length.
  price: { fontSize: "1.2rem", fontWeight: 700, margin: "4px 0", marginTop: "auto" },
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
