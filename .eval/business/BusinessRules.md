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

Musicians can browse customer jobs, make quotes on them, and see their sent and won quotes.

- **Verifiable:** ✅ yes
- **Sources:**
  - `About_the_organisation.md`: "The mobile app is used only by the musician to browse through customer jobs, make quotes on them,  see their sent and won quotes."
- **Components:** _no linked components_

### Rule 3

Musicians can change their profile settings, including name, images, reviews and billing settings.

- **Verifiable:** ✅ yes
- **Sources:**
  - `About_the_organisation.md`: "They can also change their profile settings, including their name, images, add reviews and billing settings ect."
- **Components:** _no linked components_

### Rule 4

The product has exactly two AI parts: "skriv med AI" (sales pitch writing) and the profile coach.

- **Verifiable:** ✅ yes
- **Sources:**
  - `About_the_organisation.md`: "There is 2 different AI parts in the program."
  - `About_the_organisation.md`: "First of all there is a "skriv med AI" which features a possibility to make AI write the "sales pitch" to each new open job."
  - `About_the_organisation.md`: "The second part is called the profile coach, that can help users finish and polish their profile"
- **Components:**
  - `web-app/supabase/functions/agent-assist/prompts::PITCH_GUIDELINES`, matched on named by the model while reading the business documents
  - `web-app/supabase/functions/agent-assist/prompts::PROFILE_COACH_GUIDELINES`, matched on named by the model while reading the business documents

### Rule 5

The "skriv med AI" feature writes a sales pitch for each new open job.

- **Verifiable:** ✅ yes
- **Sources:**
  - `About_the_organisation.md`: "First of all there is a "skriv med AI" which features a possibility to make AI write the "sales pitch" to each new open job."
- **Components:**
  - `web-app/supabase/functions/agent-assist/prompts::PITCH_GUIDELINES`, matched on named by the model while reading the business documents

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
