// A procedural skin's entire "content" — small enough to store as jsonb and
// small enough that Godot's ProceduralArtGenerator (src/procedural_art_generator.cpp)
// and this web app's live preview shader (components/SkinCustomizer.tsx) can
// each render it from scratch and get a visually matching result. Only one
// pattern for now; more are additive later, not a v1 blocker.

export interface SkinRecipe {
  pattern: "cellular";
  seed: number;
  frequency: number;
  darkColor: string; // hex, e.g. "#241f1a"
  baseColor: string;
  highlightColor: string;
}

export const DEFAULT_RECIPE: SkinRecipe = {
  pattern: "cellular",
  seed: 0,
  frequency: 0.08,
  darkColor: "#26201a",
  baseColor: "#bfa68c",
  highlightColor: "#d9c7ad",
};

export const MIN_FREQUENCY = 0.02;
export const MAX_FREQUENCY = 0.3;

// Shared between creator/create/actions.ts (server-side validation) and
// creator/create/page.tsx + SkinVisibilityAndSubmit (the price input's
// min/max) -- actions.ts is a "use server" file, which can only export
// async functions, so these live here instead of there.
export const MIN_PRICE_CENTS = 50; // $0.50
export const MAX_PRICE_CENTS = 50000; // $500.00 — sanity ceiling, not a business rule

const HEX_COLOR_RE = /^#[0-9a-fA-F]{6}$/;

// Used both client-side (before enabling the Save button) and server-side
// (the server action never trusts the client's own validation).
export function validateSkinRecipe(value: unknown): value is SkinRecipe {
  if (typeof value !== "object" || value === null) return false;
  const r = value as Record<string, unknown>;
  return (
    r.pattern === "cellular" &&
    typeof r.seed === "number" &&
    Number.isInteger(r.seed) &&
    typeof r.frequency === "number" &&
    r.frequency >= MIN_FREQUENCY &&
    r.frequency <= MAX_FREQUENCY &&
    typeof r.darkColor === "string" &&
    HEX_COLOR_RE.test(r.darkColor) &&
    typeof r.baseColor === "string" &&
    HEX_COLOR_RE.test(r.baseColor) &&
    typeof r.highlightColor === "string" &&
    HEX_COLOR_RE.test(r.highlightColor)
  );
}
