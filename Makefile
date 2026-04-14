# DJ Tilbud Mobile — Dev Commands
# Usage: make <target>
#
# Environments:
#   local  → local Supabase (http://127.0.0.1:54321) — default for dev
#   dev    → remote dev Supabase (dnfwbfmjlkjgvenvrkwt.supabase.co)
#   prod   → production Supabase — never used for builds, read-only reference

.PHONY: run run-local run-dev build-dev build-prod clean

# ── Run ────────────────────────────────────────────────────────────────────────

run: run-local

run-local:
	flutter run --dart-define=ENV=local

run-dev:
	flutter run --dart-define=ENV=dev

# ── Build (App Store) ──────────────────────────────────────────────────────────
# App Store builds ALWAYS use dev. Never build with local or prod.

build-dev:
	flutter build ipa --dart-define=ENV=dev --release

# ── Helpers ────────────────────────────────────────────────────────────────────

clean:
	flutter clean && flutter pub get
