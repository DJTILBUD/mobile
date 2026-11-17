# Module: web-app/supabase [AI]

Provides Supabase Edge Functions (Deno runtime) for AI generation (sales pitch drafting and profile coach via Anthropic Claude), Firebase Cloud Messaging (FCM) push notifications and in-app feed logging for DJ and musician marketplace events, and AES-256-GCM encrypted storage for sensitive payout/payment details.

## Key files
- `web-app/supabase/functions/agent-assist/index.ts`: Edge function providing AI sales pitch drafting, summary generation, profile bio generation, and step-by-step profile coach feedback using Anthropic Claude.
- `web-app/supabase/functions/agent-assist/prompts.ts`: System prompts and formatting guidelines for sales pitch writing, profile coaching, and musician bios based on domain rules.
- `web-app/supabase/functions/_shared/fcm.ts`: Shared helper for generating Google OAuth2 access tokens from service accounts and dispatching push notifications via Firebase Cloud Messaging HTTP v1 API.
- `web-app/supabase/functions/_shared/notification_log.ts`: Shared helper writing analytics events to NotificationLogs and in-app feed entries to UserNotifications.
- `web-app/supabase/functions/_shared/auth.ts`: Shared authorization helpers for bearer token and custom header secret verification.
- `web-app/supabase/functions/payment-info/index.ts`: Edge function for retrieving and storing encrypted musician and DJ payment/banking info (PrivateDjInfos and PrivateMusiciansInfo) using AES-256-GCM.
- `web-app/supabase/functions/notify-new-job/index.ts`: Edge function triggered on new or reopened marketplace jobs to match available DJs/musicians and send push notifications.
- `web-app/supabase/functions/notify-chat-message/index.ts`: Edge function notifying DJs, musicians, or admins of new chat messages and support inquiries.

## Public interface
- POST agent-assist: Generates sales pitch, profile bio, summary, or profile-coach recommendations via Anthropic API
- GET/POST payment-info: Fetches or upserts AES-256-GCM encrypted payment/banking records for authenticated DJs or musicians
- POST notify-new-job, notify-new-ext-job: Dispatches push notifications to eligible musicians/DJs for new or reopened jobs
- POST notify-job-reminder: Sends job availability reminders to targeted unbid musicians or DJs
- POST notify-quote-status, notify-service-offer-status: Dispatches push notifications when a quote or service offer is won or lost
- POST notify-chat-message, notify-chat-reaction, notify-chat-reminder: Handles chat and support thread push notifications and reminders
- POST notify-process-reminder, notify-ready-reminder, notify-extra-hours-reminder, notify-delivery-reminder, notify-content-reminder, notify-content-status, notify-referral-status, notify-ext-job-assigned, notify-song-request, notify-admin-message, notify-custom: Workflow-specific push notifications and reminder triggers
- POST notify-log-received: Logs push notification delivery confirmations from client background handlers using x-log-secret authentication
- export function getFcmAccessToken(sa: ServiceAccount): Promise<string>
- export function sendFcmPush(opts: { tokens: string[]; title: string; body: string; data?: Record<string, string>; projectId: string; accessToken: string }): Promise<void>
- export function logNotificationSent(supabase: SupabaseClient, events: NotificationSentEvent[]): Promise<void>
- export function isAuthorizedBearer(req: Request, fnName: string, extraSecrets?: Array<string | undefined | null>): boolean
- export function isAuthorizedHeaderSecret(req: Request, headerName: string, expected: string | undefined | null, fnName: string): boolean

## Dependencies
- npm:@anthropic-ai/sdk@0.30.0
- npm:@supabase/supabase-js@2
- Firebase Cloud Messaging HTTP v1 API (https://fcm.googleapis.com/v1/projects/...)
- Google OAuth2 Token API (https://oauth2.googleapis.com/token)
- Web Crypto API (AES-GCM, RSASSA-PKCS1-v1_5)

## AI touchpoints [AI]
- `web-app/supabase/functions/agent-assist/index.ts`
- `web-app/supabase/functions/agent-assist/prompts.ts`
- `web-app/supabase/functions/deno-globals.d.ts`

## Open questions
- _none_
