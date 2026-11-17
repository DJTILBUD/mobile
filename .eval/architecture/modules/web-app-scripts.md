# Module: web-app/scripts

Provides CLI utilities and batch scripts to scrape Trustpilot reviews via Apify, match reviews against DJs and won jobs using name/date heuristics, generate candidate CSVs for manual auditing, and insert approved reviews into the Supabase Reviews table.

## Key files
- `web-app/scripts/trustpilot/_shared.ts`: Defines shared data types, Supabase admin client initialization with production safeguards, CSV parsing/serialization helpers, and review-matching heuristics.
- `web-app/scripts/trustpilot/scrape-and-match.ts`: CLI script that scrapes Trustpilot reviews via Apify actor runs, matches reviews against won jobs and DJ profiles, and writes deduplicated candidates to candidates.csv.
- `web-app/scripts/trustpilot/insert-approved.ts`: CLI script that parses approved rows from candidates.csv and idempotently inserts them into the database Reviews table via the Supabase admin client.

## Public interface
- getAdminClient(): SupabaseClient
- parseCsv(text: string): { headers: string[]; rows: CsvRow[] }
- toCsv(headers: string[], rows: CsvRow[]): string
- normalizeName(s: string): string
- toIsoDate(s: string): string
- TpReview
- WonJob
- DjRecord
- Confidence
- MatchResult
- CsvRow

## Dependencies
- @supabase/supabase-js
- node:fs
- node:path

## Open questions
- _none_
