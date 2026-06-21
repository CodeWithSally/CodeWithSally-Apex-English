import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import { resolve } from 'path';
import { fileURLToPath } from 'node:url';
import { dirname } from 'node:path';
import tailwindcss from '@tailwindcss/vite';
import salesforce from '@salesforce/vite-plugin-ui-bundle';

const __dirname = dirname(fileURLToPath(import.meta.url));

export default defineConfig(() => {
  return {
    base: './',
    plugins: [tailwindcss(), react(), salesforce()],

    // Build configuration for MPA
    build: {
      outDir: resolve(__dirname, 'dist'),
      assetsDir: 'assets',
      sourcemap: false,
    },

    // Resolve aliases (shared between build and test)
    resolve: {
      dedupe: ['react', 'react-dom'],
      alias: {
        '@': path.resolve(__dirname, './src'),
        '@api': path.resolve(__dirname, './src/api'),
        '@components': path.resolve(__dirname, './src/components'),
        '@utils': path.resolve(__dirname, './src/utils'),
        '@styles': path.resolve(__dirname, './src/styles'),
        '@assets': path.resolve(__dirname, './src/assets'),
      },
    },

    // Vitest configuration
    test: {
      // Override root for tests (build uses src/pages as root)
      root: resolve(__dirname),

      // Use jsdom environment for React component testing
      environment: 'jsdom',

      // Setup files to run before each test
      setupFiles: ['./vitest.setup.js'],

      // Global test patterns
      include: [
        'src/**/*.{test,spec}.{js,mjs,cjs,jsx}',
        'src/**/__tests__/**/*.{js,mjs,cjs,jsx}',
      ],

      // Coverage configuration
      coverage: {
        provider: 'v8',
        reporter: ['text', 'html', 'clover', 'json'],
        exclude: [
          'node_modules/',
          'src/test/',
          'src/app.jsx',
          'src/components/**/index.js',
          '**/*.config.js',
          'build/',
          'dist/',
          'coverage/',
          'eslint.config.js',
        ],
        thresholds: {
          global: {
            branches: 85,
            functions: 85,
            lines: 85,
            statements: 85,
          },
        },
      },

      // Test timeout
      testTimeout: 10000,

      // Globals for easier testing
      globals: true,
    },
  };
});
