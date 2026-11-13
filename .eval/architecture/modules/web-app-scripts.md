# Module: web-app/scripts

Provides standalone CLI scripts and helper utilities to scrape customer reviews from Trustpilot via Apify, match them against won marketplace jobs and DJ profiles, and import approved reviews into the Supabase Reviews database table.

## Key files
- `web-app/scripts/trustpilot/_shared.ts`: Shared client utilities, environment validation, CSV parser/serializer with delimiter auto-detection, and name/date heuristic matching types.
- `web-app/scripts/trustpilot/scrape-and-match.ts`: CLI pipeline script that fetches Trustpilot reviews using Apify, correlates them with won jobs and DJ profiles, and saves match proposals to candidates.csv.
- `web-app/scripts/trustpilot/insert-approved.ts`: CLI pipeline script that reads reviewed candidates from candidates.csv, validates fields, and idempotently inserts approved rows into the Reviews table.

## Public interface
- getAdminClient(): SupabaseClient
- parseCsv(text: string): { headers: string[]; rows: CsvRow[] }
- toCsv(headers: string[], rows: CsvRow[]): string
- normalizeName(s: string): string
- toIsoDate(s: string): string
- CLI execution: bun run scripts/trustpilot/scrape-and-match.ts (trustpilot:scrape)
- CLI execution: bun run scripts/trustpilot/insert-approved.ts (trustpilot:insert)

## Dependencies
- @supabase/supabase-js
- node:fs
- node:path
- Apify API (https://api.apify.com/v2)

## Open questions
- Are the matching helper functions truncated in _shared.ts (e.g., loadDjs, loadWonJobs, matchReview, truncate) tested anywhere or shared with web-app runtime APIs?
- Is this Trustpilot review import workflow meant strictly as an ad-hoc local admin task, or is it integrated into a recurring automation or CI/CD workflow?
