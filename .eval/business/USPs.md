# Unique selling propositions

_Each USP is sourced to a business document (verbatim) and mapped to the components that deliver it._

## Two-sided marketplace for DJs and Saxophonists

DJTILBUD is an online two-sided marketplace where customers request DJs and Saxophonists for their events, and musicians use the mobile app to find and quote on those jobs.

- **Sources:**
  - `About_the_organisation.md`: "Mobile app for DJTILBUD, which is an online two-sided marketplace where customers can request for DJs and Saxophonists to their events."
  - `About_the_organisation.md`: "The mobile app is used only by the musician to browse through customer jobs, make quotes on them,  see their sent and won quotes."
- **Delivered by:** _no linked components_

## "Skriv med AI" sales pitch writer

Musicians can have AI write the sales pitch for each new open job instead of drafting it themselves.

- **Sources:**
  - `About_the_organisation.md`: "There is 2 different AI parts in the program."
  - `About_the_organisation.md`: "First of all there is a "skriv med AI" which features a possibility to make AI write the "sales pitch" to each new open job."
- **Delivered by:**
  - `lib/features/agent/presentation/widgets/agent_bottom_sheet.dart::_DraftText`, matched on name "draft" in _DraftText; module "skriv" in module lib/features/agent; module "writ" in module lib/features/agent; +2 more
  - `web-app/supabase/functions/agent-assist/prompts::PITCH_GUIDELINES`, matched on named by the model while reading the business documents
  - `web-app/supabase/functions/agent-assist/prompts::AGENT_BEHAVIOUR`, matched on named by the model while reading the business documents

## Profile coach

An AI profile coach helps musicians finish and polish their profile.

- **Sources:**
  - `About_the_organisation.md`: "There is 2 different AI parts in the program."
  - `About_the_organisation.md`: "The second part is called the profile coach, that can help users finish and polish their profile"
- **Delivered by:**
  - `web-app/supabase/functions/agent-assist/prompts::PROFILE_COACH_GUIDELINES`, matched on named by the model while reading the business documents
  - `web-app/supabase/functions/agent-assist/prompts::PROFILE_BIO_GUIDELINES`, matched on named by the model while reading the business documents

## Coverage

- **Statements linked to code:** 4 of 8 · rule: 2/5 · usp: 2/3
- **Artifacts reached from the business:** 5 of 3472 linkable artifacts in the scan
- **How the links were made:** candidates from names, paths, routes and endpoints in your own code, confirmed by the model.

### Reach by area

- Web app: 4 of 2734
- Jobs: 0 of 208
- Profile: 0 of 128
- Core: 0 of 89
- Chat: 0 of 59
- Agent: 1 of 38
- Featured jobs: 0 of 28
- Design system: 0 of 26
- Referrals: 0 of 25
- Calendar: 0 of 22
- Onboarding: 0 of 21
- Notifications: 0 of 16
- Shared: 0 of 15
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

- **usp** Two-sided marketplace for DJs and Saxophonists: 1 candidate(s) were offered and the model confirmed none of them.
- **rule** The mobile app is used only by musicians (DJs and Saxophonists), not by customers.: The only words that matched a name, path or route are too short to mean one thing (djs, quot, sent, won), and a three- or four-letter stem matches by accident across two languages. Something longer has to match the same artifact.
- **rule** Musicians can browse customer jobs, make quotes on them, and see their sent and won quotes.: The only words that matched a name, path or route are too short to mean one thing (quot, sent, won), and a three- or four-letter stem matches by accident across two languages. Something longer has to match the same artifact.
- **rule** Musicians can change their profile settings, including name, images, reviews and billing settings.: 1 candidate(s) were offered and the model confirmed none of them.

## Gaps

_None. All material was sourced._
