# Domain Context

## Purpose
This file gives Claude the background context needed to understand the DJTilbud platform, who the users are, and what problem the AI agent is solving. Read this before building or modifying any part of the AI agent.

---

## What DJTilbud is
DJTilbud is a Danish two-sided marketplace connecting customers who need musicians for events with DJs and saxophonists who want the work. Customers post job requests describing their event. Musicians see the requests and submit proposals. The customer reviews the proposals and selects one musician, or the job expires after seven days.

---

## How a job flows through the system

1. **Customer posts a job request** - describes the event type, date, location, and what they are looking for. Sometimes includes a fixed budget, sometimes leaves the price open.

2. **Musicians receive a notification** - only musicians in the relevant category see it (DJs see DJ jobs, saxophonists see saxophonist jobs).

3. **Musicians submit a proposal** - consisting of a written pitch and a price. This is the moment the AI agent is most useful.

4. **Customer browses proposals** - they see up to three proposals at once, each showing the musician's full profile alongside their pitch. They compare profiles, watch videos, read reviews, and read pitches before deciding.

5. **Customer selects one musician or the job expires** - they have seven days. If no one is selected, the job expires and all proposals are lost.

---

## The closing rate problem
Between 59% and 75% of jobs on DJTilbud expire or are cancelled without a musician being hired. The data shows a clear pattern: musicians with complete, well-presented profiles and personal, well-written pitches have significantly higher success rates. The two main problems are:

- **Pitch quality**: Many musicians send generic, short, or copy-pasted pitches. Common examples: "Hire me", "I can do this perfectly", five-word messages with no personalisation.
- **Profile completeness**: Many profiles have poor photos, few or no videos, thin biographies, and no reviews.

The AI agent exists to fix both of these problems.

---

## Who the musicians are
- 63 DJs and 22 saxophonists currently active on the platform
- Working musicians - they gig on weekends, travel between venues, manage their own bookings
- Mobile-first - they almost never use the webapp on a desktop, they use their phones
- Time-pressured - when a notification comes in they want to respond quickly, often between sets or in transit
- They care about getting hired but often do not prioritise profile maintenance or pitch quality because it feels effortful and uncertain

---

## What the customer sees
When a customer opens their proposal page they see all proposals side by side. Each proposal shows:
- The musician's profile photo
- Their name and category
- Their pitch text
- Their price
- A link to their full profile with videos, biography, and reviews

The customer makes their decision based on this information alone. They have never met the musician. The profile and the pitch are everything.

---

## Why the AI agent matters
The agent solves a real problem on both sides:
- For musicians: it reduces the effort and uncertainty of writing a good pitch and building a strong profile
- For the platform: better pitches and profiles lead to higher closing rates, which means more successful transactions for everyone

The agent is not a shortcut to producing generic content faster. It is a tool for helping musicians communicate who they are and why they are the right fit for a specific job - in a way they would not do on their own because they do not have the time or the knowledge to do it well.

---

## The competitive context
On a typical job, a customer receives two to three proposals from musicians. The musician is competing directly against one or two others. A pitch that is personal, specific, and well-written will stand out immediately against one that is generic or too short. The profile with good videos and a warm biography will build more trust than one with a blurry photo and two sentences.

The agent's job is to help musicians compete - not just to submit something, but to submit something worth choosing.

---

## Sources informing the agent design
- Parhankangas & Renko (2022): proximal language predicts success in competitive bidding contexts
- Zhang et al. (2023): self-presentation combining competence and warmth drives purchase behaviour on two-sided platforms
- Cialdini (2001): liking and social proof as core persuasion principles
- DJTilbud platform data: closing rate analysis and pitch quality patterns
- Musician interviews (2025): user journey mapping and construct definition
