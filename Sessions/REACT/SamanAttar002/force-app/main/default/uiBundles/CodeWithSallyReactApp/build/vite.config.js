var __spreadArray = (this && this.__spreadArray) || function (to, from, pack) {
    if (pack || arguments.length === 2) for (var i = 0, l = from.length, ar; i < l; i++) {
        if (ar || !(i in from)) {
            if (!ar) ar = Array.prototype.slice.call(from, 0, i);
            ar[i] = from[i];
        }
    }
    return to.concat(ar || Array.prototype.slice.call(from));
};
import { existsSync } from 'node:fs';
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import { resolve } from 'path';
import tailwindcss from '@tailwindcss/vite';
import salesforce from '@salesforce/vite-plugin-ui-bundle';
import codegen from 'vite-plugin-graphql-codegen';
var schemaPath = resolve(__dirname, '../../../../../schema.graphql');
var schemaExists = existsSync(schemaPath);
export default defineConfig(function (_a) {
    var mode = _a.mode;
    return {
        base: './',
        plugins: __spreadArray([
            tailwindcss(),
            react(),
            salesforce()
        ], (schemaExists
            ? [
                codegen({
                    configFilePathOverride: resolve(__dirname, 'codegen.yml'),
                    runOnStart: true,
                    runOnBuild: true,
                    enableWatcher: true,
                    throwOnBuild: true,
                }),
            ]
            : []), true),
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
            setupFiles: ['./src/test/setup.ts'],
            // Global test patterns
            include: [
                'src/**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}',
                'src/**/__tests__/**/*.{js,mjs,cjs,ts,mts,cts,jsx,tsx}',
            ],
            // Coverage configuration
            coverage: {
                provider: 'v8',
                reporter: ['text', 'html', 'clover', 'json'],
                exclude: [
                    'node_modules/',
                    'src/test/',
                    'src/**/*.d.ts',
                    'src/main.tsx',
                    'src/vite-env.d.ts',
                    'src/components/**/index.ts',
                    '**/*.config.ts',
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
