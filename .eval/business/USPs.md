# Unique selling propositions

_Each USP is sourced to a business document (verbatim) and mapped to the components that deliver it._

## AI quote-writing assistant

An AI helps musicians write a quote by giving them a draft for the sales pitch they send in response to a customer's request.

- **Sources:**
  - `About_the_organisation.md`: "There exists 2 AI's in the product."
  - `About_the_organisation.md`: "One that helps the musicians write a quote (it gives a draft for the sales pitch) and another called "profile-coach" that helps them figuring out what is missing and what they should add to finalize a good profile"
- **Delivered by:**
  - `lib/features/agent/presentation/widgets/agent_bottom_sheet.dart::_DraftText`, matched on name "draft" in _DraftText; module "assistant" in module lib/features/agent; module "miss" in module lib/features/agent; +5 more
  - `web-app/supabase/functions/agent-assist/prompts::PITCH_GUIDELINES`, matched on named by the model while reading the business documents
  - `web-app/supabase/functions/agent-assist/prompts::AGENT_BEHAVIOUR`, matched on named by the model while reading the business documents
  - `web-app/supabase/functions/agent-assist/prompts::DOMAIN_CONTEXT`, matched on named by the model while reading the business documents
  - `lib/features/jobs/presentation/screens/dj_quote_form_screen.dart::DjQuoteFormScreen`, matched on named by the model while reading the business documents

## AI profile-coach

An AI called "profile-coach" helps musicians figure out what is missing from their profile and what they should add to finalize a good profile.

- **Sources:**
  - `About_the_organisation.md`: "There exists 2 AI's in the product."
  - `About_the_organisation.md`: "One that helps the musicians write a quote (it gives a draft for the sales pitch) and another called "profile-coach" that helps them figuring out what is missing and what they should add to finalize a good profile"
- **Delivered by:**
  - `web-app/supabase/functions/agent-assist/prompts::PROFILE_COACH_GUIDELINES`, matched on named by the model while reading the business documents
  - `web-app/supabase/functions/agent-assist/prompts::PROFILE_BIO_GUIDELINES`, matched on named by the model while reading the business documents

## Two-sided marketplace for DJs and saxophonists

DJTILBUD connects customers seeking musicians for events with musicians (DJs and saxophonists) who make quotes on those requests, with a dedicated musician-facing mobile app.

- **Sources:**
  - `About_the_organisation.md`: "Mobile app for DJTILBUD which is a 2 sided marketplace for customers seeking musicians for events and musicians that makes quotes on these requests, offering a service as either DJ og Saxopohnists."
  - `About_the_organisation.md`: "The app is the musician facing part, where musician can create their profiles, upload iamges and reviews of them selves and maek quotes for jobs."
- **Delivered by:** _no linked components_

## Coverage

- **Statements linked to code:** 3 of 7 · rule: 1/4 · usp: 2/3
- **Artifacts reached from the business:** 7 of 3511 linkable artifacts in the scan
- **How the links were made:** candidates from names, paths, routes and endpoints in your own code, confirmed by the model.

### Reach by area

- Web app: 5 of 2734
- Jobs: 1 of 242
- Profile: 0 of 132
- Core: 0 of 89
- Chat: 0 of 59
- Agent: 1 of 38
- Featured jobs: 0 of 28
- Design system: 0 of 26
- Referrals: 0 of 25
- Calendar: 0 of 22
- Onboarding: 0 of 21
- Notifications: 0 of 16
- Shared: 0 of 16
- Redirecter: 0 of 13
- Auth: 0 of 12
- First win: 0 of 10
- Other: 0 of 9
- App config: 0 of 8
- Global error: 0 of 2
- Layout: 0 of 2
- Page: 0 of 2
- Providers: 0 of 2
- Route extra survives keyboard test: 0 of 2
- Suppression: 0 of 1

### Linked to nothing (4)

- **usp** Two-sided marketplace for DJs and saxophonists: The only words that matched a name, path or route are too short to mean one thing (part, quot), and a three- or four-letter stem matches by accident across two languages. Something longer has to match the same artifact.
- **rule** Musicians on the platform offer their service as either a DJ or a Saxophonist.: 2 candidate(s) were offered and the model confirmed none of them.
- **rule** The mobile app is the musician-facing side of the marketplace, not the customer-facing side.: 2 candidate(s) were offered and the model confirmed none of them.
- **rule** Musicians can create their profiles, upload images and reviews of themselves, and make quotes for jobs in the app.: 2 candidate(s) were offered and the model confirmed none of them.

## Gaps

_None. All material was sourced._
