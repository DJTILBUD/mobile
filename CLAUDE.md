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

The "typecheck + tests" done-bar for this app = `flutter analyze` + `flutter test` (this folder already has a fuller "Definition of done" checklist at the bottom). Note: `build_runner` is **not** a dependency here — generated files are committed, so `dart run build_runner build` fails with "Could not find package build_runner" and is a no-op; don't treat that as a blocker. `mobile/test/` **does** exist now (unit + widget tests under `test/core/`, `test/features/`), so `flutter test` is a real gate — 90 tests, all green as of 2026-08-07. The other gate is `flutter analyze` (0 errors; the 338 `_c` info/warning lints are the documented baseline — quote the error count, not the issue count).

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
**No emojis in release notes.** Notes shipped before 1.0.37 contain them (the 1.0.34 "Send besked" headline had one) so the existing files are NOT a style template — the user rejects emoji in store copy. Plain text plus `•` bullets. Play caps the changelog at 500 characters; the other two are 4000.

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

### Android target API level: pinned to 36, NOT `flutter.targetSdkVersion`

Google Play requires target API 36 (Android 16) from **Aug 31 2026** or the app can no longer be
updated. The Flutter SDK on this machine is **3.29.2, whose `flutter.targetSdkVersion` and
`flutter.compileSdkVersion` are both 35**, so inheriting them would have silently shipped a
non-compliant bundle. `android/app/build.gradle.kts` therefore hardcodes `compileSdk = 36` and
`targetSdk = 36`. **Don't "clean this up" back to `flutter.*`** until the installed Flutter SDK
actually defaults to >= 36 (Flutter 3.35+); verify with
`grep targetSdkVersion $FLUTTER_ROOT/packages/flutter_tools/gradle/src/main/groovy/flutter.groovy`.

Two things that make this work and are easy to lose:
- AGP here is **8.7.0**, which predates API 36 and prints a loud "compileSdk 36 has not been tested"
  warning. `android/gradle.properties` carries `android.suppressUnsupportedCompileSdk=36` to silence
  it. The build genuinely works on AGP 8.7 + Gradle 8.10.2 + JDK 17, with no AGP or Gradle upgrade.
- The SDK platform must be installed locally:
  `sdkmanager "platforms;android-36" "build-tools;36.0.0"`. A fresh machine will fail the build
  without it.

**Verify the shipped bundle, don't trust the config.** After building, the merged manifest is the
proof:
`grep -o 'targetSdkVersion[^/]*' build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml`
must print `targetSdkVersion="36"`.

**Related Play requirement, 16 KB page size** (separate from target API, also enforced): every
bundled `.so` must have LOAD segments aligned to >= 16 KB. Currently satisfied without extra work
(`ndkVersion = "27.0.12077973"` aligns by default): `libflutter.so` and `libapp.so` are 0x10000
(64 KB), `libdatastore_shared_counter.so` is 0x4000 (16 KB). Re-check after adding any plugin that
ships prebuilt native code:
`unzip -q app-release.aab -d out && llvm-readelf -l out/base/lib/arm64-v8a/*.so | awk '/LOAD/{print $NF}' | sort -u`

Going from 35 to 36 carries **no new edge-to-edge work**: Android 15 (targetSdk 35) already enforced
edge-to-edge, so the app has been running under it, and Android 16 only removes an opt-out flag this
app never used. Still worth a smoke test on an Android 16 emulator before rollout.

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

### Three separate things broke notification deep-links — all three are now guarded

**1. `state.extra` is NOT durable, so a role-only route must never depend on it.** go_router carries
no `extra` through a re-parse (there is no `extraCodec`), and a re-parse happens for reasons the user
never asked for: the platform re-reporting the current route on an Android activity restore, a Router
remount, a deep link pushed before the Router mounted. Every one of those dropped a pushed screen into
`_MissingRouteDataScreen` ("Mangler data"). The role is a **global app fact**, not per-navigation data
— `RoleCache.role` is loaded in `main()` before `runApp` and is exactly what the shell already renders
— so **`app.dart`'s `roleFromExtra(state.extra)` resolves it from the cache** whenever `extra` is
missing or the wrong type. Applied to `/admin-messages`, `/edit-profile`, `/reviews`, `/stats`,
`/payment`, `/terms`, `/notification-settings`, `/faq`, `/profile-preview`, and to the two
`/job-filters` routes (whose `extra` is the signed-in user's own id → `supabase.auth.currentUser`).
`/faq` was a hard `state.extra as MusicianRole` cast, so it **threw** rather than degrading;
`/profile-preview` fell back to a hardcoded `MusicianRole.dj`, so a musician previewed the DJ profile.
Routes that need a real entity (Job/Quote/ExtJob/Conversation) keep `_MissingRouteDataScreen` — they
have nothing to fall back to. **When adding a deep link, ask whether `extra` is derivable app state; if
it is, derive it and do not gate the screen on it.**

**2. `data['role']` is often ABSENT — use `NotificationsService.effectiveRole(data)`, never the raw
key.** `notify-admin-message` sends ONE multicast to DJs and musicians when
`target_audience = 'both'`, so it deliberately omits `role` (it cannot be per-recipient). A bare
`data['role'] == 'musician'` test then reads as "dj", which pushed **musicians into the `/dj/*` shell**
and opened `AdminMessagesScreen(role: dj)` — the wrong message list, with read-state keyed on `djId`.
`effectiveRole` prefers the payload and falls back to `RoleCache`. **Analytics deliberately keeps the
RAW payload role** (`loggedRole`) so `tapped` rows stay joinable with the `sent` rows the Edge Function
wrote; resolving it there would split one `both` campaign across two roles in the funnel.

**3. A cold start from a tapped push raced BOTH the session and the router.**
`handleInitialMessage` fires from `App.didChangeDependencies`, before either is guaranteed:
- **Session:** `Supabase.initialize` returns before `recoverSession()` restores the session (this is
  why `main()` subscribes the auth notifier first). `navigateTo`'s `if (userId == null) return`
  therefore **silently dropped the entire deep link** — the app just opened on home and the tap looked
  ignored. `_awaitUserId()` (5s, via `auth.onAuthStateChange`) turns that race into a short delay.
- **Router:** `GoRouter.push` builds on `routerDelegate.currentConfiguration` **as of the call**, which
  is empty until the `Router` has parsed its initial location. Pushing onto an empty base does not
  throw — it yields a stack with **no shell underneath**: no bottom nav, `canPop()` false (Android back
  exits the app), and the screen **disappears** on the next router refresh, which a cold start reliably
  fires when the auth notifier sees the recovered session. `_awaitRouterReady(router)` waits it out.
  Pinned in `test/app/deep_link_router_readiness_test.dart`; both waits are no-ops on the warm path.

Related, and still true: **`goTab(path)` immediately followed by `router.pushNamed(...)` only works
because the redirect is synchronous** — `go()` merely queues route information, and it is the
`SynchronousFuture` through the parser that lets `push` see the new tab as its base. Do not put an
`await` between them, and do not make `redirect` async.

(`AdminMessagesScreen` also has pull-to-refresh + a retry — the `_CenteredScrollable` wrapper makes the
loading/error/empty states pull-refreshable, `RefreshIndicator.onRefresh` invalidates + awaits
`adminMessagesProvider`.)

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

**⚠️ SINGLE-QUOTE the key in `.env.<env>`, or it is silently mangled.** `flutter_dotenv`'s parser
interpolates `$name` in unquoted AND double-quoted values (`_bashVar` in `parser.dart`, run after the
quotes are stripped) and strips `#...` as a comment; only a single-quoted value is taken literally.
Our keys contain `$`, so an unquoted key lost 3 characters on-device and every impersonation
attempt on dev came back as `Token-fejl (401): Unauthorized.` while the very same value worked from
curl. The tell is exactly that: the file's value is accepted by the server, the app's is not.
`\$` also survives, which is how `.env.prod` had been written; single quotes are the simpler rule.
Assets are bundled at build time, so a changed `.env.*` needs a full rebuild, not a hot restart.

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
   **`sax_type` (Spiltype) must be on this screen too.** It was on the feed `JobCard` but not on the
   screen the card opens, so a musician could see "Party-sax" in the list and then find no trace of it
   after tapping in — the exact complaint that got reported. The shared
   `presentation/widgets/sax_type_info.dart` (`saxTypeLabel()` + the tap-to-expand `SaxTypeDescription`)
   is the one copy; mirrors the badge + tooltip in web
   `instrumentalist/jobs/[job_id]/_components/JobInfo.tsx`. Note the description used to live as a
   private widget inside `job_detail_screen.dart`, which **nothing routes to** (that file says so at the
   top) — so it had never actually been on screen. When adding a musician-facing field, check it lands
   on the *offer form*, not just the card or the dead detail screen.
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

## "Billeder fra stedet" venue photos on the ext job detail (`VenuePhotosCard`)

The team photographs a partner venue on a site visit and comments each photo in the admin tool; the
DJ sees them on the ext job so they know where to stand and where the power is before arriving.
Mirrors web `VenuePhotosSection` on `dj/udvalgte-jobs/[id]`.

- **Same data path as the "Fast kunde" badge, and for the same reason.** The rows live in
  `RecurringCustomerPhotos`, which a DJ cannot read via RLS, so they come from the DJ-scoped
  `GET /api/internal-dj/ext-jobs?dj_id=<uid>` as `venue_photos: [{id, url, comment}]` per job.
  `djExtJobVenuePhotosProvider` (`jobs_provider.dart`) → `fetchDjExtJobVenuePhotos` → a
  `Map<int, List<VenuePhoto>>` keyed by **ext job id**; a job with no photos is absent, and any
  failure degrades to an empty map so the card just does not render. **Do NOT route it through
  `djExtJobsProvider`** (same rule as the badge: that read is direct Supabase and shared with the
  date-collision guard).
- Entity `features/jobs/domain/entities/venue_photo.dart` is the Dart mirror of the web
  `VenuePhoto` type; `fromJson` returns null for a malformed row rather than throwing, so one bad
  row never hides the rest.
- Widget `shared/widgets/venue_photos_card.dart`: a horizontal thumbnail strip with the comment
  under each, tap → `VenuePhotoViewerScreen` (PageView + `InteractiveViewer` pinch-zoom, caption
  under the image, "n / total" in the app bar).
- **The ext job detail is TABBED for partner bookings: "Job" and "Stedet".** `showVenueTab` =
  `extJob.isRecurringCustomer || venuePhotos.isNotEmpty || wishesCard.hasContent`. The "Stedet"
  tab holds everything about the venue in one place: the `RecurringCustomerBadge`,
  `EventAddressSection`, `VenuePhotosCard`, `PartnerEventWishesCard`, and a `_VenueEmptyState`
  when the first two data sources are empty (a partner booking gets the tab even before any photos
  exist, so the DJ learns where venue info lives). The "Job" tab is the previous single scroll
  minus those cards. When there is no venue tab, the address section and the wishes card render
  inline exactly as before, so a plain ext job is unchanged. `DefaultTabController(length: 2)`
  always wraps the Scaffold; the `DSTabBar` is only attached to the AppBar when the tab is shown.
  The chat `ChatBubbleFab` overlay sits above the `TabBarView`, so it is visible on both tabs.
- DJ-only for now: the sax names endpoint returns no photos, so a musician opening the shared
  detail screen sees no card.

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

## ⌨️ Keyboard avoidance — the three rules, and the global bar that broke all of them

### Rule 1c: the conversation list is `reverse: true` — do not "fix" it back

`conversation_detail_screen`'s `ListView.builder` is reversed, so **offset 0 is the bottom** and the
newest message is pinned there by construction. It is walked backwards
(`groups[groups.length - 1 - groupIndex]`) so index 0 is the newest day; inside a group the Column
still renders top-to-bottom, so the date divider stays above its messages.

It replaced a normal list that jumped to `maxScrollExtent` in a post-frame callback, which failed
two ways users reported:

- **Opening a conversation landed mid-history.** `maxScrollExtent` is an ESTIMATE while images are
  still loading and while `ListView.builder` has only laid out the visible window, so the jump
  landed short. No amount of re-jumping fixes that reliably; anchoring does.
- **Opening the keyboard hid the newest message.** The Scaffold shrinks the viewport and a normal
  list keeps its OFFSET, so the bottom of the conversation slid under the composer and you could
  not see what you were replying to. Anchored at 0 the bottom stays put and the list shortens at
  the top instead.

⚠️ `_scrollToBottom` therefore targets **`minScrollExtent`**. Targeting `maxScrollExtent` on a
reversed list flies the reader to the OLDEST message in the thread.

### Rule 1b: a TALL field needs `scrollPadding`, or the user types through a slot

Rule 1 (let the Scaffold resize) makes a focused field *visible*; it does not make it *usable*. The
framework scrolls only far enough to reveal the **caret** plus `TextField.scrollPadding` (default
20). On an empty textarea the caret is line 1, so a `minLines: 8` box (~192px — "Salgstale" on both
quote forms) came to rest with ~60px of itself above the keyboard: the DJ wrote a 450-character
pitch through a one-line slot at the bottom edge. Reported right after the 1.0.38 hotfix as "the
keyboard takes up the space where the user is writing".

`DSInput` now reserves roughly the field's own height below the caret for multiline fields
(`_scrollPadding`, `20 + lines * 22` capped at 8 lines). `ensureVisible` clamps to the scroll
extent, so over-asking just parks the field at the top of the viewport. Single-line fields keep the
default — hoisting them would only leave a dead gap.

- **⚠️ Testing this requires a TAP, not `requestFocus()`.** Programmatic focus goes through the
  focus-traversal path, which reveals the WHOLE field and hides the bug entirely; a real tap runs
  only `EditableText._showCaretOnScreen`, which reveals the caret plus `scrollPadding`. A test built
  on `requestFocus()` passes against the broken code — this one did, twice, before it was caught.
- **⚠️ And it requires `setSurfaceSize`.** A `MediaQuery` with a `size` does not change layout
  constraints; the tree still lays out at the default 800x600, the shrunken Scaffold ends up
  elsewhere, and the tap lands in dead space and focuses nothing.
  `test/core/design_system/ds_input_keyboard_test.dart` does both and fails against the unfixed
  input (field bottom 580 vs a 460 keyboard line, 72px of 192 visible).

### ⚠️⚠️ RULE 0, LEARNED THE EXPENSIVE WAY: never change the SHAPE of the tree above the router

`MaterialApp.router` hands its `builder` the **`Router` widget itself** as `child`, not the routed
screen. So a wrapper in that builder that sometimes returns `child` and sometimes returns
`Something(child: child)` moves the Router to a different depth. Flutter cannot match the elements,
unmounts the Router, and mounts a fresh one — and a fresh `Router` re-parses the whole stack from
the URL in `initState`. **go_router carries no `extra` through a re-parse** (there is no
`extraCodec` configured), so every pushed route rebuilds with `extra == null`.

Every job/profile/quote route in this app is pushed with `extra: <entity>` and falls back to
`_MissingRouteDataScreen` when it is missing. So the effect is total:

> Siden "tilbudsformular" kunne ikke åbnes, fordi nødvendige data mangler.

**This shipped as 1.0.37 and broke every screen for every user.** `ReserveKeyboardDismissBar` did
`if (!barVisible) return child;` before returning the wrapped version, so the shape flipped the
instant a keyboard opened — on the quote form, on edit-profile, everywhere. The fix is to always
return the wrapper and vary only the value (`reserved = barVisible ? barHeight : 0.0`).

- **The diagnostic that cracked it:** chat was the ONLY screen that did not fail. Chat sets
  `suppressKeyboardDismissBarProvider`, so `barVisible` stayed false there, so the shape never
  toggled. A screen that behaves differently *because it opts out of the global widget* points
  straight at that widget.
- **A synthetic go_router harness will NOT reproduce it.** Pushing a route, toggling view insets and
  asserting `extra` survives passes even against the broken code, because the Navigator's GlobalKey
  carries the route stack in that setup. Assert the real contract instead:
  `test/app/route_extra_survives_keyboard_test.dart` pins that the child's `State` is the SAME
  instance across a keyboard toggle. That test fails against the 1.0.37 code and passes now.
- **This applies to anything else placed in `MaterialApp.builder`** — a banner, a gate, a theme
  wrapper. Conditional wrapping there is never cosmetic; it resets routing. `UpdateGate` is allowed
  to swap in `ForceUpdateScreen` because blocking the whole app is the intent.


Read this before touching any screen with a text input. There are exactly three shapes.

**1. A `Scaffold` screen: keep the default `resizeToAvoidBottomInset: true` and do nothing else.**
The Scaffold shrinks its body to the space above the keyboard and Flutter scrolls the focused field
into it. Do NOT add `viewInsets` padding on top — that double-counts.

**2. A modal bottom sheet: the sheet must lift ITSELF.** `ModalBottomSheetRoute` applies no
`viewInsets` of its own (unlike a Scaffold), so nothing shrinks for you.
- ✅ Wrap the sheet's root `Container` in `Padding(bottom: viewInsets.bottom)`, clamped via
  `LayoutBuilder` so dragging the sheet down with the keyboard open can't leave it 0px tall.
  Reference implementations: `agent_bottom_sheet.dart`, `edit_quote_bottom_sheet.dart`,
  `profile_bio_bottom_sheet.dart`.
- ❌ **Do NOT put the inset in the scroll view's `padding`.** It only adds empty scroll *content*;
  the viewport still extends under the keyboard, so the field can be "scrolled into view" and STILL
  sit behind it. This exact bug was in `edit_quote_bottom_sheet` (the quote sales pitch) and
  `profile_bio_bottom_sheet` and is fixed; the comment "Add the keyboard inset so lower fields
  scroll clear of it" is the fingerprint of it.
- ❌ **Do NOT read `viewInsets` from the OUTER screen's `context` inside `builder:`.** A sheet is a
  separate route, so the parent's value is captured at push time (0) and the sheet never rebuilds as
  the keyboard animates in — the padding stays 0 forever. Use the builder's own context:
  `builder: (sheetContext) => ... MediaQuery.viewInsetsOf(sheetContext).bottom`. Three call sites had
  this (`quote_detail_screen`, `service_offer_detail_screen`, `ext_job_detail_screen`, all wrapping
  `ContactCustomerSheet`).

**3. ⚠️ THE GLOBAL "Luk" BAR — the one that made rule 1 look broken everywhere.**
`_KeyboardDismissBar` (`app.dart`) is `Positioned(bottom: viewInsets.bottom)` in the **app-level
`MaterialApp.builder` Stack**, i.e. painted ABOVE the routed screen. A Scaffold obeying rule 1
shrinks to exactly `screen - keyboard` and scrolls the focused field to the bottom of that area —
which is precisely where the opaque bar is drawn. So on EVERY screen with an input, the bottom strip
of the focused field was hidden behind it: the last lines of a tall sales pitch, the character
counter, the row of buttons under it. The chat screen only escaped it by suppressing the bar
(`suppressKeyboardDismissBarProvider`), which is a per-screen workaround, not the fix.

The fix is `_ReserveKeyboardDismissBar` in `app.dart`: it wraps the routed child in a `MediaQuery`
whose `viewInsets.bottom` is inflated by `keyboardDismissBarHeight(context)`, so every Scaffold below
stops ABOVE the bar and the bar sits in the reserved gap. One change, every screen.
- **The height constant is shared** by the reservation and the bar's own `SizedBox`. If they drift,
  the bar covers content again. It scales with the text scaler (clamped) so a large accessibility
  size can't outgrow its gap.
- **The visibility condition is duplicated and must stay identical** (`keyboard > 0 && !suppressed`).
  Reserving for a bar that isn't drawn leaves a dead gap above the keyboard — which is why the chat
  screen, which suppresses the bar, must not reserve for it either.
- Sheets following rule 2 pick the extra height up automatically and clear the bar too.
- **Regression tests: `test/app/keyboard_dismiss_bar_reservation_test.dart`.** The load-bearing one
  pumps a real `Scaffold` under the reservation and asserts its body ends ABOVE the bar strip, so it
  fails if the reservation is removed or drifts from the bar's height. `ReserveKeyboardDismissBar`
  and `keyboardDismissBarHeight` are `@visibleForTesting`-public for this reason — do not re-privatise
  them without moving the tests.

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

## Media tiles + the profile coach: two ways the UI lied to the user

**A video with no thumbnail must never render as the ADD tile.** `media_screen`'s `_MediaTile` fell
back to `Icon(LucideIcons.video)` on the plain bordered box when `thumbnailUrl == null` — the same
icon, size and border as `_AddTile`'s "Tilføj video". An uploaded clip was therefore drawn as the
add button with a delete badge on it ("how come the user can delete that?"). It now always renders
dark with the play badge (`_NoVideoPreview`), so a missing preview reads as a video, not an empty
slot. Thumbnail-less videos are NORMAL and will keep occurring: `_uploadThumbnail` is best-effort
and returns null on any failure (generation, signed URL, S3 PUT) without surfacing anything, and
the video row is inserted regardless.

**Posters are grabbed at `timeMs: 1000`, not frame 0.** The default first frame of a phone clip is
very often black (fade-in, autoexposure), which is how a gallery ends up showing a pure black tile.
Falls back to frame 0 if the seek yields nothing. Both uploaders
(`profile_remote_datasource`, `job_content_remote_datasource`) do this — keep them in sync. Only
affects NEW uploads; existing black posters stay until re-uploaded.

**The profile coach must render `AgentError`, not swallow it.** `_AssessmentText` returned
`SizedBox.shrink()` on error while the gap section below still rendered (its condition is
`AgentDone || AgentError`). So a DJ out of AI credits saw an empty sheet topped by "Din profil er
komplet — godt klaret!" and read that green badge as the AI's verdict, when the AI had never run.
`AgentError.message` is already user-ready Danish from `agent_provider` (the `AgentLimitException`
branches), so it only needed rendering.

- **The badge itself is honest and has nothing to do with credits.** Gaps come from
  `widget.userContext` — profile image, `reviewCount >= 10`, `videoCount >= 1`, bio `>= 80` chars,
  genres non-empty, `venuesAndEvents.length >= 3` — computed locally, never from the model. If it
  says complete, those six are genuinely met.
- **⚠️ `_dismissedGapTitles` can still make it lie within a session.** Dismissing every card with
  its X empties the gap list and shows the complete badge. The set is in-memory only, so it clears
  when the sheet is disposed, but the badge should arguably distinguish "nothing left" from
  "nothing you haven't dismissed".

## ⚠️ Archived jobs are invisible to DJs/musicians — enforced by RLS, not by each query

An archived internal `Jobs` row is CRM-deleted. It is almost always the **internal duplicate of an
ExtJob**, which links back to it via `ExtJobs.internal_job_id` (admin renders "Linked Archived Job").
Archiving **keeps the job's status**, so no status filter excludes it — and the sax booking form
writes a mirrored `Jobs` + `ExtJobs` pair by design, so these duplicates are routine, not rare.

**The money bug this caused:** a DJ saw job #864 and E132 — the same booking — side by side, and
`statEntriesProvider` (`_djEntries`) counted BOTH toward his earnings, so one job read as two payouts.
He asked to be paid twice. Neither mobile nor web filtered `archived` on the DJ's quotes.

**The rule now lives in the DB**: web-app migration `20260810000000_hide_archived_jobs_from_performers`
adds `archived = false OR is_admin(auth.uid())` to both broad SELECT policies on `Jobs`, so a
DJ/musician session physically cannot read one — every direct Supabase query in this app is covered,
including future ones. The explicit filters below stay as defence in depth and because **PostgREST
applies RLS to embeds**: an archived job now comes back as `job: null` inside a Quotes/ServiceOffers
select, which the client must treat as "not visible" and drop (that is why `fetchServiceOffers` also
drops a row whose `job_id` is set but whose `job` embed is null).

Filter points (all now in place):
- `fetchDjQuotes` — `Jobs!inner` + `.eq('job.archived', false)`. `Quotes.job_id` is NOT NULL so the
  inner join is safe. One filter covers the won/sent/lost tabs, calendar, nav badges, the stats screen
  AND the date-collision guard — a dead job should block nothing.
- `fetchServiceOffers` — filtered **in Dart**, not with `Jobs!inner`: an ext-job offer has `job_id`
  null, so an inner join on Jobs would silently drop every ext-job offer.
- `fetchNewInstrumentalistJobs` — already had `.eq('archived', false)`.
- "Nye jobs" for DJs is fixed **server-side** in web `src/domain/biddableJobs.ts` (the shared module
  behind both `/api/dj/biddable-jobs` and web's `useUnbidJobsFromMyRegions`), so both platforms get it
  from one change. There is a regression test there.

**Do NOT filter the ExtJob side.** The ext job is the LIVE booking; the archived internal Job is the
dead twin. Hiding the wrong one loses the real job.

## First-win popup: musicians have TWO variants and the RPC REQUIRES `p_variant`

`features/first_win/` mirrors web `src/hooks/useFirstWinPopup.ts` — keep them in sync. The DB RPC is
**`mark_first_win_shown(p_role text, p_variant text DEFAULT NULL)`** (migration
`20260522000002_musician_first_win_split`, and `…000003` dropped the old 1-arg overload).

- **`p_variant` is mandatory for `p_role='musician'`.** The function `RAISE EXCEPTION 'Invalid
  variant for musician: %'` when it is anything but `'with_dj'`/`'solo'` — NULL included. Mobile used
  to call it with only `p_role`, so **every musician dismissal threw**, nothing was persisted, and the
  walkthrough (checklist and all) reappeared on every single app launch. Reported by two saxophonists.
  DJs were never affected: the `p_role='dj'` branch takes no variant. Send `MusicianVariant.rpcValue`,
  never `.name` (`withDj` != `with_dj`) — there is a test pinning both strings.
- **Musicians have two columns, and `Musicians.first_win_shown_at` is NOT one of them.** The live
  columns are `first_win_with_dj_shown_at` + `first_win_solo_shown_at`. The legacy single column still
  exists but nothing writes it any more, so reading it (which the old mobile datasource did) is a
  second, independent way to make the popup immortal. `DjInfos.first_win_shown_at` is unchanged.
  **This one, not the missing `p_variant`, is what actually bit the reported user** (Astrid, musician
  `40695465-…`): she had already completed the solo walkthrough **on the web app** (`first_win_solo_shown_at`
  = 2026-06-04), so web considered her done — but mobile read the dead legacy column, saw NULL, and
  re-showed the *same* solo checklist on every launch, where the dismiss then also threw. Anyone who
  dismissed on web is in this state. Diagnose with `first_win_shown_at IS NULL` + any won offer, NOT
  with the two new columns.
- **Only show a variant a real win backs.** `pendingMusicianVariant` returns null when the pending
  column has no matching win — without that rule Astrid (solo column set, with_dj column NULL, and no
  with-DJ win) would flip straight from the immortal solo popup to an unearned with_dj popup.
- **The variant must be decided BEFORE showing the dialog and carried into the dismiss** — it picks
  both the walkthrough AND the column written. `firstWinDecisionProvider` returns a `FirstWinDecision`
  (`shouldShow` + `musicianVariant`); the pure `pendingMusicianVariant(...)` holds the with_dj-wins-
  ties rule. `showFirstWinDialog` no longer defaults the variant: defaulting it to `solo` showed a sax
  who won a job WITH a DJ the solo walkthrough, which tells them to agree invoicing with the customer
  — the DJ's job on that booking.
- **A failed dismiss now surfaces a toast** instead of popping as if it worked. The old `try/finally`
  with no `catch` closed the dialog and swallowed the RPC error, which is why this looked like a UI
  bug for months rather than a failing write.

## "Luk aftale og send faktura" is BLOCKED until every winning musician has contacted the customer

The DJ may not close a deal while a **winning `ServiceOffers` row on the same job has
`customer_contacted = false`** — a sax player is routinely slower than the DJ, so this fires
often. It is a **server rule**, enforced by `PUT /api/jobs/[job_id]/ready-for-billing` and
`PUT /api/ext-jobs/[ext_job_id]/ready-for-billing`, which reject with **400 +
`code: "musician_not_contacted"`** and a Danish user-facing `message`.

**What was wrong** (reported from the field, job #2962): the internal-job route returned developer
English, `quote_detail_screen` threw the message away and showed a bare **"Noget gik galt. Prøv
igen."**, and the button was tappable in the first place — so the DJ had no way to learn that the
saxophonist was the blocker. The web-app already had both halves (`LeadInfo.tsx`
`isBlockedByMusicianContact` disables the button and prints the reason); mobile simply never
mirrored it.

- **The rule is `features/jobs/domain/ready_for_billing_gate.dart`** — `isBlockedByMusicianContact`
  (there must BE a won offer AND at least one won offer un-contacted; a job with no musician is
  never blocked), `musicianContactBlockedMessage` (names the instrument when every blocker shares
  one, else neutral) and `readyForBillingErrorMessage` (maps the server reason to DJ-actionable
  Danish). Unit-tested in `test/features/jobs/domain/ready_for_billing_gate_test.dart`. Both DJ
  screens use this one copy — `ext_job_detail_screen`'s old private `_toastError` now delegates to
  it, so the two screens can never tell the DJ different things. It matches the server's stable
  **`code`** first and only falls back to sniffing the Danish copy: `JobsRemoteDatasource._errorFor`
  now populates **`DatabaseException.code`** from the route's JSON body (every non-2xx from
  `_webApiPut/_webApiPatch/_webApiDelete/_webApiGet` goes through it, not just POST), so
  `code == 'musician_not_contacted'` is decidable without depending on wording that will be
  reworded. Any new route that wants a client-legible rejection should send a `code`.
- **⚠️ `fetchServiceOffersForJob`/`ForExtJob` MUST keep `customer_contacted` in the select.** The
  DJ-view query hand-lists its columns and the repository hand-maps them, so dropping it anywhere
  along that path silently defaults every offer to "not contacted" and blocks every DJ — the same
  lossy-mapper trap as the web `mapUpdateJoinedDjInfo` one. `ServiceOffer.customerContacted`
  already existed; only the DJ-view fetch was missing it.
- **The client gate FAILS OPEN**: an unloaded or failed offer list leaves the button enabled. It only
  decides tappability — the server is always the authority, so at worst the DJ taps into the (now
  legible) rejection. Never invert this; a read error would otherwise freeze every close.
- Blocked state = `LockedInfoBanner` (`shared/widgets/locked_info_banner.dart`, promoted from
  ext_job_detail's private `_LockedInfo`) directly above a **disabled** `DSButton`. A disabled button
  with no explanation reads as a bug, which is what sent DJs to support in the first place.
- The ext-job gate is scoped to `isAssignedDj` — a musician on that screen is the person being
  waited for, not the one being blocked.

## Saxophonists on a `musician_only` ext job own "klar til fakturering" — give them the button

`notify-process-reminder` sends the musician a **`send_invoice_reminder`** ("husk lige at lukke
aftalen og sende fakturaen") for a **won `musician_only` ext job stuck in `customer_contacted`** —
because on that job type there is no DJ, so the winning musician owns `ready_for_billing` (the web
route `PUT /api/ext-jobs/[id]/ready-for-billing` authorises them explicitly). The reminder repeats
**every day, with no interval damping** (unlike the contact nudge, which is every 2nd day) until the
status advances.

Mobile shipped that push for months with **no way to act on it** — `service_offer_detail_screen`
`_wonBody` had only "Kunde kontaktet" + "Jeg er klar", so the sax was told daily to do something the
app did not expose. (The `ServiceOfferCard` action chip already rendered `JobActionType.readyForBilling`,
so the list promised an action the detail screen didn't have.) Reported verbatim as *"det kan jeg ikke
se, hvordan jeg skal gøre"*.

Now mirrored from web `instrumentalist/jobs/[job_id]/_components/LeadInfo.tsx`:
- **"Klar til fakturering ✓"** when `musician_only && customer_contacted && status != ready_for_billing`
  → `markMusicianExtJobReadyForBillingProvider` (same repository method the DJ screen uses, but it
  refreshes `serviceOffersProvider` instead of `djExtJobsProvider`).
- **"Jeg er klar" is gated behind it** on `musician_only` (`!isMusicianOnly || isReadyForBilling`), so
  the two CTAs never compete — same order as web.
- The `ProcessTracker` gains a **"Send faktura"** step on `musician_only` only.
- **Gate on `customer_contacted`, NOT on the ext-job status.** Admin-assigned `musician_only` ext jobs
  go `open → sent` and are never `closed`, so the server accepts `sent`/`closed`/`customer_contacted`
  for this transition. `ServiceOfferAction.pendingAction` (the card chip) still gates on
  `job.status == customerContacted` and therefore misses those — a known narrower condition.

## AI sheet (`agent_bottom_sheet.dart`) keyboard avoidance — the sheet lifts, not the child

Opposite rule to the chat screen above, because a **modal bottom sheet is NOT resized by the
keyboard** (`ModalBottomSheetRoute` applies no `viewInsets` padding of its own — unlike a Scaffold).
So the "Skriv til AI'en..." composer used to end up behind the keyboard even though it padded
*itself* by `viewInsets.bottom`: that padding sat **inside** the `SingleChildScrollView`, so it only
added empty scroll content and the scrollable's viewport still extended under the keyboard.

The working shape:
- The `DraggableScrollableSheet` builder wraps its `Container` in `Padding(bottom: viewInsets.bottom)`
  (clamped via `LayoutBuilder` so dragging the sheet down with the keyboard open can't leave it 0px
  tall). This lifts the **whole sheet body** above the keyboard.
- The `_RefinementStrip` composer is **pinned outside the scroll view**, between the scrolling draft
  and `_ActionBar` — a chat-composer layout. It must NOT re-apply `viewInsets` (double-counting).
- Its `TextField` has a `FocusNode` whose listener calls `_expandForKeyboard()`, animating the sheet
  to `_maxSheetSize` so the draft keeps as much room as possible once the keyboard is up.

## Customer FIRST name is visible to DJs/musicians in every job state

`Jobs.lead_name` / `ExtJobs.lead_name` is shown as **"Kunde: <first name>"** on every job surface —
open, sent and won, for both roles. Full name + phone + email stay reserved for the won contact
sections. One helper does the extraction: **`core/utils/customer_name.dart` → `customerFirstName()`**
(first whitespace token, null for junk). Never `leadName.split(' ').first` inline — `lead_name` is
`text NOT NULL` with no format constraint and the WordPress forms put `-` / blanks in it, which
would render as a customer literally called "-" (same class of trap as `lead_phone_number`, see
`phone_utils.dart`).

Surfaces wired: `job_card` (open, both roles), `quote_card` (DJ sent/won), `service_offer_card`
(sax sent/won/lost), `dj_quote_form_screen`, `instrumentalist_offer_form_screen`,
`quote_detail_screen`, `service_offer_detail_screen`. `ext_job_detail_screen` is deliberately NOT in
the list — it is a won-only view whose "Kundekontakt" card already shows the full name. Web parity:
web already shows the **full** `lead_name` pre-win (`dj/jobs/[id]/_components/LeadInfo.tsx`), so
mobile is the stricter of the two here.

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
- **⚠️ Tapping a notification marks its feed row read — matched on `(type, reference_id)`, not on id.**
  Until this landed, opening the app from a push navigated correctly but left the row unread, so the
  red badge survived the tap on all three surfaces and only "Marker alle læst" cleared it (reported
  as *"det lille røde 1 tal fjerner sig ikke"*). The fix is `navigateTo` → `NotificationsDatasource
  .markReadForPush`. It cannot match by id: the sender builds the FCM data map, `await`s
  `sendFcmPush`, and only then inserts the `UserNotifications` row (`_shared/notification_log.ts`),
  so **no row id exists at send time**. It matches the pair the sender writes instead — `data.type`
  and the id `extractReferenceId` pulls from the same payload.
  - **This makes `NotificationsService.extractReferenceId` load-bearing for the badge**, not just for
    the analytics funnel it was written for. A new notification type missing from its switch returns
    null, and its badge silently never clears on tap. `test/core/notifications/extract_reference_id_test.dart`
    pins every type.
  - **All unread rows sharing the pair are cleared**, deliberately: three unread `chat_message` rows
    for one conversation must all go read when that conversation opens, or the badge just counts down
    to 2 instead of 0. With a null reference (broadcast `custom_notification`) only the newest row is
    cleared, since the pair cannot separate two unrelated announcements.
  - **⚠️ Realtime is NOT enough to refresh the badge here, so `NotificationsService.feedReadEvents`
    exists.** On a push tapped from a TERMINATED app, `navigateTo` runs during launch: the UPDATE can
    commit while `NotificationsNotifier` has finished its first fetch but its websocket is still
    connecting, and that event is lost — badge stays lit until the next resume. The stream emits
    *after* the write, so a notifier created later reads correct data anyway and one created earlier
    is told to refetch. Ordering the other way (send push after inserting the row) would be the
    server-side fix, but it would have to change every `notify-*` function.
  - Every entry point runs it (push, foreground banner, and a row re-opened in the notification
    centre). The centre already marks its own row read first, so there the update matches nothing.
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

## Special-request extra fee: the reason is REQUIRED

`_SpecialRequestFeeSection` asks "Hvad dækker tillægget?" and the submit button stays disabled until
it has >= 10 characters (`_minReasonLength` / `_maxReasonLength` mirror
`SPECIAL_REQUEST_REASON_MIN/MAX_LENGTH` in web `src/constants.ts` — the route rejects anything
shorter, so validating here just saves a round trip). The text is sent as `reason` on
`PATCH /api/service-offer/{id}/special-request-fee` and rendered back in both the pending and the
confirmed card. Withdrawing the fee clears it locally because the route nulls it server-side.

Why: admin approves each fee by hand and previously saw only the amount, so every request cost a
round of messaging. `ServiceOffers.special_request_extra_fee_reason` (migration `20260810000002`) is
nullable only for rows that predate it.

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

### Media order (`UserFiles.sort_order`) + the 15s event-video limit

Both mirror the web app — see `web-app/CLAUDE.md` → "Profile media order" for the full rules.

- **Reorder writes go through the WEB APP, never Supabase.** `UserFiles` has no UPDATE RLS policy, so
  a direct `update({'sort_order': ...})` matches **0 rows and silently succeeds**.
  `ProfileRemoteDatasource.reorderFiles` PATCHes `/api/files/reorder` with a Bearer token (same shape
  as `deleteFile`, which already calls the web app). `orderedIds` must be the COMPLETE gallery — the
  server 409s on a partial list.
- **⚠️ `fetchUserFiles` orders `sort_order ASC, nullsFirst: false` then `id`.** Dropping
  `nullsFirst: false` makes every new upload (which leaves `sort_order` null) jump to the FRONT of the
  gallery, because Postgres sorts NULLs first on ASC. `sort_user_files.dart` is the Dart mirror of
  `web-app/src/helpers/sortUserFiles.ts` (both unit-tested — change together).
- `UserFile.sortOrder` is **optional** in the constructor on purpose: `job_content_remote_datasource`
  builds `UserFile(...)` by hand from raw rows, and a required field would break it.
- **Reordering UI is `LongPressDraggable` + `DragTarget` inside the existing `Wrap`**
  (`media_screen.dart` `_MediaSection`) — not `ReorderableListView`, which would force each gallery
  into a single-axis list and lose the wrap layout. Only `common`/`commonVideo` are draggable
  (`_canReorder`); `profile`/`profileVideo` are singletons. `_localFiles` holds the optimistic order
  and is cleared on failure so the UI snaps back rather than showing a phantom order.
- **⚠️ Profile video length is now ENFORCED on mobile** (`validate_profile_video.dart`,
  `kCommonVideoMaxSeconds` = **15**, `kProfileVideoMaxSeconds` = 60). Before this, the "maks 10 sek."
  text in `media_screen` was a **label only** — `pickVideo` had no `maxDuration` and nothing validated,
  so a 60s clip uploaded fine while the web app rejected it. There is no server-side ffprobe anywhere
  in the platform, so the client is the only gate on both platforms. Keep the constants in sync with
  `web-app/src/constants.ts` (`commonVideoMaxLengthSeconds` / `profileVideoMaxLengthSeconds`).

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

## ⚠️ A push deep-link fetches a BARE row — every "can I still act on this?" flag is missing

`NotificationsService.navigateTo` opens a job by doing `supabase.from('Jobs'|'ExtJobs').select()
.eq('id', ...).single()` and pushing the form. That row has **no joins**, so every field the browse
feed synthesises client-side is absent and silently defaults.

**The bug this caused (reported by a saxophonist):** `has_active_offer` is NOT a column — the feed
datasource injects it after joining `ServiceOffers` (`fetchNewInstrumentalistJobs` /
`fetchInstrumentalistExtJobs`, `{...j, 'has_active_offer': ...}`). `JobModel.fromJson` reads
`json['has_active_offer'] as bool? ?? false`, so on the deep-link path it was ALWAYS false and the
"Jobbet er desværre optaget" banner could never render. The deep link also never checked `status`.
Net effect: tapping an old `new_ext_job` push opened a normal, fully enabled form on a job that was
already `ready_for_billing` with another sax booked; the musician wrote a price and a sales pitch
and the first sign of trouble was the server rejecting the insert.

- The rule is the pure, unit-tested `features/jobs/domain/musician_job_availability.dart`
  (`resolveMusicianJobAvailability`), mirroring the feed queries + web `useExtJobsForMusicians` /
  `useAvailableJobsForMusicians`. It returns `biddable` / `wonByAnother` / `alreadyBid` /
  `closedForOffers`. Consumed via `musicianJobAvailabilityProvider(job)` in
  `instrumentalist_offer_form_screen`, which renders a hard block card and **hides "Send tilbud"**.
- **⚠️ A won offer is NOT the only way a job gets taken** — an admin-assigned musician leaves
  `assigned_musician_id` set with no offer row at all, so both are checked. That is the same
  resolution order the billing snapshot and iCal feed use. `assignedMusicianId` had to be threaded
  onto `Job`/`JobModel` and forwarded in `ExtJobModel.toJobModel()` for this.
- **⚠️ It fails CLOSED on an unknown/null status** — the opposite polarity to the feed's filters,
  and deliberate: this only guards the deep-link path, where the alternative is letting someone
  write an offer the server will reject anyway. Loading/lookup errors still default to `biddable`,
  because the server rejection remains the authoritative gate.
- `closed`/`customer_contacted` DO still accept sax offers (a booked DJ doesn't fill the sax slot);
  `ready_for_billing`/`canceled`/`expired` do not. Internal jobs use their own status set.
- **When you add any new "can I act on this?" signal to a feed row, check the deep-link path too** —
  it will NOT have it. Same root cause as the wave-gate banner below.

## Supply/matching wave gate: the quote form must guard independently

A DJ only sees a job once their cascade wave has opened. The feed is already correct with no Dart
involved (`GET /api/dj/biddable-jobs` runs the shared `selectBiddableJobsForDj`), but the QUOTE FORM
is reachable by **push deep-link** for a job the feed hides — most importantly an admin
"Send påmindelse", whose audience was not wave-filtered until `excludeWaveClosedDjs` shipped.

Before this, such a DJ saw a normal, fully-enabled form, wrote a price and a sales pitch, tapped
submit and got a toast — the first and only signal that they could never bid. (The toast did at
least carry the server's Danish reason: this screen reads `AppException.message` directly rather
than `friendlyErrorMessage()`, which would have swallowed it into a generic "Noget gik galt".)

- `jobWaveOpenProvider(jobId)` -> `JobsRepository.fetchJobWaveOpen` -> `GET /api/dj/jobs/{id}/wave-status`.
  Mobile cannot read `JobDjScores` (no RLS path; web reads its own rows), so the server resolves it —
  the same "resolve it server-side, key by job id" trick as `wants_ic` and the recurring-customer name.
- **⚠️ FAILS OPEN at every layer** (datasource catch, provider default, `?? true` at the call site).
  A slow or failed lookup must never block a real bid; the authoritative gate is the 403 from
  `POST /api/jobs/{id}/quotes`. This mirrors `helpers/jobWaveVisibility.ts` — never hide on absence
  of evidence.
- `_WaveClosedBanner` renders ABOVE the collision banner and before any input, and folds into
  `isBlocked` so submit is disabled. Styled `info`, not `danger`: nothing is wrong and there is
  nothing for the DJ to fix. Keep the copy in sync with the web card on `dj/jobs/[id]` and the 403
  body, and keep it about the JOB's state, never the DJ's standing.
- There are **no app links / associated domains configured**, so a pasted web URL cannot open the
  app — push is the only way in. Chat `@job:` chips are already safe (`resolveJobLink` reuses the
  wave-gated selector).

## Date-collision guard (no double-booking a date)

**⚠️ A colliding job no longer reaches the feed at all.** The shared server-side selector
(`web-app/src/domain/biddableJobs.ts`) now FILTERS colliding jobs out of `/api/dj/biddable-jobs`,
so "Nye jobs" simply never contains one. Previously they were returned and sorted last, and
`JobCard` rendered a dimmed, untappable "Dato-konflikt" badge — which the DJ could not act on and,
because `onTap` is nulled, could not tap to read the explanation on the quote form. That shipped as
a support question ("why does it say Dato-konflikt?"). This needed **no mobile release**.

The client-side pieces below stay as defence in depth: `jobs_shell_screen`'s per-row
`isDateColliding` still guards a stale cache, and the **quote form must keep its own check** because
it is reachable by push deep-link, which bypasses the feed entirely.


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

## Payment info readiness is payment-type aware (mirror of the web-app, self-billing phase 0)

`features/profile/domain/self_billing_complete.dart` mirrors `web-app/src/helpers/selfBillingComplete.ts`
function for function: `isPaymentInfoComplete(PaymentInfo.toReadinessInfo())` is what the two bid
gates (`dj_quote_form_screen`, `instrumentalist_offer_form_screen`) enforce, exactly like the web
Redirecter. Invoice needs a registered business (`sole_trader` or `aps`; **Invoice + Privat is never
complete**), CVR, billing email and bank; B-income needs CPR, bank and address. `payment_screen.dart`
hides the Privat card under Invoice (`_BusinessTypeSelector.allowPrivate`), warns on a legacy private
row, requires the CVR under Invoice, and shows the server-derived `cvrCompanyName` read-only (parsed
from `cvr_company_name`, never sent back). Tests: `test/features/profile/domain/self_billing_complete_test.dart`
mirrors the web test file; add cases to both.

## ⚠️ `Form.validate()` SKIPS fields the lazy `ListView` has unmounted — validate VALUES

Both bid forms lay their body out as `Form(child: ListView(children: [...]))`. A `ListView` is
lazy in **element** creation even with the non-builder constructor, so a field scrolled out of the
viewport is deactivated, and `FormFieldState.deactivate()` **unregisters it from the enclosing
`Form`**. `_formKey.currentState!.validate()` only walks the fields currently registered, so it
silently SKIPS the unmounted ones and returns `true`.

**The bug this caused (reported as "Man kan afgive bud på job uden at angive en pris (0 kr.)"):**
on `dj_quote_form_screen` the price input sits far above the submit button — payout box, equipment
picker and an 8-line salgstale field are in between, well past the default 250px `cacheExtent` — so
by the time the DJ taps "Afgiv bud" it is unmounted. A DJ who never typed a price passed validation
with `_price` falling back to `0`, and the customer got a 0 kr. bid.

- **The values are now checked by the pure `features/jobs/domain/offer_form_validation.dart`**
  (`validateDjQuoteInput` / `validateMusicianOfferInput`), which reads the controllers, not the
  tree, so it cannot be skipped. `Form.validate()` is still called so whatever IS mounted paints
  its inline error. Unit-tested in `test/features/jobs/domain/offer_form_validation_test.dart`.
- On failure the DJ gets a toast naming the problem **and** the form scrolls back to the top —
  the offending field is by definition probably off-screen, so an inline-only error is invisible.
- Server-side this is now also unbypassable: `POST /api/jobs/[job_id]/quotes` rejects a
  non-positive `price_dkk`, and the DB has `chk_quotes_price_positive` (migration
  `20260612000001`). The client fix is about the DJ seeing WHY, not about the data.
- **Any new required field on a long form needs the same treatment.** Rule of thumb: if the field
  can be scrolled off-screen before submit, `Form.validate()` is not a guarantee.

## "Nyt job" notifications self-expire once the job is taken

`features/notifications/domain/stale_bid_notifications.dart` — reported by a DJ: *"Kan man ikke
gøre, så appen fjerner notifikationer på jobs, når de er taget? Det er irriterende at skulle markere
fx 8 stk som læst."*

- Only the three **bid invitations** expire (`new_job`, `another_round`, `new_ext_job`). Every other
  type is about a job the user is already ON, so clearing it would hide something actionable.
  `isBidInvitationStale` returns false for anything outside that set.
- Resolved **client-side on every feed fetch** (`NotificationsNotifier._clearStaleBidInvitations` →
  `NotificationsDatasource.markStaleBidInvitationsRead`), because nothing server-side walks
  `UserNotifications` when a job closes — the row is written per recipient at send time and there is
  no trigger. It only ever marks rows **read**, never deletes: the row stays under "Alle", and a
  wrong call is recoverable.
- **It fails CLOSED in the safe direction.** A failed status lookup returns an empty set and leaves
  the feed untouched — a read error must never look like "every job is gone". An **unreadable** job
  row IS treated as stale, because for a performer that means archived (RLS hides it) or deleted.
- **DJs and saxophonists have different biddable-status sets on the SAME `Jobs` table**
  (`kJobStatusesOpenToQuotes` vs `kJobStatusesOpenToOffers` — a `closed` job still takes sax offers,
  because a booked DJ does not fill the sax slot). It branches on `data.role`; an unknown role uses
  the wider musician set so it under-clears. For `new_ext_job` a win shows up **two** ways
  (`assigned_musician_id` OR a won `ServiceOffers` row) and both are checked, same resolution order
  as `resolveMusicianJobAvailability`.

## "Jeg spillede ikke ekstra timer" — the answer is SERVER-side, per payee

`ExtraHours` cards used to have only two outcomes: log hours, or ignore them (and the day-after
`extra_hours_reminder` push) forever. Reported by a DJ who wanted a CTA to say no. The answer is
`extra_hours_declined_at` (migration `20260821000002`), set via
`PUT /api/{quotes|ext-jobs|service-offer}/{id}/extra-hours/declined` with `{declined: bool}`.

- **It must be server-side.** A local dismissal could hide the card but could never stop the push —
  `notify-extra-hours-reminder` filters `extra_hours_declined_at IS NULL` in all four buckets — and
  would not carry over to the web app.
- **One column per PAYEE row** (`Quotes` = DJ internal, `ExtJobs` = assigned DJ, `ServiceOffers` =
  musician), so a DJ declining on a `dj_and_musician` job does not silence the saxophonist.
- **Only offered while nothing is logged.** "I played no extra hours" contradicts an invoiceable
  amount; the server rejects that with `code: extra_hours_logged` rather than silently clearing it.
- Mobile: shared `features/jobs/presentation/widgets/decline_extra_hours.dart` +
  `declineExtraHoursProvider` (one notifier, an `ExtraHoursDeclineTarget` picks the row and the list
  to refresh). Used on all three screens. Web mirror: `src/components/DeclineExtraHours.tsx`.
- **⚠️ `ServiceOffers.extra_hours` is `NOT NULL DEFAULT 0`; `Quotes`/`ExtJobs` are nullable.** So on
  the musician screen "nothing logged" is **0, never null**. `_MusicianExtraHoursSection`'s old
  `extraHours != null` check was therefore ALWAYS true: every won offer read *"Du registrerede 0.0
  ekstra timer."* and offered only "Redigér" instead of the input, and the initState prefill wrote
  "0.0" into an untouched field. Both now use `> 0`, matching web's `offer.extra_hours <= 0`. Do
  not null-check that column.

## Birthday age is part of the lead, not just the won view

`Jobs.birthday_person_age` / `ExtJobs.birthday_person_age` is free text from the WordPress forms
("50", but also "halvtreds"). `core/utils/birthday_person_age.dart` `formatBirthdayPersonAge()`
mirrors web's `useFormatBirthdayPersonAge` — digits get " år", anything else is printed verbatim,
and it returns a **suffix** ("`, 50 år`") so call sites can concatenate unconditionally.

Reported by a DJ/sax: *"kan man ikke se Birthday Person Age inde på leadet"*. The field was parsed
into every model and rendered only on `ext_job_detail_screen` (won view) and `job_detail_screen`
(which **nothing routes to** — see the note at the top of that file), i.e. never on a lead. It is
now appended to the event-type heading on all four job surfaces: `dj_quote_form_screen`,
`instrumentalist_offer_form_screen`, `quote_detail_screen` and `service_offer_detail_screen`. Web
parity: only the DJ pages show it (`dj/jobs/[id]`, `dj/quotes/[id]`); the instrumentalist pages are
still a gap.

## ⚠️ An `autoDispose` StateNotifier that is only `ref.read` cannot publish state after an await

`ref.read(someProvider.notifier)` creates **no listener**. On an `autoDispose`
`StateNotifierProvider` that nothing `ref.watch`es, Riverpod therefore disposes the notifier on the
next scheduler pass — typically while the Supabase round-trip it just started is still in flight.
The write that lands afterwards throws:

> Bad state: Tried to use MarkAdminMessageReadNotifier after `dispose` was called.

**This fired on EVERY admin message a user opened.** `admin_messages_screen._toggle` did a
fire-and-forget `ref.read(markAdminMessageReadProvider.notifier).mark(...)` and then immediately
`ref.invalidate(adminMessagesProvider)`, and that invalidate is what triggered the dispose pass. The
DB write always landed — only the state write was invalid — so the message really did get marked
read while the app logged an unhandled exception.

- **Verified behaviour (probe test, Riverpod 2):** after disposal `_ref.invalidate(...)` /
  `_ref.read(...)` still work fine; **only `state =` throws**. So guarding the state writes is the
  complete fix — the refresh inside a notifier does not need a guard.
- **The fix pattern:** guard every `state =` after an await with `mounted`, and **return** the
  outcome (`Future<bool>`) instead of publishing it, because the caller would be reading a
  *different, freshly created* notifier instance by then. `MarkAdminMessageReadNotifier` does this;
  `RejectDjJobNotifier` and `DeleteExtJobEarlySetupNotifier` had the same shape and are now guarded
  too. Regression test: `test/features/profile/presentation/mark_admin_message_read_test.dart`
  (fails against the unguarded version).
- **Why most notifiers here are safe:** the screen `ref.watch`es them for a loading spinner
  (`billingLoading = ref.watch(markJobReadyForBillingProvider) is AsyncLoading`), which is a real
  listener and keeps them alive. **The audit is "is this provider `watch`ed anywhere?"** — if not,
  it needs the guard.
- **Also await before refreshing.** The old code invalidated the list alongside the un-awaited mark,
  so the refetch could land before the UPDATE and return the message still unread — the card flipped
  back to the unread style. `_toggle` now awaits, then invalidates, and toasts on failure (it was
  previously silent).

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
