# Mobile App — Flutter (Musician-facing)

Flutter app for musicians: browse jobs, submit offers, manage profile, use the AI pitch agent. Runs in parallel with the web-app — both serve live musicians.

This is also a **master's thesis** on evaluating LLM interaction quality as actionable feedback when building an AI-assisted app. Every AI/agent design decision must serve both product goals and research observability.

## ALWAYS READ THESE FOUR FOLDERS FIRST

Before building or changing anything, read the relevant folder(s) below. They are the memory of the system.

| Folder | What it contains |
|---|---|
| `architecture/` | How the app is built — three-layer rule, Riverpod patterns, routing, error handling, naming |
| `design-system/` | UI components, Figma MCP connection, theme, shared widgets, icon and font conventions |
| `webapp-reference/` | The existing DJTilbud web platform — domain knowledge, data structures, feature logic |
| `ai-agent/` | How the AI pitch agent works — interaction rules, model settings, logging, thesis observability |

## Tech stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) — latest stable |
| Platform | iOS + Android |
| Backend | Supabase (shared with all other apps) |
| Auth | Supabase Auth |
| Realtime | Supabase Realtime |
| Storage | Supabase Storage |
| Push notifications | Firebase Cloud Messaging (FCM) |
| AI agent | Anthropic Claude API via Supabase Edge Function |
| State management | Riverpod 2.0+ with code generation |
| Navigation | go_router |

## Environments and build commands

```bash
flutter run                        # local (default — always use this)
flutter run --dart-define=ENV=dev  # staging
flutter run --dart-define=ENV=prod # production
```

Env files: `.env.local` (default), `.env.dev`, `.env.prod`, `.env.example` (only one in git).

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

## Song request QR (per-DJ, DJ-only)

The song-request QR is **per-DJ**, shown on the profile (`profile_screen.dart`, DJ-only menu item → `widgets/song_request_qr_dialog.dart`). It encodes `DjProfile.songRequestToken` (`DjInfos.song_request_token`); the web backend resolves it to the DJ's next upcoming event at scan time.

- The old **per-event** QR on `song_requests_screen.dart` was removed (that screen now only lists requests). Its call sites in `quote_detail_screen.dart` and `ext_job_detail_screen.dart` no longer pass `songRequestToken`.
- `Job`/`ExtJob` models still parse `song_request_token`, but it is no longer used in the UI.

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
- Do NOT submit **DJ quotes** with a direct `Quotes` insert — POST to the web API `/api/jobs/{job_id}/quotes` (via `_webApiPost`, like `createServiceOffer` does). The "3 pending quotes → job goes `sent`" transition (plus `first_quote_only` send, suppression and tier-quota checks) lives ONLY in that route handler — **there is no DB trigger**. A direct insert leaves the job stuck in `open`. The route returns the **bare** quote row (no `job` join), so `DjQuoteModel.fromJson` tolerates a missing `job` key. (`editDjQuote` may stay a direct Supabase update — editing a pending quote doesn't change the pending count.)
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
