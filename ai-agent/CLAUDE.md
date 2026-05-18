# AI Agent

This folder governs two distinct AI features in the app. Before building or modifying either one, read the files in the order shown below.

---

## Canonical prompt files

**The `.md` files in this folder are developer documentation only — they are not what Claude reads at runtime.**

The live prompt files that Claude actually receives are in:
```
web-app/supabase/functions/agent-assist/prompts/
├── domain-context.md        ← platform background, musician personas, research grounding
├── agent-behaviour.md       ← tone, interaction style, what Claude must never do
├── pitch-guidelines.md      ← pitch-specific rules, format, character limit, examples
├── summary-guidelines.md    ← job summary rules
├── profile-bio-guidelines.md
└── profile-coach-guidelines.md
```

**To change Claude's behavior, edit those files — not this folder and not the TypeScript code.**

The Edge Function reads them at cold start, concatenates the relevant files for the current `purpose`, caches the static portion via Anthropic prompt caching, and appends the dynamic job/profile data per request.

## Reading map (for understanding the system)

| File | What it contains |
|---|---|
| `domain-context.md` | What DJTilbud is, how jobs flow, the closing rate problem, who the musicians are, and why the agent exists. |
| `agent-behaviour.md` | Shared tone, interaction style, what the agent must never do. |

### Agent-specific files

| If you are building... | Read |
|---|---|
| The **pitch agent** | `pitch-guidelines.md` |
| The **profile coach** | `profile-coach-guidelines.md` + `profile-bio-guidelines.md` |

If you are building something that touches both (e.g. a shared AI service layer, the Edge Function, or the AgentInteractions logging), read all files in the `prompts/` directory.

---

## What the two agents do

**Pitch agent** (`pitch-guidelines.md`)
- Triggered when a musician opens a job request and taps "Get AI Help"
- Reads the job details + musician profile into context
- Asks 1–2 short questions about the event
- Generates 2–3 pitch variations for the musician to choose from and edit
- Goal: a personal, specific, well-written pitch that wins the job

**Profile coach** (`profile-guidelines.md`)
- Triggered from the musician's profile screen
- Reads the current profile state (photo, videos, bio, reviews)
- Identifies the single highest-impact gap
- Gives one specific, actionable improvement — then moves to the next gap only after the first is addressed
- Goal: a complete profile that builds customer trust before they read the pitch

---

## Technical implementation

**Never call the Anthropic API directly from Flutter.** All Claude API calls go through a Supabase Edge Function. Flutter calls the Edge Function only — see `webapp-reference/supabase/functions/` for the existing proxy implementation.

| Setting | Value |
|---|---|
| Model | `claude-sonnet-4-5-20250929` |
| Streaming | Always — never show a full-response loading spinner |
| Context to include | Job details, musician profile summary, event type, previous offers by this musician |
| Max questions per turn | 2 — never 3+ |

---

## Thesis observability

Every AI interaction must be structured so it can be replayed, analyzed, and improved. Design so failure modes are isolatable: bad prompt vs. bad UI vs. bad context vs. bad model settings.

All interactions must be logged to the `AgentInteractions` table:

| Field | What to log |
|---|---|
| `timestamp` | When the interaction started |
| `job_id` | Which job the musician was working on |
| `musician_id` | Which musician |
| `prompt_sent` | Exact prompt sent to the model (including system prompt) |
| `response_received` | Full model response text |
| `final_submitted_text` | The offer text the musician actually submitted (may differ from the draft) |
| `latency_ms` | Time from request to final streamed token |

Flag any design decision that affects agent evaluability before implementing. Latency is a primary evaluation metric.

---

## What the agent must never do

- Call the Anthropic API directly from Dart — Edge Function only
- Invent facts: price, equipment, availability, experience
- Generate a pitch without asking at least one question first
- Give the same pitch twice — every output must be unique to the job
- Produce output that cannot be edited inline by the musician before submission
