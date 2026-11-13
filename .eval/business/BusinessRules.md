# Business rules

_Each rule is sourced verbatim, marked verifiable (yes/no), and linked to the components it governs._

### Rule 1

The mobile app is used only by musicians (DJs and Saxophonists), not by customers.

- **Verifiable:** ✅ yes
- **Sources:**
  - `About_the_organisation.md`: "The mobile app is used only by the musician to browse through customer jobs, make quotes on them,  see their sent and won quotes."
  - `About_the_organisation.md`: "Yes musicians use the app which is Djs and Saxohponists"
- **Components:** _no linked components_

### Rule 2

Musicians can browse customer jobs, make quotes on them, and see their sent and won quotes in the app.

- **Verifiable:** ✅ yes
- **Sources:**
  - `About_the_organisation.md`: "The mobile app is used only by the musician to browse through customer jobs, make quotes on them,  see their sent and won quotes."
- **Components:** _no linked components_

### Rule 3

Musicians can change profile settings including name, images, reviews and billing settings.

- **Verifiable:** ✅ yes
- **Sources:**
  - `About_the_organisation.md`: "They can also change their profile settings, including their name, images, add reviews and billing settings ect."
- **Components:**
  - `lib/features/profile/domain/entities/billing_change_request.dart::BillingChangeRequest`, matched on name "change" in BillingChangeRequest; name "bill" in BillingChangeRequest; module "setting" in module lib/features/profile; +1 more
  - `lib/features/profile/presentation/widgets/billing_lock_card.dart::_RequestChangeDialog`, matched on name "change" in _RequestChangeDialog; path "bill" in lib/features/profile/presentation/widgets/billing_lock_card.dart; module "setting" in module lib/features/profile; +1 more

### Rule 4

The "skriv med AI" feature offers to write the sales pitch for each new open job.

- **Verifiable:** ✅ yes
- **Sources:**
  - `About_the_organisation.md`: "First of all there is a "skriv med AI" which features a possibility to make AI write the "sales pitch" to each new open job."
- **Components:**
  - `lib/features/jobs/presentation/widgets/job_content_section.dart::JobContentSection`, matched on named by the model while reading the business documents

## Coverage

- **Statements linked to code:** 3 of 7 · rule: 2/4 · usp: 1/3
- **Artifacts reached from the business:** 3 of 716 linkable artifacts in the scan
- **How the links were made:** candidates from names, paths, routes and endpoints in your own code, confirmed by the model.

### Reach by area

- Jobs: 1 of 208
- Profile: 2 of 128
- Core: 0 of 89
- Chat: 0 of 59
- Agent: 0 of 38
- Featured jobs: 0 of 28
- Design system: 0 of 26
- Referrals: 0 of 25
- Calendar: 0 of 22
- Onboarding: 0 of 21
- Notifications: 0 of 16
- Shared: 0 of 15
- Auth: 0 of 12
- First win: 0 of 10
- Other: 0 of 9
- App config: 0 of 8
- Route extra survives keyboard test: 0 of 2

### Linked to nothing (4)

- **usp** AI profile coach: The only words that matched a name, path or route are too short to mean one thing (user), and a three- or four-letter stem matches by accident across two languages. Something longer has to match the same artifact.
- **usp** Two-sided marketplace for DJs and Saxophonists: The only words that matched a name, path or route are too short to mean one thing (app, quot, send, won), and a three- or four-letter stem matches by accident across two languages. Something longer has to match the same artifact.
- **rule** The mobile app is used only by musicians (DJs and Saxophonists), not by customers.: The only words that matched a name, path or route are too short to mean one thing (app, quot, won), and a three- or four-letter stem matches by accident across two languages. Something longer has to match the same artifact.
- **rule** Musicians can browse customer jobs, make quotes on them, and see their sent and won quotes in the app.: The only words that matched a name, path or route are too short to mean one thing (app, quot, won), and a three- or four-letter stem matches by accident across two languages. Something longer has to match the same artifact.

## Gaps

_None. All material was sourced._
