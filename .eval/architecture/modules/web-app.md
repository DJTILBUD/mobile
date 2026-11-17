# Module: web-app

Provides application configuration, linting rules, Sentry error monitoring initialization (server and edge runtimes), environment variable validation, and Vitest test runner settings for the web-app module.

## Key files
- `web-app/next.config.js`: Next.js configuration defining image domains, Sentry webpack/monitoring wrapping, and next-pwa plugin integration.
- `web-app/eslint.config.mjs`: ESLint flat configuration setting up Next.js vitals, React Compiler/hooks rules, unused imports filtering, and directory ignore lists.
- `web-app/sentry.edge.config.ts`: Initializes Sentry for Next.js edge runtime features and middleware with tracing and PII logging enabled.
- `web-app/sentry.server.config.ts`: Initializes Sentry for the Next.js server runtime with tracing and PII logging enabled.
- `web-app/validateEnv.ts`: Scans TypeScript/JavaScript files across the repository to validate used process.env variables against required and optional entries in .env.example.
- `web-app/vitest.config.ts`: Vitest test configuration defining aliases (@, @api), test timeouts, thread concurrency, test environment secrets, and setup scripts.

## Public interface
- validateEnv() (web-app/validateEnv.ts)

## Dependencies
- @sentry/nextjs
- next-pwa
- eslint-config-next
- eslint-plugin-react
- eslint-plugin-unused-imports
- vitest
- dotenv
- fs
- path

## Open questions
- _none_
