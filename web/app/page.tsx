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
      <Suspense fallback={null}>
        <AevoriaSceneWrapper />
      </Suspense>
    </main>
  );
}