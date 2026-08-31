# Elder Companion — Patient Home Dashboard (SIH26003, Team Synapse)

Flutter prototype of the **"Patient — Individual Daily Mode"** flow from the
pitch deck: her own phone, her own time.

## Flow implemented
1. **Profile & language picker** — photo tiles, zero typing (`profile_select_screen.dart`)
2. **Voice-guided check-in** — mood tap-in (`voice_checkin_screen.dart`)
3. **Home dashboard** — big tiles: Play Games, Reminders, Family, Songs, plus
   an always-visible SOS button and a single "today's goal" banner
   (`home_screen.dart`)
4. **Adaptive CST game** — memory-match with on-device difficulty tuning
   based on accuracy + latency (`game_screen.dart`)
5. **Reminders** — meds/water/appointments, one-tap confirm (`reminders_screen.dart`)
6. **Family** — photo + voice-note per relative (`family_screen.dart`)
7. **Distress/SOS alert** — queued offline, syncs when online (`distress_dialog.dart`)

## Offline-first design
`lib/services/local_store.dart` is a stand-in for the SQLite/on-device layer
in the architecture diagram. It stores:
- active profile
- daily family-set goal
- per-elder adaptive difficulty level
- pending game-session / distress logs, ready to sync to the cloud
  (Postgres via Firebase) whenever connectivity returns

## Run it
```bash
flutter pub get
flutter run
```

## Next steps to wire into the real backend
- Replace `LocalStore` with `sqflite` and add a sync job that POSTs
  `getPendingSessions()` to the Node.js/FastAPI Goal-Setting Service and
  Caregiver Alert & Sync service when connectivity is detected.
- Swap emoji placeholders for real photo/audio assets loaded per NER state.
- Add actual TTS/human-recorded audio playback (`audioplayers` is already
  a dependency) for the voice-guided check-in and reminders.
- Hook the SOS button to the SMS/Voice Alerts or ISRO SatCom path for
  zero-connectivity hill villages, per the External Connectivity block
  in the architecture diagram.

## Companion character (new)
`lib/widgets/companion_character.dart` renders a warm, semi-realistic
5–7-year-old NER boy as a `CustomPainter`, driven by a shared
`CompanionController` (ChangeNotifier) in `lib/services/companion_controller.dart`:

- **Idle behaviour**: gentle sway/breathing (AnimationController), random
  blink every ~2.4–5s (Timer), no input needed.
- **Expressions**: `neutral / happy / thinking / excited / encouraging /
  calm / celebrating` — each changes eyebrows, mouth curve, head tilt,
  and arm pose (e.g. arms up + sparkles when celebrating).
- **Speech + lip sync**: `lib/services/tts_service.dart` wraps
  `flutter_tts`. While audio plays, it calls `controller.startMouthLoop()`,
  which cycles `MouthState.{closed, openSmall, openMedium, openLarge}`
  every ~130ms — the simple, demo-friendly lip sync described in the brief
  (no phoneme timing needed).
- **"AI" text**: `lib/services/companion_brain.dart` is a rule-based
  situation → (text, expression) map for the hackathon demo. Swap its
  body for a real API/LLM call later; the text still flows into
  `TtsService.speak(text, controller)` unchanged.
- **App-wide access**: `lib/services/companion.dart` is a singleton
  (`Companion.instance`) so any screen can call
  `Companion.instance.say('correct')`, `.say('game_completed')`, etc.
  and every visible `CompanionCharacter` widget reacts immediately.
- **Where it shows up**: the Welcome screen (greets + speaks on launch),
  a dedicated "Talk to Me" screen (`companion_screen.dart`) with quick
  action buttons for every situation plus a free-text box, and the
  Memory Match game (reacts to correct/wrong taps and celebrates on
  completion).

### Wiring in a real AI response later
Replace `CompanionBrain.forFreeText` (or add an async variant) with a
call to your backend's Companion Dialogue Service / an LLM API, then
keep the rest of the pipeline as-is:
`text -> TtsService.instance.speak(text, controller) -> character speaks`.

## Kuzu 3D Character

This version includes a real local GLB 3D companion at `assets/character/kuzu.glb`.
The existing `CompanionController` + `TtsService` pipeline now drives the GLB animation state.

Supported named animations in the bundled model:
- Idle
- Blink
- Talk
- Wave
- Happy
- Thinking
- Encourage

The 3D viewer uses `flutter_3d_controller`. The project keeps the previous Flutter-drawn companion as a runtime fallback if the 3D renderer/model cannot load on the current platform.

For Android/web/macOS, follow the platform setup notes for `flutter_3d_controller` in its package documentation. The package currently supports Android, iOS, macOS and web; Windows is not listed as a supported platform, so use Chrome/Android/iOS/macOS for the 3D view. 

## Kuzu 3D Web setup

The project includes the required Flutter Web `model-viewer.min.js` bootstrap for
`flutter_3d_controller`. After extracting the ZIP, run `flutter pub get` and then
`flutter run -d chrome`. The Kuzu model is loaded from `assets/character/kuzu.glb`
and its named animations are controlled by `CompanionController`.

## SIH26003 Patient Module Spec — Phases 1–3

This build now implements all three phases of the patient module spec:
Phase 1 (comfort-building intro, the wrong-answer rephrase ladder, reminder
interrupt/resume, daily streaks/badges), Phase 2 (Personal Fact Bank /
personalization loop), and Phase 3 (Daily Living Guidance).

### New files
- `lib/models/patient_models.dart` — `ReminderItem`, `ReminderAck`,
  `GameSessionSnapshot`, `Streak`, `RewardBadge`/`BadgeType`,
  `ResponseRecord`/`ResponseMark`. Field names intentionally mirror the
  spec's data-model section so these map cleanly onto real Postgres
  tables later.
- `lib/services/reminder_service.dart` — app-wide `ChangeNotifier`
  clock. Checks real wall-clock time against each reminder's
  `timeOfDay`, and exposes `fireForDemo(reminderId)` so the
  interrupt/resume flow can be demonstrated instantly from the
  Reminders screen ("Test: ring now") without waiting for the actual
  time to arrive.
- `lib/widgets/reminder_task_overlay.dart` — the full-screen "task
  mode" overlay any game screen shows when a reminder fires: companion
  reads the reminder aloud, one big "I did it" tap acknowledges and
  resumes.
- `lib/screens/comfort_intro_screen.dart` — shown once per calendar day
  before the first game (`LocalStore.hasSeenComfortIntroToday`), framed
  as chatting/playing, never as a test.
- `lib/screens/game_hub_screen.dart` — pre-built games list (Picture
  Recall, Memory Match) the comfort intro leads into.
- `lib/screens/picture_recall_screen.dart` — the flagship demo of the
  spec's rephrase ladder: naming question → functional rephrase → fewer
  options → highlight-and-pass, never a flat "wrong". Also wired for
  reminder interrupt/resume with a persisted snapshot.
- `lib/widgets/streak_badge_bar.dart` — home screen streak + badge
  shelf. Shows no accuracy/score, per the spec's zero-failure design.

### Modified files
- `lib/screens/game_screen.dart` (Memory Match) — added the same
  reminder interrupt/resume handling as Picture Recall, plus streak and
  badge awarding on completion.
- `lib/screens/home_screen.dart` — "Play Games" now routes through the
  once-daily comfort intro before the game hub; added the streak bar.
- `lib/screens/reminders_screen.dart` — rewired onto the shared
  `ReminderService` (was a local static list before) with a demo
  "Test: ring now" trigger per reminder.
- `lib/services/companion_brain.dart` — added situational lines for the
  comfort intro, each rephrase-ladder step, reminder task-mode/ack,
  streak continuation/reset, badge-earned, session-end goodbye, and
  resuming after an interruption.

### Phase 2 — Personal Fact Bank / personalization loop
- `PersonalFact` model + `LocalStore` CRUD
  (`lib/models/patient_models.dart`, `lib/services/local_store.dart`) —
  field names mirror the spec's `personal_fact` entity exactly.
- `lib/screens/personal_fact_entry_screen.dart` — the **facilitator-
  assisted** capture path the spec says to build first ("works for every
  language... no speech recognition needed at all"): a short structured
  who/what/category form. Opens automatically, at most once every ~20h,
  when the patient taps **Play Games**, framed as a casual aside
  ("Tell Me About You"), never a required step — matching the spec's
  "light moment slipped between games," not a gate before play.
- `lib/screens/reminiscence_recall_screen.dart` — the question generator:
  pulls a random `PersonalFact`, builds a naming + easier-functional
  question pair from its category (e.g. `gift_from_family` →
  *"What did your daughter bring you last time?"*), and mixes in
  regional distractors from a small state-keyed content pack rather than
  random junk. Uses the exact same rephrase ladder as Picture Recall, and
  every response logs with `fromPersonalFact: true` on `ResponseRecord`
  so this signal stays distinguishable from generic-content recall, per
  the spec's note that it's "worth keeping that distinction available."
  If the Fact Bank is empty, it shows a warm "still getting to know you"
  screen instead of an empty/broken game.
- **Not built** (explicitly additive/deferred per the spec itself):
  direct voice capture via Bhashini/AI4Bharat STT for Assamese/Bodo/
  Manipuri — needs real API credentials/network this environment
  doesn't have, and the spec is explicit that it never blocks or
  replaces the facilitator-assisted path built above.

### Phase 3 — Daily Living Guidance
- `DailyLivingPrompt` model + the fixed 5-scenario set
  `kDefaultDailyLivingPrompts` (`lib/models/patient_models.dart`) — night
  bathroom safety (the spec's own example) plus four more across
  night-safety, mobility, and hygiene, each tagged to a time-of-day
  bucket (`timeOfDayBucket()` maps wall-clock time to
  morning/afternoon/evening/night).
- `lib/widgets/daily_living_card.dart` — the single-step 10-15s
  interaction: companion states the guidance, one big "Did you do it?"
  yes/no tap, companion praises either answer, no scoring/failure state.
- Wired into `home_screen.dart`: at most one card per time-of-day bucket
  per day (`LocalStore.getDueDailyLivingPrompt` /
  `markDailyLivingPromptShown`), so the patient isn't repeatedly nagged.
- `LocalStore.setDailyLivingPromptEnabled` is a local stand-in for the
  caregiver's enable/customize control the spec calls for — real UI for
  that belongs on the Caregiver dashboard, which isn't part of this
  project.

### What's intentionally still out of scope
- **Bhashini/AI4Bharat STT** for direct voice capture — see Phase 2
  above; additive-only per the spec, not required for either
  personalization or core gameplay.
- **Cross-module sync** with the ASHA/Caregiver dashboards — separate
  apps/specs not present in this project. `personal_fact`,
  `daily_living_prompt`, `response_record`, `reminder_ack`, etc. are all
  shaped to match those specs' field names so wiring up real sync later
  shouldn't require renaming anything.
- **Caregiver "preferred focus" selector** — the spec itself flags this
  as an open item for the Caregiver module, not the Patient module.
- **Hometown-level cultural granularity** — spec calls this a stretch
  goal; the state-level cultural pack (used for Reminiscence Recall's
  distractors) is the MVP level implemented here.

### Trying it out
1. From Home, tap **Play Games** — the comfort intro appears once per
   day, then the game hub.
2. Open **Picture Recall** and deliberately tap a wrong option to see
   the ladder: soft rephrase → functional question → fewer options →
   highlight-and-pass. Nothing is ever marked "wrong".
3. While playing either game, go to **Reminders** in another tab/route
   (or just wait — reminders also fire for real at their `timeOfDay`)
   and tap **Test: ring now** on any reminder. The game screen should
   immediately pause, snapshot its state, and show the companion's
   task-mode overlay. Tap **I did it!** to resume exactly where you
   left off.
4. Finish a round to see the streak/badge summary — no score or
   accuracy is ever shown to the patient.
5. Tap **Play Games** again later (or wait ~20h, or clear app data) to
   see the **Tell Me About You** casual prompt appear before the game
   hub — fill in a memory (e.g. category "Gift from family", entity
   "daughter", value "jasmine"), then open **Remember With Me** from the
   game hub to see it turned into a recall question with regional
   distractors.
6. On Home, a **Daily Living Guidance** card appears automatically if
   one is due for the current time of day (e.g. an evening or night
   scenario) — tap **Did you do it?** to see the companion praise you
   and the card dismiss; it won't reappear again until the next
   time-of-day bucket.
