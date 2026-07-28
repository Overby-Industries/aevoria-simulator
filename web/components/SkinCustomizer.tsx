'use client';

import { useEffect, useRef, useState } from 'react';
import * as THREE from 'three';
import {
  DEFAULT_RECIPE,
  MAX_FREQUENCY,
  MIN_FREQUENCY,
  type SkinRecipe,
} from '@/lib/skin-recipe';

// GLSL port of the cellular-noise + posterize logic in
// src/procedural_art_generator.cpp. Not pixel-identical to Godot's
// FastNoiseLite output — it's an independent Worley-noise implementation
// calibrated (see the threshold comment below) to produce a closely
// matching visual style: sparse dark "ink lines", a majority base tone,
// and a secondary highlight tone.
const VERTEX_SHADER = `
  varying vec2 vUv;
  void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
`;

const FRAGMENT_SHADER = `
  varying vec2 vUv;
  uniform float uSeed;
  uniform float uFrequency;
  uniform vec3 uDarkColor;
  uniform vec3 uBaseColor;
  uniform vec3 uHighlightColor;

  vec2 hash2(vec2 p) {
    vec2 k = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(k + uSeed * 17.0) * 43758.5453123);
  }

  // Returns (F1, F2): distance to the nearest and second-nearest feature
  // points in a jittered grid (standard Worley/cellular noise).
  vec2 cellular2x2(vec2 p) {
    vec2 iSt = floor(p);
    vec2 fSt = fract(p);
    float f1 = 8.0;
    float f2 = 8.0;
    for (int y = -1; y <= 1; y++) {
      for (int x = -1; x <= 1; x++) {
        vec2 neighbor = vec2(float(x), float(y));
        vec2 point = hash2(iSt + neighbor);
        vec2 diff = neighbor + point - fSt;
        float dist = length(diff);
        if (dist < f1) {
          f2 = f1;
          f1 = dist;
        } else if (dist < f2) {
          f2 = dist;
        }
      }
    }
    return vec2(f1, f2);
  }

  void main() {
    // 256.0 is a virtual texture resolution -- matches the pixel scale
    // Godot's generator operates in, so the same "frequency" value produces
    // a comparable number of visible cells here and in-game.
    vec2 p = vUv * 256.0 * uFrequency;
    float f2 = cellular2x2(p).y;

    // Thresholds calibrated empirically against this exact GLSL noise's
    // F2 distribution (measured range ~[0.05, 1.4], avg ~0.7 across the
    // frequency range above) to produce roughly 0-2% dark / ~78% base /
    // ~20% highlight -- matching the distribution targeted on the Godot
    // side, though the two are independently-tuned approximations of the
    // same style, not a byte-identical port.
    vec3 color;
    if (f2 < 0.22) {
      color = uDarkColor;
    } else if (f2 < 0.85) {
      color = uBaseColor;
    } else {
      color = uHighlightColor;
    }

    gl_FragColor = vec4(color, 1.0);
  }
`;

function hexToVec3(hex: string): THREE.Vector3 {
  const c = new THREE.Color(hex);
  return new THREE.Vector3(c.r, c.g, c.b);
}

export default function SkinCustomizer() {
  const containerRef = useRef<HTMLDivElement>(null);
  const recipeInputRef = useRef<HTMLInputElement>(null);
  const snapshotInputRef = useRef<HTMLInputElement>(null);
  const materialRef = useRef<THREE.ShaderMaterial | null>(null);

  const [recipe, setRecipe] = useState<SkinRecipe>(DEFAULT_RECIPE);

  // Three.js setup -- runs once.
  useEffect(() => {
    if (!containerRef.current) return;

    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0x14181f);

    const camera = new THREE.PerspectiveCamera(45, 1, 0.1, 100);
    camera.position.set(0, 0, 3.2);

    // preserveDrawingBuffer is required for a reliable canvas.toDataURL()
    // snapshot -- without it the WebGL buffer can be cleared by the time
    // the snapshot is captured on form submit.
    const renderer = new THREE.WebGLRenderer({ antialias: true, preserveDrawingBuffer: true });
    renderer.setSize(320, 320);
    renderer.setPixelRatio(window.devicePixelRatio);
    containerRef.current.appendChild(renderer.domElement);

    const material = new THREE.ShaderMaterial({
      vertexShader: VERTEX_SHADER,
      fragmentShader: FRAGMENT_SHADER,
      uniforms: {
        uSeed: { value: DEFAULT_RECIPE.seed },
        uFrequency: { value: DEFAULT_RECIPE.frequency },
        uDarkColor: { value: hexToVec3(DEFAULT_RECIPE.darkColor) },
        uBaseColor: { value: hexToVec3(DEFAULT_RECIPE.baseColor) },
        uHighlightColor: { value: hexToVec3(DEFAULT_RECIPE.highlightColor) },
      },
    });
    materialRef.current = material;

    const sphere = new THREE.Mesh(new THREE.SphereGeometry(1.4, 48, 48), material);
    scene.add(sphere);

    let animationFrameId: number;
    let frame = 0;
    function animate() {
      animationFrameId = requestAnimationFrame(animate);
      sphere.rotation.y += 0.004;
      renderer.render(scene, camera);

      // Keep the hidden snapshot field fresh from inside the render loop
      // rather than capturing it in a form 'submit' listener -- React's
      // Server Action form handling reads FormData at a point that doesn't
      // reliably run after a same-tick DOM mutation from a second 'submit'
      // listener, so a submit-time capture can race and ship an empty
      // snapshot. ~4/sec is enough to stay current with slider/color edits
      // without paying PNG-encode cost every frame.
      frame++;
      if ((frame === 1 || frame % 15 === 0) && snapshotInputRef.current) {
        snapshotInputRef.current.value = renderer.domElement.toDataURL('image/png');
      }
    }
    animate();

    return () => {
      cancelAnimationFrame(animationFrameId);
      renderer.dispose();
      material.dispose();
      sphere.geometry.dispose();
      if (containerRef.current) {
        containerRef.current.removeChild(renderer.domElement);
      }
    };
  }, []);

  // Push recipe changes into the shader's uniforms and the hidden form field.
  useEffect(() => {
    const material = materialRef.current;
    if (material) {
      material.uniforms.uSeed.value = recipe.seed;
      material.uniforms.uFrequency.value = recipe.frequency;
      material.uniforms.uDarkColor.value = hexToVec3(recipe.darkColor);
      material.uniforms.uBaseColor.value = hexToVec3(recipe.baseColor);
      material.uniforms.uHighlightColor.value = hexToVec3(recipe.highlightColor);
    }
    if (recipeInputRef.current) {
      recipeInputRef.current.value = JSON.stringify(recipe);
    }
  }, [recipe]);

  function randomizeSeed() {
    setRecipe((r) => ({ ...r, seed: Math.floor(Math.random() * 100000) }));
  }

  return (
    <div style={styles.wrapper}>
      <div ref={containerRef} style={styles.canvasContainer} />

      <input type="hidden" name="recipe" ref={recipeInputRef} />
      <input type="hidden" name="snapshot" ref={snapshotInputRef} />

      <div style={styles.controls}>
        <label style={styles.label}>
          Seed
          <div style={styles.seedRow}>
            <input
              style={styles.numberInput}
              type="number"
              value={recipe.seed}
              onChange={(e) => setRecipe((r) => ({ ...r, seed: Number(e.target.value) || 0 }))}
            />
            <button type="button" style={styles.randomButton} onClick={randomizeSeed}>
              Randomize
            </button>
          </div>
        </label>

        <label style={styles.label}>
          Pattern scale ({recipe.frequency.toFixed(3)})
          <input
            style={styles.slider}
            type="range"
            min={MIN_FREQUENCY}
            max={MAX_FREQUENCY}
            step={0.005}
            value={recipe.frequency}
            onChange={(e) => setRecipe((r) => ({ ...r, frequency: Number(e.target.value) }))}
          />
        </label>

        <div style={styles.colorRow}>
          <label style={styles.colorLabel}>
            Ink lines
            <input
              type="color"
              value={recipe.darkColor}
              onChange={(e) => setRecipe((r) => ({ ...r, darkColor: e.target.value }))}
            />
          </label>
          <label style={styles.colorLabel}>
            Base
            <input
              type="color"
              value={recipe.baseColor}
              onChange={(e) => setRecipe((r) => ({ ...r, baseColor: e.target.value }))}
            />
          </label>
          <label style={styles.colorLabel}>
            Highlight
            <input
              type="color"
              value={recipe.highlightColor}
              onChange={(e) => setRecipe((r) => ({ ...r, highlightColor: e.target.value }))}
            />
          </label>
        </div>
      </div>
    </div>
  );
}

const styles: Record<string, React.CSSProperties> = {
  wrapper: { display: 'flex', flexDirection: 'column', gap: '16px', alignItems: 'center' },
  canvasContainer: {
    width: '320px',
    height: '320px',
    borderRadius: '12px',
    overflow: 'hidden',
    border: '1px solid #2a2f3a',
  },
  controls: { display: 'flex', flexDirection: 'column', gap: '12px', width: '100%' },
  label: { display: 'flex', flexDirection: 'column', gap: '4px', fontSize: '0.85rem', color: '#e7e6e1' },
  seedRow: { display: 'flex', gap: '8px' },
  numberInput: {
    flex: 1,
    padding: '8px 10px',
    borderRadius: '6px',
    border: '1px solid #2a2f3a',
    background: '#0b0d10',
    color: '#e7e6e1',
  },
  randomButton: {
    padding: '8px 12px',
    borderRadius: '6px',
    border: '1px solid #2a2f3a',
    background: '#1c222c',
    color: '#e7e6e1',
    cursor: 'pointer',
  },
  slider: { width: '100%' },
  colorRow: { display: 'flex', gap: '16px', justifyContent: 'space-between' },
  colorLabel: { display: 'flex', flexDirection: 'column', gap: '4px', fontSize: '0.8rem', color: '#9aa2b0', alignItems: 'center' },
};
