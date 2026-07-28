"use client";

import { useState } from "react";

const FACTIONS = [
  {
    value: "commonwealth",
    name: "Aevoric Commonwealth",
    tagline: "Zero-waste ISRU, CUR direct democracy.",
    color: "#4a7fd6",
  },
  {
    value: "syndicate",
    name: "Oligarch Syndicate",
    tagline: "Garage to empire. Systemic corruption.",
    color: "#d67a4a",
  },
  {
    value: "nomads",
    name: "Nomads",
    tagline: "Unaligned. Mercenary economics.",
    color: "#8a7fd6",
  },
];

export function FactionSelector({ excludeFaction }: { excludeFaction?: string }) {
  const options = FACTIONS.filter((f) => f.value !== excludeFaction);
  const [selected, setSelected] = useState<string>("");

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
      <span style={{ fontSize: "0.9rem" }}>Choose your faction</span>
      <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
        {options.map((f) => {
          const isSelected = selected === f.value;
          return (
            <button
              key={f.value}
              type="button"
              onClick={() => setSelected(f.value)}
              style={{
                textAlign: "left",
                padding: "10px 12px",
                borderRadius: "6px",
                border: `1px solid ${isSelected ? f.color : "#2a2f3a"}`,
                background: isSelected ? `${f.color}22` : "#0b0d10",
                cursor: "pointer",
                color: "#e7e6e1",
              }}
            >
              <div style={{ fontSize: "0.9rem", fontWeight: 600 }}>{f.name}</div>
              <div style={{ fontSize: "0.78rem", color: "#9aa2b0", marginTop: "2px" }}>
                {f.tagline}
              </div>
            </button>
          );
        })}
      </div>
      {/* `required` has no effect on hidden inputs per the HTML spec — the
          signup server action is the actual source of validation truth. */}
      <input type="hidden" name="faction" value={selected} />
    </div>
  );
}
