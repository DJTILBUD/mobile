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

The "typecheck + tests" done-bar for this app = `flutter analyze` + `flutter test` (this folder already has a fuller "Definition of done" checklist at the bottom).

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
| `new_ext_job` | musician | `/instrumentalist/home` → `extJobDetail` |
| `ext_job_assigned` | dj | `/dj/featured` → `extJobDetail` |
| `ext_job_assigned` | musician | `/instrumentalist/home` → `extJobDetail` |
| `quote_won/lost` | dj | `/dj/home` → `quoteDetail` |
| `offer_won/lost` | musician | `/instrumentalist/home` → `serviceOfferDetail` |
| `chat_message` | dj | `/dj/chat` → `conversationDetail` |
| `chat_message` | musician | `/instrumentalist/chat` → `conversationDetail` |
| `ready_reminder` | dj | `/dj/home` or `/dj/featured` → quote or extJobDetail |
| `ready_reminder` | musician | `/instrumentalist/home` → `serviceOfferDetail` |
| `admin_message` | dj | `/dj/profile` → `adminMessages` |
| `admin_message` | musician | `/instrumentalist/profile` → `adminMessages` |
| `custom_notification` | any | no navigation (dismisses) |

**Foreground notifications:** system banners are suppressed. `inAppNotificationProvider` (StateProvider) holds the current `RemoteMessage?` and drives an in-app banner instead.

**Token registration:** upserted to `DeviceTokens` on app start and after login. Deleted on logout. On iOS, waits for APNs token before registering.

## Job-content fields shown to musicians (what they may/may not see)

Musicians must see **all** customer-facing job content; never `internal_notes`/`internal_note` (admin-only — these are NOT parsed into any mobile model). The relevant fields per source:
- **Jobs:** `lead_request` ("Kundens ønske") + `additional_information` ("Yderligere information") + `musician_special_request` ("Særligt ønske til musikeren").
- **ExtJobs:** `notes` ("Noter") + `musician_special_request`.

A musician can reach an ext job via **two** rendering paths — keep field display in sync across both:
1. **Browse feed → `instrumentalist_offer_form_screen.dart`.** `JobsRepositoryImpl.fetchInstrumentalistExtJobs` maps `ExtJobModel.toJobEntity()` → a `Job` where **`leadRequest` = ExtJobs.notes** and `musicianSpecialRequest` carries over. So this one screen renders both real Jobs and ext-jobs-as-Jobs; it must show `leadRequest`, `additionalInformation`, `musicianSpecialRequest`.
2. **`new_ext_job`/`ext_job_assigned` notification → `ExtJobDetailScreen`** (takes a real `ExtJob` entity). Shows `notes` + `musicianSpecialRequest`. Note: `ExtJobModel` parses `musician_special_request` but `toEntity()` must explicitly pass it through (it was previously dropped).

## Login must not flash the role-select / onboarding screen

The GoRouter `redirect` in `app.dart` gates on `_onboardingNotifier.resolved` — a flag that is only true once we actually know the session's role + onboarding status. On `signIn()`, Supabase fires the `signedIn` event (→ router refresh) **before** `RoleCache.save(role)` runs, so for a moment the user is authenticated with `RoleCache.role == null`; without the gate the redirect sent them to `/profile-setup` (the "DJ or musician?" screen) for ~0.5s before bouncing home. Rule: **after any `RoleCache.save(...)`, `await initOnboardingStatus()` before navigating** (see `login_screen.dart` and all four save sites in `profile_setup_screen.dart`) so `resolved` is set and the redirect routes correctly (home vs `/onboarding`). While `resolved` is false the redirect returns `null` (stay put) instead of routing to setup/onboarding. `initOnboardingStatus()` is also awaited in `main()` before `runApp`, so cold-start is already resolved.

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

## DJ content capture (feature 52)

Step 5 of the DJ job process: short clips (max 15s, 9:16) recorded per job. `quote_detail_screen` + `ext_job_detail_screen` show a reminder/CTA (`features/jobs/presentation/widgets/job_content_section.dart`) once `djReadyConfirmedAt != null`; tapping it opens **`MyContentScreen`** (`AppRoutes.myContent`, profile menu "Mit content", DJ-only) scoped to that job via a `JobContentKey` `extra`. That screen is the library of **all** the DJ's clips (labelled by job) + the scoped uploader + delete. Data: `job_content_remote_datasource.dart` (`fetchMyJobContent`) + `job_content_provider.dart` (`myJobContentProvider`).

- **Uploads go to AWS S3, not Supabase Storage** (the tech-stack table above is misleading for media). Flow: `GET /api/files/signed-url` → `PUT` to S3 → `POST /api/files/job-content` (verifies the DJ owns the job server-side). Do NOT direct-insert `UserFiles` for `job_content` — that bypasses ownership checks (same spirit as the Quotes/Jobs rules below).
- 15s / 9:16 is hard-validated client-side via `validateContentVideo` (`video_player` duration + aspectRatio) — there is no server-side ffprobe.
- A thumbnail is generated on upload via `video_thumbnail` and uploaded as a separate `thumbnail` row, so web + admin (and the in-app list) show a real preview.
- Notification types `content_record_reminder` / `content_upload_reminder` are DJ-only and routed exactly like `ready_reminder` in `notifications_service.dart`.

## Date-collision guard (no double-booking a date)

A DJ may not bid on a date where they already have a won quote (or 2 pending quotes, or a confirmed external job). The rule mirrors the web `collidingQuote` helper and now lives in **`lib/features/jobs/domain/date_collision.dart`** (`isDateColliding` → bool for the job list; `dateCollisionMessage` → Danish reason for the form banner). Used in two places: the job list (`jobs_shell_screen.dart` dims the card + nulls `onTap`) **and** the DJ quote form (`dj_quote_form_screen.dart` shows a `_CollisionBanner` + disables submit). The form must guard independently because it's reachable via **push deep-link**, bypassing the list. This is a client mirror only — the **authoritative** enforcement is server-side in the web `POST /api/jobs/[job_id]/quotes` route (returns 409, surfaced via the submit-error toast). Keep all three (web helper, mobile helper, both screens) in sync.

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

## Definition of done

- [ ] Works on both iOS and Android
- [ ] Handles loading, error, and empty states
- [ ] Does not break existing Supabase data
- [ ] Push notifications work for the relevant flow (if applicable)
- [ ] AI interactions stream and never block UI (if applicable)
- [ ] Three-layer architecture respected — no Supabase in domain, no business logic in build()
- [ ] Realtime subscriptions cancelled in `ref.onDispose()`
- [ ] No secrets hardcoded
