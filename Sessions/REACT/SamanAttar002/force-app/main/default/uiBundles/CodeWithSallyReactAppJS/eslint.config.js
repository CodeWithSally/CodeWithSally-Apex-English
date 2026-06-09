import js from '@eslint/js';
import react from 'eslint-plugin-react';
import reactHooks from 'eslint-plugin-react-hooks';
import reactRefresh from 'eslint-plugin-react-refresh';
import globals from 'globals';

export default [
  // Global ignores
  {
    ignores: ['build/**/*', 'dist/**/*', 'coverage/**/*'],
  },
  // Config files and build tools (first to avoid inheritance)
  {
    files: ['*.config.js', 'vite.config.js'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        ...globals.node,
        __dirname: 'readonly',
        process: 'readonly',
      },
    },
  },
  // Main JavaScript/React files
  {
    files: ['**/*.{js,jsx}'],
    ignores: [
      'coverage',
      'dist',
      'node_modules',
      'build',
      '*.config.js',
      'vite.config.js',
    ],
    languageOptions: {
      ecmaVersion: 2020,
      sourceType: 'module',
      parserOptions: {
        ecmaFeatures: {
          jsx: true,
        },
        ecmaVersion: 'latest',
        sourceType: 'module',
      },
      globals: {
        ...globals.browser,
        React: 'readonly',
        process: 'readonly',
      },
    },
    plugins: {
      react,
      'react-hooks': reactHooks,
      'react-refresh': reactRefresh,
    },
    rules: {
      ...js.configs.recommended.rules,
      ...react.configs.recommended.rules,
      ...reactHooks.configs.recommended.rules,
      'react/react-in-jsx-scope': 'off',
      'react/prop-types': 'off',
      'react/jsx-no-comment-textnodes': 'off',
      'react/no-unescaped-entities': 'off',
      'no-unused-vars': [
        'error',
        {
          argsIgnorePattern: '^_',
          varsIgnorePattern: '^_',
          caughtErrorsIgnorePattern: '^_',
          ignoreRestSiblings: true,
        },
      ],
      'react-hooks/set-state-in-effect': 'warn',
    },
    settings: {
      react: {
        version: 'detect',
      },
    },
  },
  // Test files
  {
    files: ['**/*.test.{js,jsx}', '**/test/**/*.{js,jsx}', 'src/test/**/*.{js,jsx}'],
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
        global: 'writable',
      },
    },
  },
];
