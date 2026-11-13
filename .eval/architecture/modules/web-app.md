# Module: web-app

Provides root build, runtime configuration, error tracking, environment validation, testing setup, and linting rules for the web-app Next.js application.

## Key files
- `web-app/next.config.js`: Configures Next.js application settings including PWA support, allowed image domains, and Sentry monitoring integration.
- `web-app/sentry.server.config.ts`: Initializes Sentry error and trace reporting on the server runtime.
- `web-app/sentry.edge.config.ts`: Initializes Sentry error and trace reporting on the Edge runtime.
- `web-app/validateEnv.ts`: Scans project code files to validate runtime environment variables against the required and optional definitions in .env.example.
- `web-app/vitest.config.ts`: Defines test runner configuration, concurrency, path aliases (@ and @api), and fallback test environment variables.
- `web-app/eslint.config.mjs`: ESLint flat configuration managing React hooks, React compiler lint rules, and unused import cleanup.

## Public interface
- validateEnv() in web-app/validateEnv.ts
- default export (NextConfig with Sentry and PWA wrappers) in web-app/next.config.js
- default export (ESLint flat config) in web-app/eslint.config.mjs
- default export (Vitest config) in web-app/vitest.config.ts

## Dependencies
- @sentry/nextjs
- next-pwa
- vitest/config
- dotenv
- eslint-config-next
- eslint-plugin-react
- eslint-plugin-unused-imports
- fs
- path

## Open questions
- _none_
