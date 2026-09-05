# Olitun Learner Validation Package (PROPOSED — not run)

Status: **proposal only**. No participants recruited, no sessions conducted,
no results collected. A small pilot finds problems; it cannot support
statistical claims about learning effectiveness or completion rates.
Keep this separate from any future observation reports.

Related: `docs/EXPERIENCE_EVALUATION_2026_09.md` (manual-evaluation checklist),
`docs/PRODUCT_QUALITY_PLAN.md` (product-quality plan, on PR #262).

## 1. Participant criteria (10–15 learners)

Recruit a mix, not a monoculture:

- 3–4 complete beginners (never seen Ol Chiki; literate in Hindi, Bengali,
  Odia, or English — the teaching languages the app supports).
- 3–4 Santali speakers who do not read Ol Chiki.
- 2–3 existing Ol Chiki readers (can judge correctness, not just usability).
- 2–3 low/intermittent-connectivity users (the offline-first audience).
- At least 2 participants over 45 (larger-text, audio-reliant habits).
- At least 2 participants using each supported teaching language where
  feasible (en/hi/bn/or/sat); note which build locale each session uses.

Exclude: team members, anyone who built or wrote content for the app.
If children participate: a parent/guardian must be present, give consent,
and remain in the room; sessions with children stay under 20 minutes. This
guidance is not a legal compliance finding — flag policy/legal review
before any study involving minors.

## 2. Consent and privacy guidance

- Explain before starting: what the app is, that you are testing the app
  (not them), that they may stop or skip anything at any time, and roughly
  how long it takes (45–60 min adult sessions incl. follow-up scheduling).
- Ask explicit permission to take notes; separate explicit permission for
  any audio/screen recording. No recording without it.
- Collect minimum data: first name or pseudonym, age band, languages
  known, connectivity context. No phone numbers, emails, or account
  credentials. If the app flow requests sign-in, use a disposable staging
  account operated by the facilitator — never a participant's account.
- Notes must not contain credentials, payment details, or raw personal
  content. Store notes per `docs/DATA_CLASSIFICATION.md` handling rules
  and delete recordings after the retention window agreed with participants.
- Never conduct purchases with real money during sessions. Locked-lesson
  tasks stop at understanding the lock message (see Task 6).

## 3. Task script (neutral instructions — read verbatim, do not coach)

Setup: fresh install (or cleared onboarding) on the participant's own
device class where possible; note device, OS, locale, and connectivity.

1. **First lesson.** "Open the app and do whatever you would normally do
   to start learning. Talk aloud about what you are deciding."
2. **Pronunciation.** "You hear a new letter or word. Listen to it as many
   times as you like, then tell me what you heard."
3. **Mistake recovery.** "Answer the next few practice questions however
   you like — including guessing. When you get one wrong, tell me what the
   app is telling you and what you would do next."
4. **Next step.** "You have finished for now. Show me what you would do
   the next time you open the app."
5. **Offline.** "Imagine you are travelling with no internet tomorrow.
   Show me what you could still use, and how you would prepare."
6. **Locked content.** "You see a lesson you cannot open. Tell me what
   you understand about why, and what your options are. Do not buy
   anything."
7. **Connection failure.** (Facilitator enables airplane mode mid-browse.)
   "The internet just dropped. Show me what you would do."

For each task record: completed unassisted / completed with hint / gave
up; time; verbatim confusion quotes; facilitator hints given (hints are
data — a hint means the UI failed that step).

## 4. Observation sheet (one row per task)

| # | Task | Outcome (unassisted / hinted / gave up) | Time | Confusion quote | Hints given | Severity (see §6) |
|---|------|------------------------------------------|------|-----------------|-------------|-------------------|

Plus per-session header: date, facilitator, device/OS, app version + build
SHA, locale, connectivity, participant band (e.g. "beginner/hi/low-band").

## 5. Post-task questions (short, after all tasks)

1. "What was the most confusing moment, in your own words?"
2. "What would you do first next time you open the app?" (checks next-action clarity)
3. "Was there any point you felt stuck with nothing to try?" (dead-end check)
4. "Did anything feel rushed, pressured, or try to keep you longer than
   you wanted?" (manipulative-pattern check)
5. "Is there anything you wanted to learn that the app did not offer?"

## 6. Issue-severity rubric

- **S1 blocker:** cannot complete a core task (finish onboarding, complete
  a lesson, recover from a wrong answer, resume next session). Must fix
  before release.
- **S2 friction:** completes with hint, delay, or workaround; or honest
  confusion about progress, offline state, or locked content. Fix in the
  next milestone unless 3+ sessions repeat it (then treat as S1).
- **S3 polish:** cosmetic, wording preference, minor visual inconsistency.
  Batch for design passes; never let S3 crowd out S1/S2.
- **Content flag (separate track):** suspected wrong letter, word,
  translation, or pronunciation — route to fluent Santali/Ol Chiki review,
  never fix by guessing. Mark machine-assisted suggestions as drafts.

## 7. Prioritizing repeated problems

After every 3–4 sessions, tally: issue × sessions-affected. Fix order is
(sessions-affected × severity), S1 first. An issue seen in 1 session is a
hypothesis; seen in 3+ is a finding. Re-test fixed S1/S2 issues with 2 new
participants before closing.

## 8. Learning-effectiveness outline (separate from usability)

Run only after S1 usability blockers are fixed, with fluent-speaker review
of all test items first:

1. **Baseline (10 min):** recognise/produce 10 target items (letters or
   words the lessons teach) — items the learner has not seen in the app.
2. **Lessons (20 min):** complete the selected lessons normally.
3. **Immediate check (10 min):** same skills with *different examples*
   than the lessons used (transfer, not recall).
4. **Delayed check (same format, agreed interval, e.g. 7 days):** retention.
5. **Qualitative debrief:** which items felt confusing and why.

Report usability observations and learning evidence in separate sections.
With n≈10–15, report raw counts and quotes only — no significance tests,
no "X% improvement" claims.

## 9. What this package does NOT authorize

Recruiting or contacting users, spending real money, touching production
data or permissions, collecting analytics beyond session notes, or
presenting pilot observations as effectiveness proof. Facilitators run this
as-is; any change to tasks, criteria, or data handling gets written down
before the session it affects.
