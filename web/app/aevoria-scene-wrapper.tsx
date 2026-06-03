'use client';

import dynamic from 'next/dynamic';

const AevoriaScene = dynamic(() => import('@/components/aevoria-scene'), {
  ssr: false,
  loading: () => (
    <div style={{ 
      display: 'flex', 
      alignItems: 'center', 
      justifyContent: 'center', 
      height: '100vh',
      background: '#000',
      color: '#fff',
      fontFamily: 'monospace'
    }}>
      <p>Loading Aevoria Commonwealth...</p>
    </div>
  ),
});

export default function AevoriaSceneWrapper() {
  return <AevoriaScene />;
}