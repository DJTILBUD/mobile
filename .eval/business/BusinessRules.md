# Business rules

_Each rule is sourced verbatim, marked verifiable (yes/no), and linked to the components it governs._

### Rule 1

Musicians on the platform offer their service as either a DJ or a Saxophonist.

- **Verifiable:** ✅ yes
- **Sources:**
  - `About_the_organisation.md`: "Mobile app for DJTILBUD which is a 2 sided marketplace for customers seeking musicians for events and musicians that makes quotes on these requests, offering a service as either DJ og Saxopohnists."
  - `About_the_organisation.md`: "Yes around 140 musicans are using the app, both DJs and Saxophonists."
- **Components:** _no linked components_

### Rule 2

The mobile app is the musician-facing side of the marketplace, not the customer-facing side.

- **Verifiable:** ✅ yes
- **Sources:**
  - `About_the_organisation.md`: "The app is the musician facing part, where musician can create their profiles, upload iamges and reviews of them selves and maek quotes for jobs."
- **Components:** _no linked components_

### Rule 3

Musicians can create their profiles, upload images and reviews of themselves, and make quotes for jobs in the app.

- **Verifiable:** ✅ yes
- **Sources:**
  - `About_the_organisation.md`: "The app is the musician facing part, where musician can create their profiles, upload iamges and reviews of them selves and maek quotes for jobs."
- **Components:** _no linked components_

### Rule 4

The product contains exactly two AI features: a quote/sales-pitch drafting assistant and the profile-coach.

- **Verifiable:** ✅ yes
- **Sources:**
  - `About_the_organisation.md`: "There exists 2 AI's in the product."
  - `About_the_organisation.md`: "One that helps the musicians write a quote (it gives a draft for the sales pitch) and another called "profile-coach" that helps them figuring out what is missing and what they should add to finalize a good profile"
- **Components:**
  - `web-app/supabase/functions/agent-assist/prompts::PITCH_GUIDELINES`, matched on named by the model while reading the business documents
  - `web-app/supabase/functions/agent-assist/prompts::PROFILE_COACH_GUIDELINES`, matched on named by the model while reading the business documents

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
