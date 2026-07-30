# Mobile App — Flutter (Musician-facing)

Flutter app for musicians: browse jobs, submit offers, manage profile, use the AI pitch agent. Runs in parallel with the web-app — both serve live musicians.

This is also a **master's thesis** on evaluating LLM interaction quality as actionable feedback when building an AI-assisted app. Every AI/agent design decision must serve both product goals and research observability.

## THE WEB-APP IS THE SOURCE OF TRUTH — READ THIS FIRST

The **web-app is the canonical, most-tested, proven-correct implementation** of every shared business rule (quote/offer flow, status transitions, pricing, cancellation, closing jobs, notifications, content). It serves live users and is where we *know* the logic works. The mobile app must **never re-derive, reinterpret, or "clean up" that logic** — when a behaviour exists in the web-app, copy it **exactly**. A mobile version that diverges is a bug, even when it looks reasonable. This has caused real mistakes before; do not repeat them.

**Before implementing any shared behaviour on mobile, go read the web-app's implementation first** — the route handler in `web-app/src/app/api/`, or the relevant `web-app/src/` service — and match it line-for-line in intent. The **live `web-app/` is the real source of truth** (there is no `webapp-reference/` snapshot folder; read the live `web-app/` code).

**Quick rule lookup:** `web-app/documentation/business-rules.md` is a code-cited index of every shared business rule (commission, quote caps, the status machine, cancellation, invoicing, extra-hours window, etc.) with the exact file each is enforced in. Start there to find the canonical rule, then read the cited code.

### Target architecture: mobile talks to the DB *through* the web-app

```
web-app  →  DB              (direct — web-app owns the DB and the logic)
mobile   →  web-app API  →  DB   (preferred for every write / business-logic op)
```

The goal is **one shared, tested path to the DB** so the rules can never drift between platforms. The web-app exposes HTTP endpoints under `web-app/src/app/api/`; mobile calls them via `_webApiPost` / `_webApiPut` (see `createServiceOffer` and the ext-job datasource methods for the pattern).

**Rules:**
- For any **write that carries business logic** (creating quotes/offers, status changes, closing jobs, recording content, firing notifications), **call the web-app endpoint** — do NOT write to Supabase directly from Flutter. A direct insert/update bypasses logic that lives only in the route handler, and often silently no-ops under RLS or leaves rows in a wrong state (see the `Quotes` and `Jobs.status` notes in "Things Claude must NOT do").
- If the web-app does **not** yet expose an endpoint for what you need, the fix is to **add the endpoint in the web-app and call it from mobile** — never reimplement the logic in Dart. **Confirm with the user before adding a new shared endpoint.**
- Direct Supabase **reads** for simple, logic-free fetches and Realtime subscriptions are fine. This rule is about **writes and business logic**, not every query.

## ALWAYS READ THESE THREE FOLDERS FIRST

Before building or changing anything, read the relevant folder(s) below. They are the memory of the system.

| Folder | What it contains |
|---|---|
| `architecture/` | How the app is built — three-layer rule, Riverpod patterns, routing, error handling, naming |
| `design-system/` | UI components, Figma MCP connection, theme, shared widgets, icon and font conventions |
| `ai-agent/` | How the AI pitch agent works — interaction rules, model settings, logging, thesis observability |

## Tech stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) — latest stable |
| Platform | iOS + Android |
| Backend | Supabase (shared with all other apps) |
| Auth | Supabase Auth |
| Realtime | Supabase Realtime |
| Storage | **AWS S3** for user media (images/videos/thumbnails, via presigned PUT) — NOT Supabase Storage. See "DJ content capture" below. |
| Push notifications | Firebase Cloud Messaging (FCM) |
| AI agent | Anthropic Claude API via Supabase Edge Function |
| State management | Riverpod 2.0+ with code generation |
| Navigation | go_router |

## Environments and build commands

```bash
flutter run                        # local (default — always use this)
flutter run --dart-define=ENV=dev  # staging
flutter run --dart-define=ENV=prod # production

flutter analyze                    # static analysis — run before declaring done
flutter test                       # unit/widget tests — run before declaring done
dart run build_runner build --delete-conflicting-outputs  # regen Riverpod/codegen after editing annotated providers
```

Env files: `.env.local` (default), `.env.dev`, `.env.prod`, `.env.example` (only one in git).

The "typecheck + tests" done-bar for this app = `flutter analyze` + `flutter test` (this folder already has a fuller "Definition of done" checklist at the bottom). Note: `build_runner` is **not** a dependency here — generated files are committed, so `dart run build_runner build` fails with "Could not find package build_runner" and is a no-op; don't treat that as a blocker.

## Releasing (Android + iOS)

**The release command is `fastlane release_both`, run from `mobile/`** (`mobile/fastlane/`, added
2026-07-08). It bumps `pubspec.yaml` `X.Y.Z+N → X.Y.(Z+1)+(N+1)` **once**, then builds + uploads BOTH
stores from that one version.

**Do NOT start a release with `fastlane android release` / `fastlane ios release`.** Those two lanes
deliberately do **not** bump — they ship whatever is currently in `pubspec.yaml` and exist ONLY to
re-run one platform at the current version after a failure. Running them per-platform for a new
release is exactly what let iOS's version drift ahead of Android. `release_both` is the only lane
that bumps, which is what keeps the two stores on the same number.

**Neither store goes live on its own** — both lanes stage, you click:
- **Android** → uploaded to the `production` track as a **draft** (`release_status: "draft"`); you hit
  "Rollout to production" in the Play Console. To auto-publish instead, set `release_status: "completed"`.
- **iOS** → uploaded to **TestFlight** (internal only, `distribute_external: false`, waits for
  processing), then `upload_to_app_store` **stages** the App Store version with the build attached and
  leaves it in "Prepare for Submission" (`submit_for_review: false`); you click Submit for Review.

Release notes are read from files at run time — **update them before running**:
`fastlane/metadata/android/<locale>/changelogs/default.txt` (Play), `fastlane/metadata/ios/<locale>/release_notes.txt`
("What's New"), `fastlane/metadata/testflight_changelog.txt` ("What to Test").

Signing stays local (Android `key.properties`, iOS automatic signing). Credentials are gitignored and NOT in the repo — a Google Play service-account JSON
(`fastlane/play-service-account.json`), an App Store Connect API key (`fastlane/AuthKey.p8` +
`ASC_KEY_ID`/`ASC_ISSUER_ID` in `fastlane/.env`). Full setup + per-release steps: **`mobile/fastlane/SETUP.md`** (note: `fastlane/README.md` is auto-regenerated by fastlane on every run, so the real guide lives in `SETUP.md`).
The lanes just wrap the manual `flutter build …` commands below, so this section stays the ground truth
for artifact paths / signing — with **one** deliberate difference: the iOS lane runs
`env -u GEM_HOME -u GEM_PATH PATH=/opt/homebrew/bin:$PATH flutter build ipa`. Fastlane exports
`GEM_HOME`/`GEM_PATH` pointing at its own gem dir; the Homebrew `pod` wrapper overrides `GEM_HOME` but
not `GEM_PATH`, so pod loads fastlane's gems, hits a dependency conflict and exits non-zero. Flutter
reads that as "CocoaPods is installed but broken. Skipping pod install." and the build fails — only
under fastlane, never in a plain shell. Don't drop the `env -u`.

**Underlying manual process** (what fastlane wraps; still valid if you upload by hand). Both stores
require the build number to strictly increase.

1. **Bump version** in `pubspec.yaml` `version: X.Y.Z+N` (semantic version `+` build number — `versionName`/`versionCode` derive from it). Patch bump + increment build for a bugfix (e.g. `1.0.10+34 → 1.0.11+35`).
2. **Done-bar:** `flutter analyze --no-fatal-infos --no-fatal-warnings` (the `_c` underscore lints are a pre-existing baseline — only errors block) + `flutter test`.
3. **Android:** `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`. Signed via `android/key.properties` → keystore at `/Users/victorbrorson/djtilbud-release.jks` (machine-local, gitignored, NOT in repo — a fresh clone cannot sign without it). App id `com.djtilbud.app`. Upload to Play Console.
4. **iOS:** `flutter build ipa --release` → `build/ios/ipa/dj_tilbud_app.ipa`. Signing is **Automatic** with `DEVELOPMENT_TEAM = 87QC252TJH`; even with only Apple *Development* certs in the keychain, automatic signing produced a store-method IPA from CLI (no Apple *Distribution* cert / Xcode Organizer step needed). Upload via **Transporter** (drag the `.ipa`) or `xcrun altool --upload-app`. Bundle id `com.djtilbud.app`, min iOS 16.6.
5. The "Launch image is the default placeholder" warning is pre-existing and non-blocking.

Claude cannot do the store uploads (needs store credentials + it's the irreversible outward-facing step) — hand the signed artifacts + release notes to the user.

## The 4 success dimensions

Every feature, UI decision, and AI interaction must serve all four:

1. **Musician success (primary)** — Musicians submit offers with less effort and less hesitation. Every friction point in the offer flow is a failure. Speed is non-negotiable.
2. **Marketplace trust** — Offers and profiles are clear, specific, believable. AI must NOT invent claims.
3. **LLM interaction quality (thesis core)** — When something goes wrong in the AI interaction, it must be traceable to a specific lever (prompt, context, UI, model settings) and fixable.
4. **Practical viability** — Push notifications must be reliable. LLM responses must stream. UI must be learnable in under 2 minutes.

## Critical user flows

**Flow 1 — Job notification → offer submitted (critical path):**
```
Push notification → tap → job detail screen → "Make Offer" or "Get AI Help" → draft → submit
```
Optimize everything for speed and zero friction here.

**Flow 2 — AI agent assists offer:**
```
Job detail → AI agent tab → agent asks ≤2 questions → produces draft → musician edits inline → submits
```

**Flow 3 — Profile management:** View/edit bio, videos, images, reviews. AI can help rewrite bio sections.

**Flow 4 — Job browse:** Paginated list, filter by event type / location / date.

## Push notification handling

Notification routing lives in `core/notifications/notifications_service.dart`. The `navigateTo()` method switches on `data['type']` from the FCM payload.

| Type | Role | Navigates to |
|---|---|---|
| `new_job` | dj | `/dj/home` → `djQuoteForm` |
| `new_job` | musician | `/instrumentalist/home` → `instrumentalistOfferForm` |
| `another_round` | dj/musician | same as new_job |
| `new_ext_job` | musician | `/instrumentalist/home` → `instrumentalistOfferForm` (biddable job → make an offer; NOT `extJobDetail`, which is the won/fulfillment view) |
| `ext_job_assigned` | dj | `/dj/featured` → `extJobDetail` |
| `ext_job_assigned` | musician | `/instrumentalist/home` → `extJobDetail` |
| `quote_won/lost` | dj | `/dj/home` → `quoteDetail` |
| `offer_won/lost` | musician | `/instrumentalist/home` → `serviceOfferDetail` |
| `chat_message` | dj | `/dj/chat` → `conversationDetail` |
| `chat_message` | musician | `/instrumentalist/chat` → `conversationDetail` |
| `ready_reminder` | dj | `/dj/home` or `/dj/featured` → quote or extJobDetail |
| `ready_reminder` | musician | `/instrumentalist/home` → `serviceOfferDetail` |
| `extra_hours_reminder` | dj | same routing as `ready_reminder` (quote or extJobDetail) |
| `extra_hours_reminder` | musician | `/instrumentalist/home` → `serviceOfferDetail` |
| `contact_customer_reminder` | dj/musician | same routing as `ready_reminder` (deep-links into the job) |
| `send_invoice_reminder` | dj/musician | same routing as `ready_reminder` (deep-links into the job) |
| `chat_unused_reminder` | dj/musician | same routing as `chat_message` (chat tab → `conversationDetail`) |
| `admin_message` | dj | `/dj/profile` → `adminMessages` |
| `admin_message` | musician | `/instrumentalist/profile` → `adminMessages` |
| `custom_notification` | any | no navigation (dismisses) |

**Deep-link `extra` must match the route's expected TYPE, or you get the "Mangler data" screen.**
`NotificationsService.navigateTo` reads `data['role']` as a **String** (`'dj'`/`'musician'`), but several
routes expect a **`MusicianRole` enum** as `state.extra` (they do `if (state.extra is! MusicianRole) →
_MissingRouteDataScreen`, title "Mangler data"). Passing the raw `role` String silently fell through to
that screen — the bug that broke tapping the `admin_message` push (`AppRoutes.adminMessages`). Convert
`role == 'musician' ? MusicianRole.instrumentalist : MusicianRole.dj` before `pushNamed(..., extra:)`.
When adding a deep link, check what the GoRoute builder expects `extra` to be. (`AdminMessagesScreen`
also now has pull-to-refresh + a retry — the `_CenteredScrollable` wrapper makes the loading/error/empty
states pull-refreshable, `RefreshIndicator.onRefresh` invalidates + awaits `adminMessagesProvider`.)

**Foreground notifications:** system banners are suppressed. `inAppNotificationProvider` (StateProvider) holds the current `RemoteMessage?` and drives an in-app banner instead.

**Campaign funnel labeling (`second_wave`).** The out-of-region "second wave" musician campaign (and the internal sax variant) is *sent* with `data.type` = `new_ext_job`/`new_job` (so tap-routing + opt-out are unchanged) but *logged* by the sender under `second_wave_ext_job_sent` / `second_wave_job_sent`. So receive/tap logging MUST run `data['type']` through `NotificationsService.campaignAwareLogType(data, event)` (used in `logReceivedToSupabase`, the `navigateTo` tapped insert, and `main.dart`'s background path) — otherwise the campaign's opens log under the plain type and the funnel reads "sent N, opened 0" even though delivery works. Use `notification_type like 'second_wave_%'` (group by `event`) to measure it.

**`received` logging is iOS-blind.** The background isolate (`_firebaseBackgroundHandler` → `notify-log-received`) only runs on iOS when the APNs payload carries `content-available`, which `sendFcmPush` does NOT set. So `received` events are essentially never logged for backgrounded iOS pushes; `tapped` (via `onMessageOpenedApp`) always logs. Treat **tapped/sent as the open-rate metric**, not received.

**Token registration:** upserted to `DeviceTokens` on app start and after login. Deleted on logout. On iOS, waits for APNs token before registering.

**Gotcha — `_upsertToken` deletes the user's OTHER tokens.** After upserting, `NotificationsService._upsertToken` runs `delete().eq('user_id', userId).neq('token', token)` to clear stale rotated tokens. This means registering a device under user X wipes every other device token X has. Harmless for a normal single-device login, but it's why **impersonation must never register a token** (see below).

## Notification settings screen = the per-type opt-out UI (must mirror the senders)

`notification_settings_screen.dart` renders one toggle per notification the musician can silence.
Turning a toggle off adds its type string(s) to `DeviceTokens.disabled_notification_types`; each
**sending Edge Function** (`web-app/supabase/functions/notify-*`) filters its recipients with
`!(disabled_notification_types ?? []).includes("<type>")`. **The toggle string MUST byte-match the
string the sender checks** or the opt-out silently does nothing. The screen is data-driven
(`_sectionsForRole(isDj)` → `_NotifSection`/`_NotifGroup`); to add/change a toggle, edit that list.

Full opt-out map (verified against the functions), role-scoped:
- both: `new_job`, `chat_message`, `chat_reaction`, `chat_unused_reminder`, `ready_reminder`,
  `extra_hours_reminder`, `contact_customer_reminder`, `send_invoice_reminder`, `admin_message`
- dj-only: `another_round`, `quote_won`/`quote_lost`, `content_record_reminder`/`content_upload_reminder`,
  `content_accepted`/`content_rejected`, `song_request`
- musician-only: `new_ext_job`, `offer_won`/`offer_lost`
- **NOT toggleable (excluded on purpose):** `ext_job_assigned` (`notify-ext-job-assigned`) and
  `custom_notification` (`notify-custom`) — their senders do NOT read `disabled_notification_types`,
  so a toggle would be a lie. If you make either honour opt-out, add it to the screen then.

When adding a NEW notification type, wire the opt-out check into its Edge Function AND add a toggle
here (or it's un-silenceable). The `_toggle` write is guarded by `NotificationsService.isImpersonating`
(see below) — keep that.

## Super-owner impersonation (debug builds only)

To view a production user's app for debugging, the `kDebugMode`-only floating dev tool (`core/widgets/dev_env_banner.dart` — the same bottom-right FAB that switches DB env) has an **"Impersonate"** action that logs in AS any existing user **without a browser or cookie**:

1. POST the target email to the web-app admin endpoint `POST /api/admin/magic/token` (gated by `ADMIN_API_KEY`, read from `EnvConfig.adminApiKey` / `.env.*`). It returns a one-time magic-link **token hash** (`generateLink({type:'magiclink'}).properties.hashed_token`).
2. Establish the session on-device via `supabase.auth.verifyOTP(type: OtpType.magiclink, tokenHash: ...)` (`AuthRemoteDatasource.verifyMagicTokenHash` → `AuthRepositoryImpl.signInWithMagicTokenHash`, which reuses the same `_detectRole` as password login).

**Critical: `NotificationsService.setImpersonating(true)` is set BEFORE `verifyOTP`** so the resulting `signedIn` event skips `registerToken()`. Without this the impersonated (real prod) user's actual phone token would be deleted by the `_upsertToken` cleanup above, silently killing their push. The flag is **persisted** (SharedPreferences, loaded in `main()` before the auth listener subscribes) so a relaunch mid-impersonation still skips registration; `registerToken`/`_upsertToken`/`removeToken` all hard-return when it's set. After establishing the session the FAB calls `RestartWidget.restartApp` so the router cold-resolves into the impersonated user's home; the panel then shows "Logget ind som <email>" + a "Log ud" button (`signOut` clears the flag). The **notification-settings toggle** (`notification_settings_screen.dart`, `_toggle`) also bails when `isImpersonating` — it does `UPDATE DeviceTokens.disabled_notification_types WHERE user_id = <current>`, which would hit the real user's device rows. Rule of thumb: **any new code that writes `DeviceTokens` for the current user must guard on `NotificationsService.isImpersonating`.** Points the app at prod, so writes are real — view only. To enable: set `ADMIN_API_KEY` in the mobile `.env.<env>` to match **that env's deployed web-app** key (e.g. the Vercel prod value for `.env.prod`).

## Job-content fields shown to musicians (what they may/may not see)

Musicians must see **all** customer-facing job content; never `internal_notes`/`internal_note` (admin-only — these are NOT parsed into any mobile model). The relevant fields per source:
- **Jobs:** `lead_request` ("Kundens ønske") + `additional_information` ("Yderligere information") + `musician_special_request` ("Særligt ønske til musikeren").
- **ExtJobs:** `notes` ("Noter") + `musician_special_request`.

A musician can reach an ext job via **two** rendering paths — keep field display in sync across both:
1. **Make an offer → `instrumentalist_offer_form_screen.dart`.** Reached from the browse feed AND from a
   **`new_ext_job` notification** (a new biddable ext job). Both map `ExtJobModel.toJobEntity()` → a `Job`
   (with `isExtJob`/`extJobId` set, **`leadRequest` = ExtJobs.notes**, `musicianSpecialRequest` carried
   over). So this one screen renders both real Jobs and ext-jobs-as-Jobs; it must show `leadRequest`,
   `additionalInformation`, `musicianSpecialRequest`. **`new_ext_job` must route here, NOT to
   `ExtJobDetailScreen`** — the musician has not won yet (routing to the won view showed the customer's
   contact details and a "kontakt kunden" flow for a job they hadn't won; a real bug that was fixed).
2. **`ext_job_assigned` notification → `ExtJobDetailScreen`** (takes a real `ExtJob` entity) — the WON /
   assigned fulfillment view (customer contact, process tracker). Shows `notes` + `musicianSpecialRequest`.
   Note: `ExtJobModel` parses `musician_special_request` but `toEntity()` must explicitly pass it through
   (it was previously dropped).

## Login must not flash the role-select / onboarding screen

The GoRouter `redirect` in `app.dart` gates on `_onboardingNotifier.resolved` — a flag that is only true once we actually know the session's role + onboarding status. On `signIn()`, Supabase fires the `signedIn` event (→ router refresh) **before** `RoleCache.save(role)` runs, so for a moment the user is authenticated with `RoleCache.role == null`; without the gate the redirect sent them to `/profile-setup` (the "DJ or musician?" screen) for ~0.5s before bouncing home. Rule: **after any `RoleCache.save(...)`, `await initOnboardingStatus()` before navigating** (see `login_screen.dart` and all four save sites in `profile_setup_screen.dart`) so `resolved` is set and the redirect routes correctly (home vs `/onboarding`). While `resolved` is false the redirect returns `null` (stay put) instead of routing to setup/onboarding. `initOnboardingStatus()` is also awaited in `main()` before `runApp`, so cold-start is already resolved.

## Registration (mobile signup)

Mobile can create brand-new accounts (`SignupScreen`, route `AppRoutes.signup`, reached from the
"Opret konto" link on `login_screen.dart`). Key facts:

- **It's pure Supabase Auth client-side** (`AuthRemoteDatasource.signUpWithPassword` → `auth.signUp`),
  exactly like `signIn` — there is **no web-app registration endpoint**; account creation carries no
  business logic, so it does not need to route through the web API.
- **Email confirmation is OFF** (`web-app/supabase/config.toml` `enable_confirmations = false`), so
  `signUp` returns an **active session immediately**. The repo still returns a `SignUpResult` so the
  screen handles both: `signedInNeedsSetup` (the normal path) and `needsEmailConfirmation` (a
  "Tjek din mail" fallback, only hit if confirmations get enabled in some env).
- **Role is NOT chosen at signup** (unlike web, which has separate `/dj/login/register` vs
  `/instrumentalist/login/register` pages). A new mobile user has a session but no role, so signup
  just `goNamed(AppRoutes.profileSetup)` — the **existing** `profile-setup` (role select + create
  `DjInfos`/`Musicians`) → `onboarding` path takes over unchanged. This is the same state as the
  `NeedsProfileSetupException` branch in `login_screen`.
- **`/signup` MUST be in the router's `isPublicRoute` list** (`app.dart`). Without it, the moment the
  session appears the onboarding gate (Gate 4) would bounce the user to `/onboarding` before any
  profile exists. `/profile-setup` is already public for the same reason; do not "tidy" either out.

## "Udvalgte jobs" must filter `sent` out — `djExtJobsProvider` deliberately includes it

`djExtJobsProvider` / `fetchDjExtJobs` (`jobs_remote_datasource.dart`) returns ext jobs with status
`sent`/`closed`/`customer_contacted`/`ready_for_billing` — **`sent` is intentionally included** because
the date-collision guard (`dj_quote_form_screen`, `jobs_shell_screen`) treats a `sent` assigned ext job
as a confirmed booking that blocks bidding on that date. So the provider is shared between two consumers
with different needs. The **"Udvalgte jobs" screen (`featured_jobs_screen.dart`) must filter the list
itself** to `_kVisibleExtJobStatuses` (`closed`/`reopened`/`customer_contacted`/`ready_for_billing`),
mirroring web's `VISIBLE_STATUSES` in `dj/udvalgte-jobs/page.tsx`. Without that filter an
assigned-but-still-`sent` ext job (not yet a real booking) leaks into the list — the bug fixed here.
Do NOT "fix" this by dropping `sent` at the datasource: that silently breaks the date-collision guard.

## "Fast kunde" (recurring-customer) badge on Udvalgte jobs — name comes from the web API, NOT Supabase

The "Udvalgte jobs" list (`featured_jobs_screen.dart`) + the ext-job detail (`ext_job_detail_screen.dart`)
show a purple **"Fast kunde · <navn>"** pill (`shared/widgets/recurring_customer_badge.dart`) when the
assigned ext job belongs to a recurring (venue) customer, so the DJ/musician sees they're playing for a
fixed customer. Mirrors the web app's `dj/udvalgte-jobs` badge.

- **The venue name is NOT a column mobile can read.** `ExtJobs.recurring_customer_id` is a column, but the
  name lives on `RecurringCustomers`, which is **RLS-readable only by service_role/admin** — a DJ-role user
  (mobile's own session) gets nothing from a direct read or a PostgREST embed. So the name is resolved
  **server-side** by the DJ-scoped web endpoint `GET /api/internal-dj/ext-jobs?dj_id=<uid>` (it maps
  `recurring_customer_id → account_name` with the service-role client and returns `recurring_customer_name`
  per row). This is the same endpoint web's `useInternalDjExtJobs` uses.
- **Wiring:** `djExtJobRecurringNamesProvider` (`jobs_provider.dart`) calls
  `JobsRepository.fetchDjExtJobRecurringNames` → datasource `_webApiGet('/api/internal-dj/ext-jobs?dj_id=…')`
  and returns a `Map<int,String>` keyed by **ext job id** (only ids that belong to a recurring customer are
  in the map, so a lookup miss = "not a fixed customer"). The screens look up `map[extJob.id]`.
- **Do NOT route this through `djExtJobsProvider`.** That provider's `fetchDjExtJobs` is a **direct** Supabase
  read that intentionally includes `sent` (the date-collision guard needs it) and is shared with that guard;
  the web endpoint returns only `closed`/`customer_contacted`/`ready_for_billing` and would break the guard.
  The names map is a **separate, additive** provider so the shared list/guard path is untouched.
- **Saxophonists get the badge too, via a SEPARATE endpoint.** The DJ endpoint checks `DjInfos`, so it 4xx's
  for a musician. The sax path uses `GET /api/internal-musician/ext-job-recurring-names` (auth-derived) →
  `musicianExtJobRecurringNamesProvider`. It resolves names for **every recurring ext job a sax can see on a
  card** (role_type musician/dj_and_musician in open/sent/reopened/closed/customer_contacted/ready_for_billing),
  so the **`RecurringCustomerBadge` shows on ALL sax cards**: the feed `JobCard` (musician view) + `ServiceOfferCard`
  (sent/won/lost), wired in `jobs_shell_screen` (each tab watches the provider, passes `recurringName:
  names[job.extJobId]` / `names[offer.extJobId]`), plus the detail screens. Because `ExtJobDetailScreen` is
  **shared** by DJs and musicians, it **coalesces both maps** (`djNames[id] ?? musicianNames[id]`) — each is
  empty for the other role, so watching both is safe. The DJ-only "Udvalgte jobs" **list**
  (`featured_jobs_screen`) still watches only the DJ map (that route is DJ-only). Web parity:
  `MusicianJobCard` + `ServiceOfferCard` fed by `useMusicianExtJobRecurringNames` in `instrumentalist/page.tsx`.

## "🎶 Til festen" partner-booking card (`PartnerEventWishesCard`)

`shared/widgets/partner_event_wishes_card.dart` — a purple card of the couple-facing partner-booking
details (address_as, guest_age, first_dance_song, spotify_playlist_url, special_conditions, early_setup
+ a sax subsection), mirroring the web `src/components/PartnerEventWishesCard.tsx`. Self-hides when
nothing is set. Kept as the **LAST card** on both screens. Shown to:
- **DJs** on `featured_jobs/.../ext_job_detail_screen.dart` (from the `ExtJob` entity) — the full card;
  the **playliste** value has a **Kopiér** button (`copyable: true` → Clipboard + "Link kopieret" toast).
- **Won saxophonists** on `jobs/.../service_offer_detail_screen.dart` `_wonBody` (from `offer.job`) with
  **`musicianView: true`** — which renders ONLY "Sådan omtales parret" + "Særlige forhold" (the DJ-oriented
  playliste/brudevals/alder/opsætning + the sax subsection are hidden). Keep the web `musicianView` prop in sync.
- **Sax type (Party/Lounge) is shown separately on EVERY sax offer** (sent + won + lost) via a `_MetaRow`
  in `_JobHeroCard` (`service_offer_detail_screen`), independent of the partner "Til festen" card. Web
  already shows it via `ExtJobInfo`.

**The data plumbing was the work:** these are ExtJobs Phase-2 columns that the models didn't carry.
Added to BOTH entity/model layers: `ExtJob`/`ExtJobModel` gained `address_as, guest_age,
first_dance_song, spotify_playlist_url, special_conditions, early_setup` (+ surfaced the already-parsed
`sax_type`/`musician_start_time` on the entity — `toEntity()` had been dropping them), and `Job`/`JobModel`
gained the same six. **`ExtJobModel.toJobModel()` must forward all six** or the won-sax view (which sees an
ext job as a `Job` via that mapper) shows an empty card. When you add another ExtJobs display column,
thread it through: `ExtJobModel.fromJson` + `toEntity` (DJ path) AND `toJobModel` + `JobModel.fromJson`
(sax offer path).

## Chat has TWO independent message-bubble implementations (no shared widget)

The two chat UIs do **not** share a bubble widget — a change to one must be mirrored by hand:
- **Normal + musician support chat:** `conversation_detail_screen.dart` → private `_MessageBubble`
  (system messages return early with a centered `Text`, so they get no long-press). Long-press fires
  `_showReactionBar(Offset, ChatMessage)` — a floating **OverlayEntry** bar (emoji quick-reactions +
  reply + **copy**).
- **Admin-side support thread:** `admin_support_thread_screen.dart` → private `_Bubble`. Long-press
  fires `_showReactionBar(ChatMessage)` — a **showModalBottomSheet** (emoji row + a "Kopiér besked"
  ListTile).

Both read the body from `ChatMessage.message` and copy via `Clipboard.setData` (import
`package:flutter/services.dart`; the conversation file already had it, the support file did not).
Copy is gated on `message.isNotEmpty` so image-only bubbles don't offer it.

## Chat keyboard avoidance: use the Scaffold default, do NOT hand-roll `viewInsets`

`conversation_detail_screen.dart` (musician + support chat) must keep the Scaffold's
**default `resizeToAvoidBottomInset: true`** and lay the body out as
`Column[Expanded(list), …banners, ChatMessageInput]` — the composer pins itself above the
keyboard because the Scaffold shrinks the body. The admin side
(`admin_support_thread_screen.dart`) uses this exact default and works. An earlier version set
`resizeToAvoidBottomInset: false` and manually padded the body by
`MediaQuery.of(context).viewInsets.bottom`, with a comment claiming the Scaffold's auto-resize is
"unreliable inside the MaterialApp.builder Stack." That premise is **wrong** (nothing above the
router strips `viewInsets`; the admin thread proves default resize works in the same Stack) and the
manual override left the input hidden behind the keyboard. Do not reintroduce it. Note the global
`_KeyboardDismissBar` (`app.dart`, a "Luk" bar at `bottom: viewInsets.bottom`) is already suppressed
on this screen via `suppressKeyboardDismissBarProvider` (set true in `initState`'s post-frame,
false in `dispose`) so it can't overlay the composer — keep that.

## Notification center (in-app feed) — `features/notifications/`

Facebook-style feed of every push the user received, reached via a **bell icon in the Profile tab
app bar, top-right** (`NotificationBell` in `profile_screen.dart` `actions`; the dark-mode toggle
sits in `leading`, top-left) → route `AppRoutes.notifications` → `NotificationsScreen` (All/Ulæste
filter, Nye/Tidligere grouping, per-type icon, unread dot).

- **Data source is the `UserNotifications` table** (web-app migration `20260713130000`), written
  **server-side** by the `notify-*` Edge Functions at send time — NOT by client received-logging
  (which is iOS-blind, see above). The mobile side only reads + marks read.
- **Tap reuses `NotificationsService.navigateTo(data, router)`** — the stored `data` jsonb is the
  exact FCM payload, so the feed replays the identical deep-link routing. No per-type nav logic was
  added; the tile just calls `navigateTo(n.data, ref.read(routerProvider))`.
- **`notificationsProvider`** (`StateNotifierProvider`, NOT autoDispose so the badge survives) fetches
  + subscribes to Realtime on `UserNotifications` filtered by `user_id` (Realtime lives in the
  provider, per the rule), re-fetches on resume, and does optimistic mark-read.
  `unreadNotificationCountProvider` drives the bell badge.
- **No backfill** — the feed only fills from notifications sent after deploy (the table didn't exist
  before). Tapping a seeded/old notification only navigates if the referenced row still exists.
- **One unread count across three surfaces, all reading `unreadNotificationCountProvider`:** the OS
  **app-icon badge** (`app_badge_plus`, set by `NotificationsNotifier._emit` on every change +
  cleared on logout in `app.dart`), the **Profile bottom-nav tab badge** (`main_shell.dart` — this
  replaced the old `unreadAdminMessageCountProvider` badge, so the Profile tab now counts
  notifications, not admin messages; admin messages still surface as `admin_message` rows in the
  feed), and the **profile app-bar bell**. Keep all three on this one provider so the number is
  traceable icon → tab → bell.
- **Tap from the in-app list keeps the back stack:** the tile calls
  `NotificationsService.navigateTo(data, router, keepCurrentStack: true)`. That flag makes the
  internal `goTab()` skip the `router.go(<shell tab>)` reset, so the detail pushes ON TOP of the
  notifications screen and Back returns there (a real push / foreground banner passes the default
  `false`, still resetting to the tab so Back → home when the app opens fresh).

## Admin support search (mobile Support tab) mirrors the admin tool

The mobile admin **Support tab** (`chat_screen.dart` `_AdminSupportTab`) has the same search as the web
admin tool's support inbox — search logic lives **server-side in the web-app** (source of truth):
- **Cross-conversation search**: `GET /api/chat/support/admin/threads?q=` searches user **name + message
  content** and returns per-thread `matches` (+ `match_count`), mirroring the admin tool's
  `admin/app/api/support/route.ts`. Mobile: `AdminSupportDatasource.fetchThreads({q})` +
  `adminSupportSearchProvider(query)` (a debounced search box; empty query falls back to the realtime
  `adminSupportThreadsProvider`). The list shows highlighted match snippets under each name; tapping a
  snippet opens the thread at that message.
- **Jump-to-message**: the thread screen (`admin_support_thread_screen.dart`) takes
  `AdminSupportThreadArgs(thread, initialMessageId)` (router accepts the bare thread too for back-compat)
  and scrolls+flashes that message. Reliable scroll uses a **non-lazy `ListView` + a `GlobalKey` per
  message + `Scrollable.ensureVisible`** (support threads are small) — that's the workaround for "lazy
  ListView can't scroll to an arbitrary off-screen message"; do NOT switch this list back to
  `ListView.builder` or jump breaks.
- **In-thread search**: app-bar search field → highlights matches in bubbles (`_AdminFormattedText`
  gained a `highlight` param), with a **`n/m` counter + up/down** step-through (`_gotoMatch`, wraps).
  This goes beyond the admin tool (which has no in-thread stepper).

## DSButton gotchas (design system)

- **`secondary`/`tertiary` foreground must NOT be `brand.primary`.** `brand.primary` (`#D1F366` lime) is a *background* token whose readable text pair is `brand.onPrimary` (dark). On a tinted bg (secondary = `brand.primary @ 10%`) the correct, theme-aware text token is **`brand.primaryActive`** (commented "text on tinted bg"). Using `brand.primary` as fg renders light-lime-on-light-lime (invisible). Same applies to `DSIconButton`.
- **Never animate `AnimatedContainer.constraints` between bounded and unbounded.** A button that toggles `expand` (shrink-wrap ↔ full-width) or `size` while its element is reused throws *"Cannot interpolate between finite and unbounded constraints"* (a 1-frame flash + red screen). `DSButton` applies `expand` via an outer `SizedBox(width: infinity)` so the AnimatedContainer's own constraints never change. Keep it that way.

## Floating chat bubble (mirrors web `FloatingChatButton`)

`shared/widgets/chat_bubble_fab.dart` (`ChatBubbleFab`) is a bottom-right floating "Beskeder" pill (paper-plane icon + overlapping partner/current-user avatars + unread badge) that opens the conversation. Pass `jobId` **or** `extJobId`; it finds the conversation from `conversationsProvider` and **self-hides** (`SizedBox.shrink()`) when none exists, so it's safe to drop into a `Stack` unconditionally. Mount it via `Positioned.fill` → `SafeArea` → `Align(bottomRight)` over a scrollable body, and add ~96px bottom padding to the scroll content so it never covers the last card. Used on the musician won-offer view (`service_offer_detail_screen.dart`). The inline `ConversationCard` (DJ-side chat list entry) still exists separately and is now configurable via `title` / `showPartnerName` / `compact`. Reminder: chats only exist on **won** internal jobs (or assigned ext jobs) with an **internal** DJ — see the embedding note below.

## Embedding DjInfos: `Quotes.dj_id` does NOT FK to DjInfos

`Quotes.dj_id` and `ServiceOffers`/`Musicians` ids FK to **`auth.users`**, and `DjInfos.id` also FKs to `auth.users` — so there is **no direct FK between `Quotes` and `DjInfos`**. PostgREST embeds need a declared FK, so `from('Quotes').select('dj_id, dj:DjInfos(...)')` fails with **PGRST200** ("could not find a relationship"). In Riverpod `.when()` widgets the error branch often renders `SizedBox.shrink()`, so this surfaces as a **silently missing section**, not a crash (this is exactly what hid the "DJ på jobbet" block on the musician won-offer view). To get a DJ's profile from a quote: fetch `dj_id` from `Quotes`, then query `DjInfos` by `id` separately (see `fetchWonDjInfoForJob`). Embedding DjInfos only works where the column genuinely FKs to it, e.g. `Conversations.dj_id → DjInfos.id` (chat uses the hint `DjInfos!Conversations_dj_id_fkey`). Note a won quote can be an **external DJ** (`dj_id` null, `ext_dj_id → ExtDjs`); external-DJ wins get no in-app profile and no chat.

## Song request QR (per-DJ, DJ-only)

The song-request QR is **per-DJ**, shown on the profile (`profile_screen.dart`, DJ-only menu item → `widgets/song_request_qr_dialog.dart`). It encodes `DjProfile.songRequestToken` (`DjInfos.song_request_token`); the web backend resolves it to the DJ's next upcoming event at scan time.

- The old **per-event** QR on `song_requests_screen.dart` was removed (that screen now only lists requests). Its call sites in `quote_detail_screen.dart` and `ext_job_detail_screen.dart` no longer pass `songRequestToken`.
- `Job`/`ExtJob` models still parse `song_request_token`, but it is no longer used in the UI.

## Sax offer detail (`service_offer_detail_screen.dart`) — two gaps that were fixed

- **`musicianSpecialRequest` text is rendered inside `_JobHeroCard`** (star + "Særligt ønske til
  musikeren", warning color — mirrors `ext_job_detail_screen` / `job_detail_screen`). Because
  `_JobHeroCard` shows in **both** `_sentBody` and `_wonBody`, this is the single place the sax sees the
  request across the offer lifecycle. Do NOT rely on `_SpecialRequestFeeSection` to show it — that
  section only renders the **fee** UI, and it (plus the whole "special request" area of `_wonBody`) is
  won-only, so before this the request text was invisible on the pending/`sent` offer. The compact
  `ServiceOfferCard` is a summary and deliberately does not show it (matches web).
- **Extra-hours window is `event date 00:00 … event date + 2 days 23:59:59` — enforce BOTH bounds.**
  `_MusicianExtraHoursSection._isWithinExtraHoursWindow` previously checked only the lower bound
  ("never before the event"), so a job played weeks ago still showed the "Ekstra timer" input; the
  server (`service-offer/[offerId]/extra-hours`) rejected the save, but the UI wrongly offered it. It
  now mirrors the server (`eventDate <= today <= eventDate + 2`) and the DJ screens
  (`quote_detail_screen` / `ext_job_detail_screen`, which already had the full window). Keep all three
  mobile windows + the server route in sync. (Business rule: `business-rules.md` — extra hours only on
  the event date through 2 days after.)

## Profile media: uploads MUST generate a video thumbnail + display via CachedNetworkImage

Two long-standing bugs, fixed by making the **profile** upload path match the job-content path (and the
web-app source of truth `useFiles.createFile`):
- **Profile/performance videos had no poster.** `profile_remote_datasource.uploadFile` inserted only the
  video `UserFiles` row and never generated a `type='thumbnail'` row, so every profile/common video
  showed the grey `LucideIcons.video` fallback (job-content worked because it DOES generate one). Fixed:
  `uploadFile` now, for `profileVideo`/`commonVideo`, generates a JPEG via `VideoThumbnail.thumbnailData`,
  uploads it (`type=thumbnail` signed URL), and inserts a companion `type='thumbnail'` row with
  `thumbnail_video_id` = the video row's id (mirrors `job_content_remote_datasource._uploadThumbnail`).
  The resolution side (`thumbnail_video_id → url` map in `media_screen`/`onboarding`/`profile_preview`)
  was already correct — the thumbnail rows just never existed.
- **A just-uploaded profile image flashed the error icon.** `media_screen.dart` + `onboarding_screen.dart`
  used `Image.network` (no disk cache, no retry), so the freshly-PUT S3 object (not readable for a split
  second) hit the `errorBuilder` and didn't recover. Switched to **`CachedNetworkImage`** (like
  `my_content_screen`/`profile_preview_screen`), which retries + caches only successful responses. Use
  `CachedNetworkImage` for any newly-uploaded S3 media, never `Image.network`.

## DJ content capture (feature 52)

Step 5 of the DJ job process: short clips (max 15s, 9:16) recorded per job. `quote_detail_screen` + `ext_job_detail_screen` show a reminder/CTA (`features/jobs/presentation/widgets/job_content_section.dart`) once `djReadyConfirmedAt != null`; tapping it opens **`MyContentScreen`** (`AppRoutes.myContent`, profile menu "Mit content", DJ-only) scoped to that job via a `JobContentKey` `extra`. That screen is the library of **all** the DJ's clips (labelled by job) + the scoped uploader + delete. Data: `job_content_remote_datasource.dart` (`fetchMyJobContent`) + `job_content_provider.dart` (`myJobContentProvider`).

- **Uploads go to AWS S3, not Supabase Storage** (the tech-stack table above is misleading for media). Flow: `GET /api/files/signed-url` → `PUT` to S3 → `POST /api/files/job-content` (verifies the DJ owns the job server-side). Do NOT direct-insert `UserFiles` for `job_content` — that bypasses ownership checks (same spirit as the Quotes/Jobs rules below).
- 15s / 9:16 is hard-validated client-side via `validateContentVideo` (`video_player` duration + aspectRatio) — there is no server-side ffprobe.
- A thumbnail is generated on upload via `video_thumbnail` and uploaded as a separate `thumbnail` row, so web + admin (and the in-app list) show a real preview.
- Notification types `content_record_reminder` / `content_upload_reminder` are DJ-only and routed exactly like `ready_reminder` in `notifications_service.dart`.

## Copyable "intro message to the customer" on won jobs (mirrors web-app)

The won-job contact section shows a ready-to-send Danish intro message with a "Kopiér besked" button, to
make DJs/saxes contact the customer within 24h. Text = `features/jobs/domain/customer_intro_message.dart`
`buildCustomerIntroMessage({leadName, role, performerName})` — **byte-identical to web-app
`web-app/src/helpers/customerIntroMessage.ts`; change both together** (emojis included). UI =
`features/jobs/presentation/widgets/copy_intro_message_card.dart`, placed in the "Kundekontakt" section
of `quote_detail_screen.dart` (DJ: role `'DJ'`, name from `djProfileProvider.companyOrDjName`) and
`service_offer_detail_screen.dart` (sax: role `'saxofonist'`, name from `musicianProfileProvider.fullName`),
gated on not-yet-contacted. (`offer.musicianFullName` is NOT reliably populated in the offer detail — the
service-offers query doesn't embed the musician — so read the name from `musicianProfileProvider`.)

### "Send besked" opens the SMS composer — and CANNOT be tested in the iOS Simulator

The card's primary action builds `sms:<number>?body=<encoded>` and `launchUrl`s it, opening the OS
composer with recipient + message prefilled. Non-obvious facts, all learned the hard way:

- **The iOS Simulator cannot verify this.** Its Messages app has no contacts backend, so the recipient
  chip **spins forever** and **tapping it crashes MobileSMS** (`assembleContactAvatarsForRecipient:` →
  `setPhoneNumbers:` → `CNMultiValuePropertyDescription assertValueType:` → SIGABRT). That is Apple's
  app dying, not ours — the body prefills correctly and the URL is fine. url_launcher's README says the
  same of `tel:`/`mailto:` ("iOS simulators don't have a default email or phone apps installed").
  **Only a real device tells you anything here.** Do not "fix" the URL based on Simulator behaviour.
- **`?body=` is correct on iOS; do NOT change it to `&body=`.** Widespread advice says iOS needs
  `&body=`. That advice is from the iOS 8–11 era. Verified on **iOS 26: `?body=` prefills correctly**,
  and `?` is also the RFC 5724 form Android wants — so one string works on both and no platform
  conditional is needed. Re-test body prefill on a real device before ever touching this.
- **Build the URL by hand + `Uri.encodeComponent`.** Not `Uri(queryParameters:)` (form-encodes spaces
  as `+`, which the composer shows literally) and not `Uri.encodeFull` (doesn't escape `?`, `&`, `#`).
- **`lead_phone_number` is `text NOT NULL` with NO format constraint**, filled from the WordPress
  customer forms — it holds "ikke oplyst", "-", etc. as often as a number. Naive digit-stripping turns
  those into `""`, producing `sms:?body=...`: a composer with **no recipient**, i.e. the same
  forever-spinning chip. Always gate the action on **`core/utils/phone_utils.dart` →
  `dialablePhoneNumber(raw)`** (returns digits + optional leading `+`, or null when it isn't a real
  number; ≥8 digits, since Danish numbers are 8). Never let a "is it non-blank" check and the strip
  disagree about whether there is a recipient.
- **No `canLaunchUrl` guard on purpose** — that would need `sms` in `LSApplicationQueriesSchemes`,
  which this app does not declare (`tel:` is launched unchecked the same way in `sick_disclaimer.dart`).
  It tries, and falls back to copying the message + an info toast, so it never dead-ends.

## Saxophonist same-date offers are TIME-AWARE (multiple open offers allowed)

A musician may hold **several open offers on one date**. Two same-date jobs can BOTH be won only if the
gap between one's END and the next's START is **≥ 3h** (`saxMinGapMinutes`=180). Winning one loses the
musician's other same-date open offers that conflict (gap < 3h). This is enforced server-side (DB
trigger + the web `service-offer/[offerId]/choose` cascade — mobile does NOT reimplement it); the Dart
side is UI mirroring only.

- **Canonical Dart helper:** `features/jobs/domain/sax_offer_conflict.dart` (`saxBookingsConflict`,
  `saxEndTime`, `saxDateKey`, `SaxConflictQuery`). Mirrors web `saxOfferConflict.ts` + DB
  `sax_bookings_conflict` EXACTLY — keep in sync. Any missing time ⇒ conservative conflict.
- **The conflict window is the MUSICIAN's, not the DJ's.** The sax plays `[musician_start_time,
  musician_start_time + requested_musician_hours]` — **NOT** the job's `time_start`/`time_end`
  (`start_time`/`end_time`), which are the **DJ** window (a much longer span on a duo job). Every
  booking fed to `saxBookingsConflict` is built from `musicianStartTime` + `saxEndTime(musicianStartTime,
  requestedMusicianHours)`; a null musician start time or hours ⇒ null end ⇒ conservative conflict.
  Fixed in migration `20260707000000_sax_conflict_use_musician_window.sql` (+ the web helpers +
  these Dart call sites). The earlier `20260706000003` keyed on the DJ window and was wrong for sax.
- **Submission gate = WON conflict only.** `JobsRemoteDatasource.hasDateConflict(userId, {date,startTime,
  endTime})` queries **`status='won'`** offers and compares the musician windows, so open offers no
  longer block bidding. `dateConflictProvider` takes a `SaxConflictQuery(date,startTime,endTime)`; the
  offer form (`instrumentalist_offer_form_screen.dart`) passes the musician window (`job.musicianStartTime`
  + `saxEndTime(...)`). The feed grey-out (`jobs_provider` `isOccupied`) is likewise won-only +
  musician-window (the won offers' `job.musicianStartTime`/`requestedMusicianHours`, present because
  service-offer selects embed `job:Jobs(*)`/`ext_job:ExtJobs(*)`).
- **Multi-offer notice on the offer form (informational, never blocks).** Because the feature lets a
  sax hold several offers on one date, `instrumentalist_offer_form_screen.dart` shows `_MultiOfferNotice`
  when they already hold a `sent`/`won` offer on the **same calendar date** (excluding this job). It
  lists each existing same-date offer (event + `kl. start–end`) tagged compatible (≥3h ⇒ "begge kan
  vindes", success) or conflicting (<3h ⇒ "kun ét kan vindes", danger), and spells out the two rules:
  (a) winning two < 3h apart auto-sets the other to "tabt"; (b) when both can be won it's the sax's own
  responsibility not to double-book. Conflict per row is computed with the same `saxBookingsConflict`
  helper (musician window). This is **separate** from the WON-conflict block below — the notice does NOT
  disable "Send tilbud" (it only shows in the `!hasConflict` path). Web has no equivalent yet (web only
  has the won-conflict block-card), so this is a mobile-only UX addition to mirror back to web later.
- This is distinct from the DJ `date_collision.dart` (Quotes) rule below, which is unchanged.

## Date-collision guard (no double-booking a date)

A DJ may not bid on a date where they already have a won quote (or 2 pending quotes, or a confirmed external job). The rule mirrors the web `collidingQuote` helper and now lives in **`lib/features/jobs/domain/date_collision.dart`** (`isDateColliding` → bool for the job list; `dateCollisionMessage` → Danish reason for the form banner). Used in two places: the job list (`jobs_shell_screen.dart` dims the card + nulls `onTap`) **and** the DJ quote form (`dj_quote_form_screen.dart` shows a `_CollisionBanner` + disables submit). The form must guard independently because it's reachable via **push deep-link**, bypassing the list. This is a client mirror only — the **authoritative** enforcement is server-side in the web `POST /api/jobs/[job_id]/quotes` route (returns 409, surfaced via the submit-error toast). Keep all three (web helper, mobile helper, both screens) in sync.

## "Nye jobs" empty state (filters too strict vs genuinely none)

`_DjNewJobsTab` (`jobs_shell_screen.dart`) shows a smart empty state when the visible list is empty: if `newDjJobsProvider` (the **unfiltered** server list) still has jobs, the DJ's own `DjJobFilters` are hiding them → "Ingen jobs matcher dine filtre" with a **Justér filtre** CTA (→ `AppRoutes.djJobFilters`, `extra: djId` from `djProfileProvider`) + a one-tap **Slå filtre fra** (`djFiltersEnabledProvider.state = false`). If the raw list is also empty, it's genuinely none → softer "Vi giver dig besked" copy. The reusable `EmptyJobsView` now takes optional `title`/`actionLabel`/`onAction`/`secondaryLabel`/`onSecondary`. Web mirror: `web-app/src/app/dj/page.tsx` `NewJobsEmptyState`, driven by `useUnbidJobsFromMyRegions(false)` (unfiltered) vs the filtered list.

## DJ job-length filter (`minHours` / `maxHours`)

Mirrors the web app (source of truth: `web-app/src/helpers/djJobFilters.ts` +
`jobDurationHours.ts`; migration `20260729000000`). A DJ sets a 1–12h range in
`dj_job_filters_screen.dart`; jobs outside it are hidden from the feed and suppressed from
push/email server-side.

- **Duration is derived from `time_start`/`time_end`, never stored.** Dart mirror =
  `features/jobs/domain/job_duration.dart` — **byte-for-byte with the TS helper, change both
  together** (both have the same test suite; `test/features/jobs/job_duration_test.dart`).
- **⚠️ DJ gigs run past midnight: `21:00 -> 02:00` is 5h, not -19h.** A naive subtraction breaks
  the filter for most real jobs, in the direction that looks like "the filter does nothing".
  `timeEnd <= timeStart` ⇒ +24h.
- The comparison uses the **decimal** duration (5.5h is excluded by `maxHours = 5`), and an
  unparseable duration is **never** excluded.
- **Applied twice on purpose, same as the other DJ filters:** the server
  (`GET /api/dj/biddable-jobs` → `selectBiddableJobsForDj`) already excludes them, and
  `_isJobExcludedByFilters` in `jobs_provider.dart` re-applies client-side so the instant
  "Filtre til/fra" pill works with no round trip.
- `DjJobFiltersModel.toJson` is the upsert payload and is hand-listed — a field missing there
  saves with no error then reverts on reload.
- **The length is shown on the DJ card ONLY — never on a musician card.** `job_card.dart` is shared,
  so the `isMusicianView` branch uses plain `job.timeDisplay` and only the `else` (DJ) branch uses
  `Job.timeDisplayWithDuration` ("21.00 - 02.00 (5 timer)"). Job length is a **DJ** concept: it is
  what the DJ-only `DjJobFilters` hours filter acts on, and it describes the DJ's window. A
  saxophonist works their own window (`musician_start_time` + `requested_musician_hours`), so
  printing the DJ's total next to "Saxofonist: 21.00" reads as if it were the sax's own hours.
  On the DJ side it earns its place: without it, jobs vanish from the feed with no on-screen reason.
  Web has the same split for free — the DJ feed uses `JobCard` (has the length) and the musician
  feed uses `MusicianJobCard` (does not). The shared `OverviewJobsCalendar` is safe because the
  musician calendar only ever populates `musicianJob`/`musicianExtJob`, which route to
  `MusicianJobCard`; if you ever make it populate `job`, musicians would start seeing the length.
- Note mobile's `DjJobFilters` entity is still a **partial** mirror — it has no `minAge`/`maxAge`,
  which web's filter shape does have (web's form doesn't expose them either, but its API does).

## Saxophonist job filters (MusicianJobFilters) — separate from DJ filters

Saxophonists have their own job filters, mirroring the DJ ones but scoped to **regions + sax type
(`sax_type` = `'lounge'`/`'party'`, NOT the generic `event_type`)**. Web-app is the source of truth
(`web-app/src/helpers/musicianJobFilters.ts` + `MusicianJobFilters` table, keyed to `Musicians`, columns
`excluded_regions` + `excluded_sax_types`). The mobile pieces:
- **Screen:** `musician_job_filters_screen.dart` (Regioner + Lounge/Party chips), reached from the profile
  menu **only for `MusicianRole.instrumentalist`** → route `AppRoutes.musicianJobFilters`
  (`/instrumentalist/job-filters`, `extra: musicianId` from `musicianProfileProvider`).
- **Data:** `MusicianJobFilters` entity/model + `fetch/saveMusicianJobFilters` on the profile datasource
  (direct Supabase upsert `onConflict: 'musician_id'`, exactly like DJ filters — a per-user preference,
  no web-API round-trip) + `musicianJobFiltersProvider` / `saveMusicianJobFiltersProvider`.
- **Feed:** `filteredInstrumentalistJobsProvider` wraps `combinedInstrumentalistJobsProvider` and drops
  jobs whose `region`/`saxType` are excluded, gated by `musicianFiltersEnabledProvider` (the
  `_MusicianFilterTogglePill` "Filtre til/fra" in the jobs-shell appbar, both list + calendar modes).
  Mirror of `filteredDjJobsProvider` + `djFiltersEnabledProvider`. Notifications/emails are suppressed
  server-side by `GET /api/musicians/available` (no client involvement).

## Customer decision-window countdown is ONE shared widget (normal jobs + ext jobs)

`features/jobs/presentation/widgets/customer_deadline_banner.dart` (`CustomerDeadlineBanner`, takes a
`DateTime? deadline`) is the single countdown banner used by **both** normal jobs and ext jobs, on
`quote_detail_screen`/`service_offer_detail_screen` (normal) and `ext_job_detail_screen` +
`service_offer_detail_screen` (ext). Do NOT reintroduce a bespoke ext-job banner — mirror the web
decision to reuse the normal-job widget.

Two non-obvious wiring facts:
- **`ExtJob.decisionDeadline` and `Job.customerDeadline` both honor `deadline_extended_until`** (admin
  deadline extension, ext-jobs column added web-side in `20260622000001`). The mobile model must parse it
  (`ExtJobModel`) or an admin extension silently won't show on mobile while it does on web.
- **The offer detail screen sees an ext job as a `Job`** (`ServiceOfferModel` builds `offer.job` via
  `ExtJobModel.toJobModel()`). That mapper MUST pass `sentAt` + `deadlineExtendedUntil` through, or
  `offer.job.customerDeadline` is null and the countdown silently hides for ext-job offers (the bug that
  made the banner missing on the post-bid screen). The `if (!offer.isExtJob)` gate around the banner was
  removed for the same reason.

## Things Claude must NOT do

- Do NOT call the Anthropic API directly from Flutter — always use an Edge Function
- Do NOT use `setState` for shared state — Riverpod only
- Do NOT use `Navigator.push` or raw path strings — use `context.goNamed()`
- Do NOT use GetX or Provider packages
- Do NOT block the UI during any network call — always show loading or streaming state
- Do NOT use `BuildContext` across async gaps — check `mounted` or use `ref`
- Do NOT put Supabase imports in the domain layer
- Do NOT put business logic in widget `build()` methods
- Do NOT subscribe to Supabase Realtime from inside a widget — only from providers
- Do NOT use `autoDispose` on global providers (auth, profile)
- Do NOT generate AI offer text without the musician's actual profile context
- Do NOT create a widget longer than ~150 lines without splitting it
- Do NOT create Supabase migrations here — migrations live in `web-app/supabase/migrations/` only
- Do NOT submit **DJ quotes** with a direct `Quotes` insert — POST to the web API `/api/jobs/{job_id}/quotes` (via `_webApiPost`, like `createServiceOffer` does). The "3 pending quotes → job goes `sent`" transition (plus `first_quote_only` send, suppression and tier-quota checks) lives ONLY in that route handler — **there is no DB trigger**. A direct insert leaves the job stuck in `open`. The route returns the **bare** quote row (no `job` join), so `DjQuoteModel.fromJson` tolerates a missing `job` key. **`editDjQuote` also routes through the web API** (`PUT /api/quotes/{id}`) so the 10-minute edit window, the pending-status guard and the price/pitch/equipment validation are enforced — a direct update bypassed all of it. That route returns only `{success, message}`, so `editDjQuote` re-reads the row afterwards to return the `DjQuote` shape callers expect.
- Do NOT update **`Jobs.status` / `ExtJobs.status`** (e.g. `customer_contacted`, `ready_for_billing`, planned contact) with a direct Supabase update. RLS on `Jobs` only lets the **customer (by `lead_email`)** update — a DJ's direct update matches **0 rows, returns no error**, so it looks like success but silently does nothing (status "resets" on reload). Use the elevated web API routes via `_webApiPut`: `/api/jobs/{id}/customer-contact`, `/api/jobs/{id}/ready-for-billing` (and the `/api/ext-jobs/{id}/...` equivalents). The ext-job datasource methods already do this — match that pattern.

## Genre option lists must byte-match the DB enum (curly apostrophe `’`, U+2019)

The `genres` / `musician_genre` Postgres enums are the source of truth, and the DJ genre
`70’er/80’er/90’er` is stored with a **typographic right single quote `’` (U+2019)** — see
`web-app/supabase/migrations/20240613131422_add-genres-dj.sql`. A selected genre is written to the
enum-typed `DjInfos.genres` column **verbatim**, so a value that differs by even one byte is an
invalid enum member and Postgres **rejects the whole profile save** (the DJ sees a generic save
error). Mobile previously hardcoded these lists with a **straight ASCII apostrophe `'` (U+0027)**, so
picking that genre made the profile unsaveable. The four lists
(`edit_profile_screen`, `profile_setup_screen`, `dj_job_filters_screen`, `onboarding_screen`
`_djGenres`) now use the curly `’`. **When adding/editing any genre option, copy the exact string
from the web-app's enum/`genrePriority.ts` — never retype it** (an editor or keyboard may substitute
a straight apostrophe). The straight-vs-curly difference is invisible on screen; verify with a
hexdump (`e2 80 99` = correct) if a save mysteriously fails.

## Web-API error messages are Danish + user-facing — but get suppressed by default

The web-app authors its API rejection reasons as **Danish, user-safe** text (e.g. ready-for-billing:
*"Alle vindende musikere skal have kontaktet kunden…"*). On mobile they arrive via
`JobsRemoteDatasource._webApiPut/Post/...` which wraps them in **`DatabaseException`** — and
`friendlyErrorMessage()` **deliberately suppresses `DatabaseException` inner messages** (assumes raw
DB text), returning a generic *"Noget gik galt. Prøv igen."*. So by default the DJ never sees WHY an
action failed.

To surface a specific reason, the screen's error handler must **pattern-match the Danish server text**
(not English, and not rely on `friendlyErrorMessage`). Example: `ext_job_detail_screen.dart`
`_toastError` matches `'musikere'` / `'markeres som kontaktet'` to explain that the instrumentalist
(or the DJ) still has to contact the customer. A real incident: a sax+DJ ready-for-billing was blocked
because the saxophonist hadn't marked contact, but the heuristic only matched the English words
`'musician'`/`'contact'`, so the Danish message fell through to the generic toast and the DJ had no
idea the sax player was the blocker. **When matching server reasons, match the Danish strings.**
(Internal-job `quote_detail_screen._handleReadyForBilling` still shows only a generic toast — a known
minor gap; internal DJ-only jobs can't hit the musician-contact blocker.)

## Handelsbetingelser (terms) + FAQ content are hardcoded and duplicated — sync by hand

- **Terms URLs** (mirror these exactly across apps): customer `https://djtilbud.dk/kunde-handelsebetingelser/` (the odd spelling "handels**e**betingelser" is the real live URL, not a typo), DJ `https://djtilbud.dk/dj-handelsbetingelser/`, sax/instrumentalist `https://djtilbud.dk/handelsbetingelser-instrumentalister/`. Mobile lists all three in `features/profile/presentation/screens/terms_screen.dart` (profile menu "Handelsbetingelser", route `AppRoutes.terms`, role-aware: customer link + the user's own DJ/sax link). Web sources: `web-app/src/components/SickDisclaimer.tsx` (dj/musician) + the customer link in `web-app/src/app/dj/faq/page.tsx`.
- **FAQ content lives in 3 independent hand-maintained copies** (no shared source): mobile `features/profile/presentation/screens/faq_screen.dart` (`_djFaqData` / `_instrumentalistFaqData`), web DJ `web-app/src/app/dj/faq/page.tsx` (inline `faqData`), web customer `web-app/src/app/faq/page.tsx` (+ `web-app/src/staticData/static-faqs.ts`). A wording change must be applied to each relevant copy. There is **no** instrumentalist/sax FAQ *page* on web — the sax FAQ exists only in mobile's `_instrumentalistFaqData`.

## Definition of done

- [ ] Works on both iOS and Android
- [ ] Handles loading, error, and empty states
- [ ] Does not break existing Supabase data
- [ ] Push notifications work for the relevant flow (if applicable)
- [ ] AI interactions stream and never block UI (if applicable)
- [ ] Three-layer architecture respected — no Supabase in domain, no business logic in build()
- [ ] Realtime subscriptions cancelled in `ref.onDispose()`
- [ ] No secrets hardcoded
