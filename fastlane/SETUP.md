# Mobile release automation (fastlane)

> Note: `fastlane/README.md` is **auto-generated** by fastlane on every run — this
> `SETUP.md` is the real guide, keep it here.

One command per platform, run locally from `mobile/`. Signing stays on your Mac
(Android `key.properties` + local keystore, iOS automatic signing). No signing
secrets are committed.

```bash
fastlane release_both      # THE release command: bump ONCE, ship BOTH stores (same version)
fastlane android release   # re-ship CURRENT version to Google Play only (NO bump — retry)
fastlane ios release       # re-ship CURRENT version to the App Store only (NO bump — retry)
```

**Always use `fastlane release_both` for a release.** It bumps `pubspec.yaml` **once**
(`X.Y.Z+N -> X.Y.(Z+1)+(N+1)`) and then ships both stores from that **same** version, so
Android and iOS can never drift apart. It prepares everything (build, version/build number,
release notes) and stops before going live — the only manual step is the final confirm
click in each console.

**The single-platform lanes (`android release` / `ios release`) do NOT bump** — they ship
whatever version is currently in `pubspec.yaml`. Use them **only to retry one platform**
after a failure (so it re-ships at the same version and the two stores stay matched).
⚠️ Do **not** run them to start a new release: running each platform separately (each with
its own bump, the old behaviour) is exactly what let iOS's version race ahead of Android.

## One-time setup (already done)
- **fastlane:** `brew install fastlane`.
- **Google Play:** service account JSON at `fastlane/play-service-account.json` (the
  service account must be invited in Play Console with Release/Admin permission, and the
  "Google Play Android Developer API" enabled in its Google Cloud project).
- **App Store Connect:** API key at `fastlane/AuthKey.p8`, plus `ASC_KEY_ID` +
  `ASC_ISSUER_ID` in `fastlane/.env` (copy from `fastlane/.env.example`).
- All three secret files are gitignored — never commit them.

## Every release
1. **Edit the release notes** (default to Danish "Fejlrettelser og forbedringer."):
   - Android (Play "What's new"): `fastlane/metadata/android/da-DK/changelogs/default.txt`
   - iOS App Store "What's New": `fastlane/metadata/ios/da/release_notes.txt`
   - iOS TestFlight "What to Test": `fastlane/metadata/testflight_changelog.txt`
2. **Run `fastlane release_both`** from `mobile/`. It bumps the version once and ships both
   stores on that same version. (Version bump is automatic — nothing to edit in pubspec.)
3. **Android — just approve:** the lane uploads a **draft** to Production with the build +
   notes filled in. Play Console → your app → **Production** → review → **Rollout to production**.
4. **iOS — test, then just submit:** the lane pushes the build to **TestFlight** (test it in
   a few minutes) **and** stages the App Store version with the build + "What's New" attached.
   When happy: App Store Connect → your app → the prepared version → **Submit for Review**.
   One click, nothing to type. (This lane waits ~10–20 min for Apple to process the build.)

Both approvals stay manual on purpose — going live is the irreversible, outward-facing gate.

## Notes / gotchas
- **Version code / build number must strictly increase** for every upload, on both stores
  (and the App Store needs a higher version *name* once a version is released).
  `release_both` bumps once to handle this. **Keep Android + iOS in sync by always releasing
  with `release_both`** — never run `android release`/`ios release` per-platform for a new
  release (each store would advance separately). If one platform fails inside `release_both`,
  retry just that platform with its single lane (no bump) so it re-ships the same version.
- **Android uploads a draft** to the `production` track. To auto-publish (live immediately)
  set `release_status: "completed"` in `Fastfile`; to ship to testers first change `PLAY_TRACK`
  to `internal`/`beta`.
- **Release-note locale folders are Danish-only** (your app's primary language):
  `fastlane/metadata/android/da-DK/` and `fastlane/metadata/ios/da/`. A locale your store
  listing doesn't have would error on upload. To add English later, create
  `fastlane/metadata/android/en-US/changelogs/default.txt` and
  `fastlane/metadata/ios/en-US/release_notes.txt` — only if those listings have English enabled.
- **Export compliance is pre-answered.** `ios/Runner/Info.plist` sets
  `ITSAppUsesNonExemptEncryption = false` (app uses only exempt HTTPS/TLS encryption), so
  App Store Connect never shows "Missing Compliance" and skips the France encryption
  declaration. Flip to `<true/>` only if the app ever ships non-exempt encryption needing
  an export license.
- **Never commit** `play-service-account.json`, `AuthKey.p8`, or `.env` — they're gitignored.
- The Android keystore (`~/djtilbud-release.jks`) and `android/key.properties` stay as-is —
  fastlane reuses them via the normal Gradle build.
- `fastlane/README.md` is regenerated by fastlane on each run; edit **this** file instead.
