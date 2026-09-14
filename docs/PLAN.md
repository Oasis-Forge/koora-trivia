# Koora Trivia: owner plan (13 Sep 2026)

> From the full audit on 13 September 2026: 152 findings; every bug, UI, content and release item was re-checked by a second agent. Update this file as items ship, and re-check each content fact on the day you edit it.

## Done since the audit
- Daily challenge repeating on consecutive days, and its seed depending on the time zone: PR #2, merged 13 September 2026.
- "Replay level" and "Next level" on the result screen starting a level with zero hearts: PR #3, merged 13 September 2026.
- The owner published a *European regulations* consent message in AdMob on 13 September 2026; the EEA consent form now appears on the emulator (debug build with `UMP_DEBUG_EEA=true`), and the Settings privacy-options row shows.
- Data safety form updated by the owner to Approximate location, App interactions, Diagnostics and Device or other IDs, and sent for review: 13 September 2026.
- Privacy policy page updated to the PR #5 text and checked live: 13 September 2026.
- PR #8, merged 14 September 2026: the share text ends with the Play Store link and a UTM referrer · the in-app review prompt after a 3-day daily streak or a 3-star level, at most every 30 days, never after an ad · «أبلغ عن خطأ» on the answer panel and in the review list opens a ready email with the question id, reason and version · a local error log fed by `FlutterError.onError` and `PlatformDispatcher.onError`, and «أرسل ملاحظاتك» in Settings emails the version and recent errors · Settings shows the real version · players no longer see raw exception text · `android:appCategory="game"` · privacy policy source mentions feedback emails (publishing needs the owner's go-ahead).
- 14 September 2026: 13 misspelled names and the U+200F fixed (PR #10); wording of 3086, 5090, 5093, 5099, 6098 and 9073 fixed and «كلتاهما» banned by the bank test.
- 14 September 2026: second correct options removed from 1080, 10043, 1096, 10081, 8089, 8088, 3083, 2098, 10099 and 5098.
- PR #7, merged 14 September 2026: the level grid fits all ten levels on 360×640 and 411×731 · compact quiz layout below 700 dp, options anchored above the hints bar, feedback panel scrolls into view · Skip shown as a skip on the quiz screen and in the review · backup import validates every value, reloads every provider, and datasources survive badly typed values · widget tests for result-screen buttons, the level grid, the quiz layout, and a real-storage import test.
- PR #6, merged 13 September 2026: the daily reminder fires (receivers and a status-bar icon; verified on a release build on the emulator, including after a reboot); one reminder per day for the next week, skipping today once the daily is done, naming the streak in the first, and taking the question count from AppConfig · hearts, the countdown and tasks refresh on resume and every 30 s, and a granted heart no longer resets the countdown · the no-hearts dialog offers the daily challenge (only if not done), an ad and a 200-coin refill, with «حسناً» · count-noun grammar helper used for days, stars, levels, points, questions and correct answers.
- PR #5, merged 13 September 2026: ads wait for UMP consent (`canRequestAds()`) and start at launch instead of when Settings, the result screen or the shop first opens · Settings privacy row with ad privacy options and the policy link · the rewarded-ad button enables when an ad loads and failed loads retry with backoff and on resume, as does a failed consent update · Data safety docs list what AdMob collects · privacy policy source updated · the manifest's AdMob comment fixed · the Arabic DATA_SAFETY.md copy deleted.

---

## Phase 1: before production (during the 14-day closed test)

### Bugs
- **P2 · S**: Follow-ups to the day-key fix (PR #2). Record the day key when the daily starts (finishing after midnight resets the streak), and use UTC dates in `daysBetween` so daylight-saving days count correctly *(day_key.dart, stats_provider.dart)*.
- **P2 · S**: Charge a heart only when `QuizProvider` actually records the answer (`selectAnswer` returns bool). This closes the double-tap and timeout-frame race. Ship it with decision ① *(quiz_screen.dart, quiz_provider.dart)*.

### UI/UX

### Content
- **P1 · M**: Answers made wrong by 2024–26 events: 1021, 1051, 1084, 4030, 8083, 6037, 10009, 10091, 1079/10024, 1011, 3048, 5048, 6099, 5022, 2097, 8008, 1014, 1044. Re-check each fact on the day you edit it.
- **P1 · M**: Answers that were never right, or that contradict their own explanation: 10086, 10063, 10082, 5040, 5056, 10092, 3072/10052, 3081, 4081, 7097, 5092, 10095, 3087, 5096, 3090, 6082, 6091, 7093.
- **P1 · L**: Have a person review levels 7–10 in every category; a sample of levels 9–10 found about 1 in 10 wrong. Reviewer checklist: a source for every answer, no wrong option that is also true, and no «الوحيد» or «حتى الآن» without a year.
- **P2 · S**: Question-bank tests. Run the duplicate check's noise words through `_normalize`. Owner to confirm a bare «لا شيء» is acceptable in laws *(question_bank_test.dart)*.

### Release & tech debt
- **P0 · M**: Production gate. Only 5 of the 12 required testers have joined. Recruit 15–20 as a buffer and record the date the 12th joins. Replace the crashing versionCode 1 on the internal track.
- **P1 · S**: Play Console and GitHub tasks:
  - Read and fix the "Some languages have errors" warning.
  - Set the displayed developer name to Oasis Forge.
  - Confirm content rating.
  - Host app-ads.txt at the oasis-forge.github.io root and set it as the listing's Website.
- **P1 · M**: Check on a release build or real phone and log results in PRE_PUBLISH §1:
  - Level pass and fail.
  - Daily challenge shows no replay button.
  - Backup import and export.
  - Shop purchases and the +70-coin ad.
  - Quiz screen and level grid on a real short phone and a real tall one.

### Features
- All Phase 1 features are in PR #8.

---

## Phase 2: first update after launch

### Bugs
- **P2 · S**: The quiz timer keeps running while the app is in the background, so a phone call costs the question. Pause and resume with the app lifecycle and hide the question while paused *(quiz_provider.dart, quiz_screen.dart)*.
- **P2 · S**: «العب مرة أخرى» after a quick-play round ignores the chosen category. Keep the category and pass it back *(quiz_provider.dart, score_screen.dart)*.
- **P2 · S**: The categories screen spins forever if loading fails. Show a friendly error with a retry button *(categories_screen.dart)*. The raw exception text in SnackBars was fixed in PR #8.
- **P3 · S**: Economy leaks. Allow Extra time once per question and cap the speed bonus at 50. Grant the daily heart only if it wasn't already granted today, and show «كسبت قلباً! ❤️» only when a heart was actually added.
- **P3 · M**: Move end-of-round saving out of ScoreScreen's post-frame callback into one provider method with error logging. That callback is what hid the star-saving bug.

### UI/UX
- **P1 · S**: After the daily challenge, the result screen is a dead end. Add a one-tap "remind me tomorrow" card (asks for permission at that moment) and a "play a level" button *(score_screen.dart)*.
- **P2 · S**: Show the pass mark and star thresholds before a level starts, built from AppConfig instead of the hard-coded 10 and 7. Show −1 heart on wrong answers.
- **P2 · S**: Hints and shop clarity:
  - Captions under the hint icons.
  - Disabled hint and buy buttons say why they are disabled.
  - The coin badge looks like a shop button, has a 48 dp tap target, and also works on the Tasks screen.
- **P2 · M**: Large system font sizes:
  - Cap text scaling at 1.3.
  - Make onboarding pages scrollable.
  - Compute the category grid and chip heights.
  - Check the home status row on 320 dp phones.
- **P2 · M**: Accessibility:
  - Use a red that is readable as text (the current one is 2.6:1).
  - Show the correct answer in green in the review list.
  - Announce answer feedback to TalkBack.
  - Label hearts, timer and stars, and give every IconButton a tooltip.

### Content
- **P2 · M**: 32 facts appear twice in different categories, and one level has three Switzerland-2006 questions. Keep one copy of each according to the overlap rules, and add a test that catches near-duplicates with the same answer.
- **P2 · M**: Some explanations reveal the answer to a later question in the same level (1001→1006, 5029→5030…); fix them and add a test. Also fix the 51 questions whose answer gives itself away by length or by repeating a word from the question (laws levels 4–9 first).
- **P2 · M**: Tie record and count questions to a year (1002, 1019, 3015, 5081, 5100…). Add a test banning «حالياً», «الحالي» and «حتى الآن» without a year, and add a post-tournament re-check step to CLAUDE.md.

### Release & tech debt
- **P2 · S**: CI: GitHub Actions runs analyze and test on every PR with Flutter 3.44.8, once in UTC and once in a western time zone.
- **P2 · M**: Upgrade plugins: flutter_timezone 5 (removes the Gradle workaround), share_plus 13, flutter_local_notifications 22, google_mobile_ads 9.1. Retest the reminder, sharing and ads on a release build.
- **P2 · M**: Docs:
  - Replace the stale public README (offline claim, 11 tests, debug key).
  - Rewrite ECONOMY.md in English to match AppConfig.
  - Add a release-notes template for updates.
- **P3 · S**: Release guardrails:
  - The archive tool checks that both files exist and that versionCode and signer are correct.
  - Release builds fail when key.properties is missing.

### Features
- **P1 · M**: Daily challenge: no repeated questions within a cycle and an even difficulty mix (e.g. 2 easy, 3 medium, 2 hard) *(quiz_repository_impl.dart)*. Ship soon after the seed fix so daily sets change only once.
- **P1 · M**: Streak protection bought with coins, plus rewards at 7, 30 and 100 days. Price per decision *(update_streak.dart, user_stats.dart)*.
- **P1 · L**: World Cup 2026 pack: about 100 lasting, person-checked questions, released while interest is high. Placement per decision.
- **P2 · S**: Quick play skips recently seen questions and prefers unlocked levels. Add the new storage key to the backup list.
- **P2 · M**: More rewarded-ad offers, per decision: +1 hint for an ad between questions, and replaying a failed level without losing a heart if decision ① changes.

---

## Phase 3: growth

### Bugs
- Nothing planned yet. Prioritise from error logs and question reports.

### UI/UX
- **P2 · M**: Sound and celebration. Wrong answers are silent, and a level pass sounds the same as a correct answer. Add distinct sounds for wrong answers, the last seconds and level passes, and confetti on 3 stars or a new best *(feedback_service.dart)*.

### Content
- **P3 · M**: Rebalance level difficulty using reviewer ratings (e.g. the specialist records in moments_records level 1).

### Release & tech debt
- **P3 · M**: Revisits a decision: turn R8 back on with keep rules for Room and WorkManager (saves at most 8 MB). Stay on AGP 9 until plugins support AGP 10's defaults.

### Features
- **P2 · M**: Achievements and category mastery with one-time coin rewards, plus a rotating pool of daily tasks that keeps the 130-coin daily total.
- **P2 · M**: A shareable image card for WhatsApp and Instagram stories, and a "challenge a friend" code that replays the same questions without a server.
- **P2 · M**: Free endless modes from the existing questions: Survival and 60-second True/False, with a personal best for each.
- **P2 · L**: In-app purchases per decision: heart packs, acknowledged within 3 days, restored through Play Billing, and a checksum on backup codes.
- **P3 · L**: Revisits local-only storage: Play Games cloud save and achievements, and downloadable question packs (needs privacy policy and Data safety updates).

---

## Decisions only the owner can make
1. **① Heart deduction** (before production).
   - Options: one heart per wrong answer (and then timeouts should cost one too; today they are free) · one per failed attempt · raise the cap or lower the pass mark.
   - **Recommend:** one per failed attempt, and update the onboarding text.
2. **② Name and address on the store page** (before production).
   - Options: personal account with a non-home address · organization account (needs a D-U-N-S number, which takes weeks).
   - **Recommend:** if your name must stay private, apply for D-U-N-S now.
3. **Skip hint scoring.**
   - Options: counts as a miss (and say so in the app) · left out of the level total · replaced by another question.
   - **Recommend:** leave it out of the total, as the code's own comment intends, but no 3 stars on a level with a skip.
4. **Telemetry.**
   - Options: none · local error log plus a feedback email · Firebase Crashlytics and Analytics (needs Data safety and privacy policy updates).
   - **Recommend:** the local log now; Crashlytics and about 8 analytics events in the first update.
5. **Timer while the app is in the background.**
   - Options: keep it running · pause and hide the question · keep it running and show a resume screen.
   - **Recommend:** pause and hide the question.
6. **Shop and monetization.**
   - Options: keep or hide the «قريباً» Remove-ads row · sell heart packs or coins for money · add hint-for-ad and replay-level ads.
   - **Recommend:** hide the row at launch, sell only heart packs, and add hint-for-ad.
7. **Streak protection.**
   - Options: none · protection bought with coins.
   - **Recommend:** at least 200 coins, so a full day of tasks (130 coins) can't buy it, and hold at most one.
8. **World Cup 2026 pack.**
   - Options: a new category · add to world_cup and arab_football (every category needs exactly 100 questions).
   - **Recommend:** a new category, allowing Arab-team 2026 questions in it as a recorded exception to overlap rule 1 (Arab content normally goes to arab_football).
9. **Back-arrow direction.**
   - Options: keep the current arrows · switch to Flutter's `BackButton`, which follows Material's right-to-left convention.
   - **Recommend:** switch; it also gives TalkBack labels.
10. **Tuning:** 20-second timer, 30-minute heart regen, 3 hints a day, level 10 difficulty.
    - Options: keep · adjust.
    - **Recommend:** ask testers directly now and change the numbers in the first update.
11. **Deferred bets** (revisiting decisions): interstitials, multiple languages, cloud save, R8, locking the daily after a quit-and-preview, clock and backup exploits.
    - **Recommend:** keep all deferred and review after about 30 days of production data.

---

## Parked
- Correct answers cluster in one screen position in some levels. Re-run the check after the seed fix.
- After a level pass, make "Next level" the main button instead of Share.
- The home category chips look like they apply to Levels too, and the app uses two different words for "category".
- The completed daily card shows «أكملت تحدي اليوم ✅» twice.
- «مضاعفة» (doubled) in the store listing and on the daily card, but the daily multiplier is ×1.5.
- 13 unused AppStrings constants.
- No test guards against hard-coded Arabic text outside app_strings.dart.
- The splash screen still shows the old `ic_ball` drawing.
- The Σ icon in Settings stats is mirrored.
- The reminder time always shows in 24-hour format.
- `UserStats.lastPlayedDayKey` is saved but never used. Keep it for a future cloud move.
- New question formats: "Who am I?" clues and picture questions that avoid rights issues.
- Back buttons use `arrow_forward` and the quiz Next button `arrow_back`; both auto-mirror, so Arabic shows ← for Back, the reverse of Material's RTL convention. Changing it needs owner approval.
- `cmdline-tools` is missing from the Android SDK (builds work without it).
