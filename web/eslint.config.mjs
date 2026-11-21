import { defineConfig, globalIgnores } from 'eslint/config';
import nextCoreWebVitals from 'eslint-config-next/core-web-vitals';
import prettier from 'eslint-config-prettier/flat';

// Flat-config replacement for the old .eslintrc.json (`next lint` was removed in
// Next 16, so `npm run lint` now calls ESLint directly).
export default defineConfig([
  ...nextCoreWebVitals,
  // Must stay after the Next config so it can switch off conflicting style rules.
  prettier,
  {
    rules: {
      'react/no-unescaped-entities': 'off',
      '@next/next/no-img-element': 'off',
    },
  },
  // Mirrors web/.gitignore and web/.prettierignore (build output, generated files).
  globalIgnores(['.next/**', 'out/**', 'build/**', 'dist/**', 'coverage/**', 'next-env.d.ts']),
]);
