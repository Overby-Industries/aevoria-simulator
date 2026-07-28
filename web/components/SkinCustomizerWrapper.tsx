'use client';

import dynamic from 'next/dynamic';

const SkinCustomizer = dynamic(() => import('./SkinCustomizer'), {
  ssr: false,
  loading: () => (
    <div
      style={{
        width: '320px',
        height: '320px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        borderRadius: '12px',
        border: '1px solid #2a2f3a',
        color: '#6d7482',
        fontSize: '0.85rem',
      }}
    >
      Loading preview...
    </div>
  ),
});

export default function SkinCustomizerWrapper() {
  return <SkinCustomizer />;
}
