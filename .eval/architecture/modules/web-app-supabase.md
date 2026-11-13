# Module: web-app/supabase [AI]

Provides Supabase Edge Functions handling Firebase Cloud Messaging (FCM) push notifications and in-app feed logging for marketplace events, secure AES-256-GCM encrypted payment and tax data management, and LLM-powered assistant capabilities (sales pitch generation and profile coaching via Anthropic).

## Key files
- `web-app/supabase/functions/agent-assist/index.ts`: Deno edge function invoking Anthropic SDK for sales pitch writing ('Skriv med AI') and profile coaching
- `web-app/supabase/functions/agent-assist/prompts.ts`: System prompts and behavioral guidelines for pitch generation and profile coaching
- `web-app/supabase/functions/payment-info/index.ts`: Edge function for reading and saving encrypted private banking and tax information (AES-256-GCM)
- `web-app/supabase/functions/_shared/fcm.ts`: Google OAuth2 service account authentication and Firebase Cloud Messaging v1 push dispatcher
- `web-app/supabase/functions/_shared/notification_log.ts`: Shared logging utility recording notification sends to NotificationLogs and UserNotifications feed tables
- `web-app/supabase/functions/_shared/auth.ts`: Shared authorization token and header normalization utilities for edge functions
- `web-app/supabase/functions/notify-new-job/index.ts`: Push notification dispatcher alerting eligible DJs and musicians when a new job is posted or reopened
- `web-app/supabase/functions/notify-chat-message/index.ts`: Push notification dispatcher for direct messages, replies, and admin support messages

## Public interface
- POST /agent-assist - LLM agent endpoints for sales pitch generation, profile bio, and profile coaching
- GET/POST /payment-info - Fetch or update encrypted payment, CPR, and billing address data
- POST /notify-admin-message - Push notification for broadcast or targeted admin messages
- POST /notify-chat-message - Push notification trigger on new chat messages
- POST /notify-chat-reaction - Push notification trigger on message reactions
- POST /notify-chat-reminder - Scheduled reminder for uninitiated chat conversations
- POST /notify-content-reminder - Push reminder to record or upload gig content
- POST /notify-content-status - Push notification for verified or rejected content uploads
- POST /notify-custom - Push notification for custom ad-hoc messages
- POST /notify-delivery-reminder - Push reminder for equipment logistics and gear deliveries
- POST /notify-ext-job-assigned - Push notification when assigned to external jobs
- POST /notify-extra-hours-reminder - Scheduled reminder for performers to report extra event hours
- POST /notify-job-reminder - Admin-triggered push re-notifying available performers about open jobs
- POST /notify-log-received - Callback for mobile clients to log received push notifications
- POST /notify-new-ext-job - Push notification for new external jobs matching saxophonists/musicians
- POST /notify-new-job - Push notification for new open marketplace jobs matching available DJs and saxophonists
- POST /notify-process-reminder - Scheduled reminder to contact customers or mark invoices ready
- POST /notify-quote-status - Push notification when a DJ's quote is won or lost
- POST /notify-ready-reminder - Pre-event reminder to confirm readiness for upcoming gigs
- POST /notify-referral-status - Push notification alerting referrers when referral jobs close or cancel
- POST /notify-service-offer-status - Push notification when a musician's service offer is won or lost
- POST /notify-song-request - Push notification alerting DJs of incoming guest song requests

## Dependencies
- npm:@anthropic-ai/sdk@0.30.0
- npm:@supabase/supabase-js@2
- Firebase Cloud Messaging (FCM v1 API)
- Google OAuth2 API (https://oauth2.googleapis.com/token)
- Web Crypto API (AES-GCM, RSASSA-PKCS1-v1_5, SHA-256)

## AI touchpoints [AI]
- `web-app/supabase/functions/agent-assist/index.ts`
- `web-app/supabase/functions/agent-assist/prompts.ts`
- `web-app/supabase/functions/deno-globals.d.ts`

## Open questions
- _none_
