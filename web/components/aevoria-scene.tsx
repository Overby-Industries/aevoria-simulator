'use client';

import { useEffect, useRef, useState } from 'react';
import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

export default function AevoriaScene() {
  const containerRef = useRef<HTMLDivElement>(null);
  const [initialized, setInitialized] = useState(false);

  useEffect(() => {
    if (!containerRef.current || initialized) return;

    // Scene setup
    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0x000011);
    scene.fog = new THREE.Fog(0x000011, 10, 100);

    // Camera
    const camera = new THREE.PerspectiveCamera(
      60,
      window.innerWidth / window.innerHeight,
      0.1,
      1000
    );
    camera.position.set(15, 8, 20);
    camera.lookAt(0, 0, 0);

    // Renderer
    const renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setPixelRatio(window.devicePixelRatio);
    renderer.shadowMap.enabled = true;
    containerRef.current.appendChild(renderer.domElement);

    // Lights
    const ambientLight = new THREE.AmbientLight(0x333366, 0.5);
    scene.add(ambientLight);
    
    const sunLight = new THREE.DirectionalLight(0xffffff, 2);
    sunLight.position.set(50, 30, 20);
    sunLight.castShadow = true;
    scene.add(sunLight);

    const accentLight = new THREE.PointLight(0x4466ff, 1, 50);
    accentLight.position.set(-10, 5, 10);
    scene.add(accentLight);

    // Placeholder objects
    const stationGeometry = new THREE.CylinderGeometry(2, 3, 8, 32);
    const stationMaterial = new THREE.MeshStandardMaterial({ 
      color: 0x4466aa, 
      metalness: 0.8, 
      roughness: 0.3 
    });
    const station = new THREE.Mesh(stationGeometry, stationMaterial);
    station.castShadow = true;
    station.position.set(0, 0, 0);
    scene.add(station);

    const ringGeometry = new THREE.TorusGeometry(4, 0.2, 16, 64);
    const ringMaterial = new THREE.MeshStandardMaterial({ 
      color: 0x88aaff, 
      metalness: 0.9, 
      roughness: 0.2,
      emissive: 0x112244,
      emissiveIntensity: 0.5
    });
    const ring = new THREE.Mesh(ringGeometry, ringMaterial);
    ring.rotation.x = Math.PI / 3;
    ring.position.set(0, 2, 0);
    scene.add(ring);

    // Stars
    const starsGeometry = new THREE.BufferGeometry();
    const starsCount = 2000;
    const starsPositions = new Float32Array(starsCount * 3);
    for (let i = 0; i < starsCount; i++) {
      starsPositions[i * 3] = (Math.random() - 0.5) * 200;
      starsPositions[i * 3 + 1] = (Math.random() - 0.5) * 200;
      starsPositions[i * 3 + 2] = (Math.random() - 0.5) * 200;
    }
    starsGeometry.setAttribute('position', new THREE.BufferAttribute(starsPositions, 3));
    const starsMaterial = new THREE.PointsMaterial({ 
      color: 0xffffff, 
      size: 0.15,
      blending: THREE.AdditiveBlending
    });
    const stars = new THREE.Points(starsGeometry, starsMaterial);
    scene.add(stars);

    // Controls
    const controls = new OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.05;
    controls.target.set(0, 1, 0);
    controls.update();

    // Animation loop
    function animate() {
      requestAnimationFrame(animate);
      ring.rotation.y += 0.002;
      station.rotation.y -= 0.001;
      stars.rotation.y += 0.0001;
      controls.update();
      renderer.render(scene, camera);
    }
    animate();

    // Handle window resize
    function onResize() {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
    }
    window.addEventListener('resize', onResize);

    setInitialized(true);

    return () => {
      window.removeEventListener('resize', onResize);
      renderer.dispose();
      if (containerRef.current) {
        containerRef.current.removeChild(renderer.domElement);
      }
    };
  }, [containerRef, initialized]);

  return (
  <div ref={containerRef} style={{ width: '100%', height: '100vh', position: 'relative' }}>
    {/* Nav Overlay */}
    <div style={{
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'flex-start',
      padding: '24px 32px',
      pointerEvents: 'none',
      zIndex: 10,
    }}>
      <div style={{
        display: 'flex',
        flexDirection: 'column',
        gap: '4px',
      }}>
        <h1 style={{
          margin: 0,
          fontSize: '28px',
          fontWeight: 300,
          letterSpacing: '6px',
          color: '#ffffff',
          textShadow: '0 0 20px rgba(100, 150, 255, 0.5)',
          fontFamily: "'Segoe UI', system-ui, sans-serif",
        }}>
          AEVORIA
        </h1>
        <p style={{
          margin: 0,
          fontSize: '13px',
          fontWeight: 300,
          letterSpacing: '4px',
          color: 'rgba(180, 200, 255, 0.7)',
          fontFamily: "'Segoe UI', system-ui, sans-serif",
          fontStyle: 'italic',
        }}>
          Per Avia, Ad Astra
        </p>
      </div>

      <div style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'flex-end',
        gap: '12px',
        pointerEvents: 'auto',
      }}>
        <span style={{
          fontSize: '11px',
          letterSpacing: '3px',
          color: 'rgba(255, 255, 255, 0.4)',
          fontFamily: 'monospace',
          textTransform: 'uppercase',
        }}>
          Aevoric Commonwealth
        </span>
      </div>
    </div>

    {/* Bottom Status Bar */}
    <div style={{
      position: 'absolute',
      bottom: 0,
      left: 0,
      right: 0,
      display: 'flex',
      justifyContent: 'space-between',
      padding: '16px 32px',
      borderTop: '1px solid rgba(100, 150, 255, 0.1)',
      background: 'linear-gradient(transparent, rgba(0, 0, 20, 0.6))',
      pointerEvents: 'none',
      zIndex: 10,
    }}>
      <span style={{
        fontSize: '10px',
        letterSpacing: '2px',
        color: 'rgba(255, 255, 255, 0.4)',
        fontFamily: 'monospace',
        textTransform: 'uppercase',
      }}>
        CUR v1.5.1 — Tier 0: Awakening
      </span>
      <span style={{
        fontSize: '10px',
        letterSpacing: '2px',
        color: 'rgba(100, 180, 255, 0.5)',
        fontFamily: 'monospace',
      }}>
        SYS NOMINAL
      </span>
    </div>
  </div>
);
}