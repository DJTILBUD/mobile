# AI Agent

This folder is a high-level overview of the two AI features in the mobile app. It is **not** the source of truth for prompt content — see "Canonical prompt source" below.

---

## Canonical prompt source

**What Claude actually receives at runtime lives in `web-app/supabase/functions/agent-assist/prompts.ts`** — exported TypeScript string constants that the Edge Function imports and composes per `purpose`.

```
web-app/supabase/functions/agent-assist/
├── index.ts        ← composes the system prompt per purpose (sales_pitch, profile_bio, etc.)
├── prompts.ts      ← THE source of truth — exported string constants
└── prompts/        ← reference .md copies of the same strings (kept in sync manually)
```

**To change Claude's behaviour, edit `prompts.ts` and mirror the same change in the matching `prompts/*.md` file.** The Edge Function does not load the `.md` files at runtime — it bundles `prompts.ts` at deploy time. Run `supabase functions deploy agent-assist` after editing.

The exported constants are:

| Constant | Mirror file |
|---|---|
| `DOMAIN_CONTEXT` | `prompts/domain-context.md` |
| `AGENT_BEHAVIOUR` | `prompts/agent-behaviour.md` |
| `HUMAN_AI_GUIDELINES` | `prompts/human-ai-guidelines.md` |
| `PITCH_GUIDELINES` | `prompts/pitch-guidelines.md` |
| `SUMMARY_GUIDELINES` | `prompts/summary-guidelines.md` |
| `PROFILE_BIO_GUIDELINES` | `prompts/profile-bio-guidelines.md` |
| `PROFILE_COACH_GUIDELINES` | `prompts/profile-coach-guidelines.md` |

---

## What the two agents do

**Pitch agent** (uses `PITCH_GUIDELINES` + shared constants)
- Triggered when a musician opens a job request and taps "Get AI Help"
- Reads the job details + musician profile into context
- Generates pitch immediately — no clarifying questions first
- Accepts inline follow-up edits ("make it warmer", "make it shorter")
- Goal: a personal, specific, well-written pitch that wins the job

**Profile coach** (uses `PROFILE_COACH_GUIDELINES` + `PROFILE_BIO_GUIDELINES` + shared constants)
- Triggered from the musician's profile screen
- Reads the current profile state (photo, videos, bio, reviews)
- Identifies the single highest-impact gap
- Gives one specific, actionable improvement — then moves to the next gap only after the first is addressed
- Goal: a complete profile that builds customer trust before they read the pitch

---

## Technical implementation

**Never call the Anthropic API directly from Flutter.** All Claude API calls go through the Supabase Edge Function at `web-app/supabase/functions/agent-assist/`.

| Setting | Value |
|---|---|
| Model | `claude-sonnet-4-5-20250929` |
| Streaming | Always — never show a full-response loading spinner |
| Context to include | Job details, musician profile summary, event type, previous offers by this musician |

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
- Give the same pitch twice — every output must be unique to the job
- Produce output that cannot be edited inline by the musician before submission
