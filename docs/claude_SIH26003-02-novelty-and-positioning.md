# SIH26003 — Novelty & Positioning (for Claude Code)

Use this to keep feature decisions, copy, and UI language consistent with what the team is claiming in the pitch. If a feature you're building contradicts something here, flag it — don't silently build around it.

## The whitespace, one sentence
> Digital CST exists, but has only ever been built for people who are literate, connected, and accompanied by a caregiver who can operate a device. Smriti removes all three assumptions at once.

## Why this matters for NER specifically (evidence)
- India 60+ dementia prevalence: 7.4% (8.8M people, 2016) → projected 16.9M by 2036.
- Assam 8.47% (above national avg); rest of NER 7.35%.
- Rural 8.4% vs urban 5.3%. No formal education 10.29% vs middle-school+ 1.54%. Women 9.0% vs men 5.8%.
- **Argument:** the highest-prevalence profile in India is rural + female + unschooled — exactly what every existing product and standard cognitive test assumes *away*. Design failure, not market gap.

## Closest prior art (don't reinvent claims that don't hold up against these)
- **Thinkability iCST** — solo only, no group mode.
- **vCST (Brazil/India, JMIR Aging 2024)** — India arm: 15 participants, loaned devices, Zoom-based, Tamil/English only, one dropped connection degrades the whole group, total dependence on a caregiver to operate the device.
- **Ami (SUTD Singapore)** — closest shipped competitor: 3 touchscreen games, 6 languages, ~1000 tablets via Lions Befrienders. But urban, always-connected, institution-delivered, no offline mode, no dashboard, no adaptive engine.
- **Consumer brain training** (Lumosity, CogniFit, Peak) — score/streak/timer driven, contraindicated for dementia (failure states).
- **Dementia engagement apps** (Memory Lane Games, MindMate, GreyMatters) — no health-worker layer, no group mode, no adaptation, Western content only.

## Eight novelty claims (build toward these, ranked by how defensible they are)

**Tier A — structural, hardest to copy**
1. **Zero-ASR voice architecture.** No speech recognition needed for core interaction — touch/gesture only. All system speech is a finite pre-recorded phrase set (~200 utterances) voiced by a native speaker, shipped per content pack. Where Bhashini/AI4Bharat *does* support the language (Assamese, Bodo, Manipuri), use it — but the app never depends on ASR existing for a language (Khasi, Garo, Mizo, Nagamese, Kokborok, Pnar have none).
2. **Group CST on one shared tablet.** Six elders + one ASHA on one tablet: turn-taking prompts, shared cultural challenge, per-person tap attribution, facilitator script for an untrained facilitator. **This is the ASHA dashboard's core job.** Solo home play is the reinforcement tier, not the core.
3. **Own-baseline scoring, not population norms.** Every elder is her own control — onboarding captures personal reaction latency, hesitation, hint dependence, error perseveration. All later readings are drift from that baseline. Removes literacy bias from scoring entirely.

**Tier B — verifiable in demo**
4. **The game is the instrument.** Monitoring is a by-product of play — no test is ever administered, no assessment anxiety.
5. **Difficulty tuned to a target success rate (~80%), not a challenge curve.** Grid size, distractor count, pacing adjust silently between rounds. No Game Over, no buzzer, no red X. Mismatch = cards stay visible 2s, flip back with a neutral sound. Hint after 3 consecutive misses or detected hesitation.
6. **Reminders in a family member's recorded voice.** Son records 15 seconds once; plays in his voice, her language, offline, forever. Elder taps his photo to acknowledge → lands on his dashboard. **This is a core caregiver-dashboard feature** — cheapest and most memorable thing the app does.

**Tier C — supporting**
7. **Cultural adaptation as a shippable content pack**, not a fork. New district = author a pack (motifs, object photography, folk audio, festival calendar, routine sequences, recorded phrases, facilitator script), not new code.
8. **The ASHA is the network.** Everything on-device (SQLite); compact JSON deltas burst-sync at PHC / Ayushman Arogya Mandir / existing NESAC node. We ride NESAC's already-funded infrastructure (25 telemedicine centres, ~350 satellite terminals across 8 NE states) — we are not building a VSAT network.

## Never say / say instead
| Never | Instead |
|---|---|
| "Our AI detects/diagnoses dementia" | "Flags sustained deviation from her own baseline, routes to ASHA. Diagnosis stays with a clinician." |
| "Our games slow or reverse decline" | "CST is the NICE-recommended non-drug intervention for mild-to-moderate dementia. We deliver its structure where no therapist can reach." |
| "We support all NE languages" | "Three fully built and demonstrated; architecture takes a new language as a recorded content pack." |
| "We use satellite connectivity" | "Offline-first by default; satellite is one opportunistic sync point on nodes NESAC already operates." |
| "First cognitive gaming app for elderly" | "First digital CST that works without literacy, without a network, and without a caregiver operating the device." |
| "NER has more dementia" | "Assam 8.47% vs national 7.4% — and NER's elderly are disproportionately rural, female and unschooled, the three highest-prevalence groups nationally." |

## Implication for engineering
- Do **not** build any feature that requires live speech recognition for the elder-facing flow.
- Do **not** design the ASHA session as one-patient-at-a-time by default — it's a group construct with per-patient response capture inside it.
- Any "AI insight" surfaced to ASHA/caregiver must be phrased as a trend/flag against the patient's own baseline, never as a diagnostic statement.
- Every reminder object needs a slot for a recorded audio clip (family voice), not just text.
