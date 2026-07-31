'use client';

import { useState } from 'react';

// Splits into its own client component because the confirm() dialog for
// "keep private" and the price field's visibility both need real
// interactivity that creator/create/page.tsx (a server component, gating
// the whole page on an auth/is_creator check) can't provide on its own.
export default function SkinVisibilityAndSubmit({
  minPrice,
  maxPrice,
}: {
  minPrice: number;
  maxPrice: number;
}) {
  const [visibility, setVisibility] = useState<'public' | 'private'>('public');

  return (
    <>
      <fieldset style={styles.fieldset}>
        <legend style={styles.legend}>Where should this go?</legend>
        <label style={styles.radioLabel}>
          <input
            type="radio"
            name="visibility"
            value="public"
            checked={visibility === 'public'}
            onChange={() => setVisibility('public')}
          />
          Submit to the Marketplace -- other players can buy it
        </label>
        <label style={styles.radioLabel}>
          <input
            type="radio"
            name="visibility"
            value="private"
            checked={visibility === 'private'}
            onChange={() => setVisibility('private')}
          />
          Keep for myself only -- sends straight to your sim account, never
          listed or reviewed
        </label>
      </fieldset>

      {visibility === 'public' && (
        <label style={styles.label}>
          Price (USD)
          <input
            style={styles.input}
            name="price"
            type="number"
            step="0.01"
            min={minPrice / 100}
            max={maxPrice / 100}
            required
          />
        </label>
      )}

      <button
        style={styles.button}
        type="submit"
        onClick={(e) => {
          if (
            visibility === 'private' &&
            !confirm(
              "Keep this skin for yourself only? It won't be listed on the Marketplace or reviewed -- you can still use it on any ship in the simulator."
            )
          ) {
            e.preventDefault();
          }
        }}
      >
        {visibility === 'private' ? 'Save for my own use' : 'Submit for review'}
      </button>
    </>
  );
}

const styles: Record<string, React.CSSProperties> = {
  fieldset: {
    border: '1px solid #2a2f3a',
    borderRadius: '6px',
    padding: '10px 12px',
    display: 'flex',
    flexDirection: 'column',
    gap: '8px',
  },
  legend: { fontSize: '0.85rem', padding: '0 4px', color: '#9aa2b0' },
  radioLabel: { display: 'flex', alignItems: 'center', gap: '8px', fontSize: '0.85rem' },
  label: { display: 'flex', flexDirection: 'column', gap: '4px', fontSize: '0.9rem' },
  input: {
    padding: '10px 12px',
    borderRadius: '6px',
    border: '1px solid #2a2f3a',
    background: '#0b0d10',
    color: '#e7e6e1',
    fontSize: '1rem',
  },
  button: {
    marginTop: '8px',
    padding: '10px 12px',
    borderRadius: '6px',
    border: 'none',
    background: '#2e4a73',
    color: 'white',
    fontSize: '1rem',
    cursor: 'pointer',
  },
};
