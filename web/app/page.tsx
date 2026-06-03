import { Suspense } from 'react';
import dynamic from 'next/dynamic';
import AevoriaSceneWrapper from './aevoria-scene-wrapper';

export default function HomePage() {
  return (
    <main style={{ width: '100vw', height: '100vh', overflow: 'hidden' }}>
      <Suspense fallback={null}>
        <AevoriaSceneWrapper />
      </Suspense>
    </main>
  );
}