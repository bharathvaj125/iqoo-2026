# SIH26003 — Problem Context (for Claude Code)

Read this before writing any feature. Every screen, field, and flow should trace back to something here.

## Problem Statement
**SIH26003** — AI-Based Cognitive Gaming and Memory Assistance Platform for Elderly Dementia Patients in the North Eastern Region (NER).
Ministry: MDoNER · Category: Software

## One-line positioning
An AI-powered cognitive gaming and memory assistance platform for elderly dementia patients in NER, using culturally adapted cognitive stimulation activities and an offline-first, community-care delivery model.

CST (Cognitive Stimulation Therapy) is the *clinical framework* structuring the activities — it is not the whole product. The product has two halves:

1. **Cognitive engagement** — games (memory, attention, recognition, emotional/social)
2. **Memory / daily assistance** — medicines, hydration, daily activities, appointments

Don't let the games overshadow half 2 — "memory assistance" is in the PS title.

## Why NER — the real problem (not "more dementia," but more *undiagnosed, unmanaged* dementia)
- **Access gap** — PHCs/sub-centres below national infra average; specialists concentrated in Guwahati/Shillong. Multi-day travel for a memory-clinic visit.
- **Belief gap** — early symptoms read as "old age," spirits, a curse. Formal-care uptake tracks *perceived* severity, which starts low.
- **Care-structure gap** — heavy youth out-migration removes the family member most likely to notice early symptoms.
- **Language gap** — no mainstream cognitive app supports Naga languages, Khasi, Garo, Mizo, Bodo, Meitei. Five language families, 200+ tribes.
- **Connectivity gap** — hill terrain, landslide-prone, intermittent coverage. **Offline is a requirement, not a nice-to-have.**
- **Trust gap** — traditional healers and clan/community elders are the first point of contact.

## Clinical basis
- Dementia is not curable. **CST is the NICE-recognised gold-standard non-pharmacological intervention** for mild-to-moderate dementia.
- Traditional CST is therapist-led and group-based → bottleneck in NER → we digitise the structure so an **ASHA worker or family member can facilitate without clinical training.**
- **Never say** "our games slow or reverse decline." **Say:** "CST is the NICE-recommended non-drug intervention for mild-to-moderate dementia. We deliver its structure where no therapist can reach."

## The two roles that matter for what you're building next
- **ASHA worker** — runs *group* sessions for multiple patients on one shared tablet at scheduled times. Not one-on-one by default. This is the **core delivery tier**.
- **Caregiver (usually family, often physically distant)** — sets up reminders, watches engagement/alerts asynchronously, may be the fallback caregiver-of-record if no family is present (in which case the ASHA fills this role too).

## Delivery model (device-ownership gap)
| Tier | Who | How |
|---|---|---|
| **Core** | All registered elders | ASHA-facilitated **group** sessions on a shared rugged tablet at a community centre/PHC |
| **Reinforcement** | Households with a smartphone | Short 10–15 min **solo** maintenance activities at home |
| **Outreach** | No device / can't travel | ASHA home visit with the tablet; offline session; sync later |

Pitch line: *"Smartphone ownership is not a prerequisite for our core intervention."*

## AI/ML adaptive engine — ground rules
- Tracks error rate, reaction time, hesitation, hints used → dynamic difficulty adjustment.
- Baseline is **individual**, captured at onboarding by the ASHA/family member. It's a *performance* baseline, **not a diagnosis**.
- **Never say** "our AI detects/diagnoses dementia." **Say:** "Flags sustained deviation from her own baseline, routes to ASHA. Diagnosis stays with a clinician."
- Intervention pathway: AI flags sustained decline → ASHA/caregiver notified → added engagement + ASHA review → if clinically concerning → healthcare professional evaluation.

## Offline-first architecture — non-negotiable
- Local-first: SQLite on-device. Games, reminders, and logs fully functional at zero connectivity.
- **Store-and-forward**: lightweight JSON telemetry burst-syncs opportunistically when the tablet reaches connectivity (community centre / PHC / ASHA's return trip).
- Satellite (ISRO SatCom/VSAT, NESAC nodes) is an **optional connectivity layer for extreme-remote deployment**, not an MVP dependency. If challenged: "we sync whenever connectivity exists; SatCom is the scale path where terrestrial links fail."

## Elderly-friendly access & identity
- **No typed login, ever.**
- Shared device (ASHA tablet): photo-tile picker — "Who are you?" → tap your picture.
- Personal device (reinforcement tier): single-profile kiosk mode.
- Encrypted local storage, role-based access, minimal identifiable data on the shared screen.

## Security
On-device encryption at rest; consent at registration (patient and/or family/ASHA proxy); only aggregate behavioural telemetry in transit, not raw health records; align to **DPDP Act 2023**.
