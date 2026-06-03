"use client";

import { Suspense } from 'react';
import dynamic from 'next/dynamic'

// 2. Dynamically import the wrapper with SSR disabled
const AevoriaSceneWrapper = dynamic(() => import('./aevoria-scene-wrapper'), { 
  ssr: false 
})

export default function HomePage() {
  return (
    <main style={{ width: '100vw', height: '100vh', overflow: 'hidden' }}>
      <Suspense fallback={<div style={{ color: 'white', padding: '20px' }}>Loading 3D Scene...</div>}>
        <AevoriaSceneWrapper />
      </Suspense>
    </main>
  );
}