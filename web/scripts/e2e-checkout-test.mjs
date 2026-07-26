// One-off end-to-end test driver — signs up a throwaway account, buys a
// Tier 1 store item with Stripe's test card, and confirms the redirect
// back to the success page. Not part of the app; safe to delete after use.
import { chromium } from "playwright";
import { createClient } from "@supabase/supabase-js";
import { readFileSync } from "fs";
import WebSocket from "ws";

globalThis.WebSocket = WebSocket;

const env = Object.fromEntries(
  readFileSync(new URL("../.env.local", import.meta.url), "utf8")
    .split("\n")
    .filter((l) => l.includes("=") && !l.trim().startsWith("#"))
    .map((l) => {
      const i = l.indexOf("=");
      return [l.slice(0, i).trim(), l.slice(i + 1).trim()];
    })
);

const BASE = "http://localhost:3000";
const runId = Date.now();
const testEmail = `test-buyer-${runId}@gmail.com`;
const testPassword = "test-password-123";

// Create the test account via the Admin API — pre-confirmed, no email
// sent, sidesteps Supabase's signup email rate limit entirely. Username
// must be unique per run since profiles.username has a unique constraint
// and this script doesn't clean up its test accounts afterward.
const admin = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);
const { error: createErr } = await admin.auth.admin.createUser({
  email: testEmail,
  password: testPassword,
  email_confirm: true,
  user_metadata: { username: `test_buyer_${runId}` },
});
if (createErr) {
  console.error("Failed to create test user via admin API:", JSON.stringify(createErr, Object.getOwnPropertyNames(createErr)));
  process.exit(1);
}
console.log("Pre-confirmed test user created:", testEmail);

const browser = await chromium.launch();
const page = await browser.newPage();
const consoleErrors = [];
page.on("console", (msg) => {
  if (msg.type() === "error") consoleErrors.push(msg.text());
});
page.on("pageerror", (err) => consoleErrors.push(String(err)));

try {
  console.log("2. Logging in with the pre-confirmed test account...");
  await page.goto(`${BASE}/login`);
  await page.fill('input[name="email"]', testEmail);
  await page.fill('input[name="password"]', testPassword);
  await page.click('button[type="submit"]');
  await page.waitForLoadState("networkidle");
  console.log("   URL after login attempt:", page.url());
  await page.screenshot({ path: "scripts/e2e-2-after-login.png" });

  if (!page.url().includes("/account")) {
    console.log("   Login did not reach /account — likely blocked on email confirmation.");
    console.log("   Page content snippet:", (await page.textContent("body"))?.slice(0, 300));
    await browser.close();
    process.exit(2);
  }

  console.log("3. Navigating to /store...");
  await page.goto(`${BASE}/store`);
  await page.waitForLoadState("networkidle");
  await page.screenshot({ path: "scripts/e2e-3-store.png" });
  const productCount = await page.locator('form button:has-text("Buy")').count();
  console.log("   Products with a Buy button found:", productCount);

  console.log("4. Clicking Buy on the first product...");
  await page.locator('form button:has-text("Buy")').first().click();
  await page.waitForURL(/checkout\.stripe\.com/, { timeout: 20000 });
  console.log("   Redirected to:", page.url());
  // Stripe's checkout page keeps long-poll/analytics connections open, so
  // "networkidle" never fires — just wait for the page to settle in.
  await page.waitForTimeout(4000);
  await page.screenshot({ path: "scripts/e2e-4-stripe-checkout.png" });

  const iframeInfo = await page.locator("iframe").evaluateAll((els) =>
    els.map((el) => ({
      title: el.getAttribute("title"),
      name: el.getAttribute("name"),
      hidden: el.getAttribute("aria-hidden"),
    }))
  );
  console.log("   iframes on checkout page:", JSON.stringify(iframeInfo, null, 2));

  console.log("5. Filling contact info and expanding the Card payment method...");
  const emailField = page.locator('input[name="email"], input#email');
  if (await emailField.count()) {
    await emailField.first().fill(testEmail);
  }

  const radioInfo = await page.locator('input[type="radio"]').evaluateAll((els) =>
    els.map((el) => ({ value: el.getAttribute("value"), id: el.id, checked: el.checked }))
  );
  console.log("   radio inputs found:", JSON.stringify(radioInfo));

  // The payment method list is an accordion — click the radio itself
  // rather than the label/button, which can be covered by an overlay.
  const cardRadio = page.locator('input[type="radio"][value="card"]');
  if (await cardRadio.count()) {
    await cardRadio.click({ force: true });
  } else {
    // Fallback: click the row container that wraps the "Card" label.
    await page.locator('#payment-method-label-card').locator("xpath=ancestor::li[1]").click({ force: true });
  }
  await page.waitForTimeout(1000);
  await page.screenshot({ path: "scripts/e2e-4b-card-expanded.png" });

  const iframeInfo2 = await page.locator("iframe").evaluateAll((els) =>
    els.map((el) => ({ title: el.getAttribute("title"), name: el.getAttribute("name") }))
  );
  console.log("   iframes after expanding card:", JSON.stringify(iframeInfo2));

  const mainPageInputs = await page.locator("input").evaluateAll((els) =>
    els.map((el) => ({ name: el.getAttribute("name"), id: el.id, placeholder: el.getAttribute("placeholder") }))
  );
  console.log("   inputs on main page (not in iframes):", JSON.stringify(mainPageInputs));

  console.log("   Filling card fields...");
  const cardNumberInput = page.locator('input[placeholder="1234 1234 1234 1234"], input[name="cardnumber"], #cardNumber');
  await cardNumberInput.first().fill("4242424242424242", { timeout: 15000 });
  const expInput = page.locator('input[placeholder="MM / YY"], input[name="exp-date"], #cardExpiry');
  await expInput.first().fill("1234");
  const cvcInput = page.locator('input[placeholder="CVC"], input[name="cvc"], #cardCvc');
  await cvcInput.first().fill("123");

  const nameField = page.locator('input[name="billingName"]');
  if (await nameField.count()) await nameField.fill("Test Buyer");

  const zipField = page.locator('input[name="billingPostalCode"]');
  if (await zipField.count()) await zipField.fill("94103");

  const phoneField = page.locator('input[type="tel"]');
  if (await phoneField.count()) await phoneField.first().fill("4155551234");

  await page.screenshot({ path: "scripts/e2e-5-card-filled.png" });

  console.log("6. Submitting payment...");
  await page.click('button[type="submit"]');
  await page.waitForURL(/localhost:3000\/store\/success/, { timeout: 30000 });
  console.log("   Final URL:", page.url());
  await page.waitForLoadState("networkidle");
  await page.screenshot({ path: "scripts/e2e-6-success.png" });
  console.log("   Success page text:", (await page.textContent("body"))?.slice(0, 300));

  console.log("\nConsole errors captured during run:", consoleErrors.length ? consoleErrors : "none");
} catch (err) {
  console.error("TEST FAILED:", err);
  await page.screenshot({ path: "scripts/e2e-FAILURE.png" }).catch(() => {});
  console.log("Console errors so far:", consoleErrors);
  process.exitCode = 1;
} finally {
  await browser.close();
}
