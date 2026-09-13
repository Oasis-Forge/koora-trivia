# Koora Trivia: owner plan (13 Sep 2026)

> From the full audit on 13 September 2026: 152 findings; every bug, UI, content and release item was re-checked by a second agent. Update this file as items ship, and re-check each content fact on the day you edit it.

## Done since the audit
- Daily challenge repeating on consecutive days, and its seed depending on the time zone: PR #2, merged 13 September 2026.
- "Replay level" and "Next level" on the result screen starting a level with zero hearts: PR #3, merged 13 September 2026.

---

## Phase 1: before production (during the 14-day closed test)

### Bugs
- **P1 · S**: The daily reminder never fires. Declare `ScheduledNotificationReceiver` and the boot receiver in `AndroidManifest.xml`, and add a one-colour status-bar icon (the launcher icon shows as a blank shape). Verify on a release build, including after a reboot.
- **P1 · M**: The rewarded-ad button never re-enables once an ad loads, and failed loads are never retried. Have AdService report load state so `AdsProvider` notifies, and retry with backoff and on resume *(admob_ad_service.dart, ads_provider.dart, rewarded_button.dart)*.
- **P1 · S**: Hearts, the refill countdown and tasks stay frozen on screen. Refresh `EconomyProvider` when the app resumes and every ~30 s while hearts are below max. Compute the countdown from `lastRegenAtIso`, which also fixes the 30-minute reset after a granted heart.
- **P1 · S**: An imported backup gets overwritten by the next save. After import, reload every provider, check each value against its model, and catch TypeError in the local datasources *(backup_repository_impl.dart, settings_screen.dart)*.
- **P1 · S**: The levels grid hides level 10 on 360×640 and 411×731 phones. Size the tiles with `LayoutBuilder` and let the grid scroll *(levels_screen.dart)*.
- **P1 · S**: Using the Skip hint shows «انتهى الوقت!» and a red review row. Use `AnswerRecord.skipped` and the unused `skippedAnswer` string *(quiz_screen.dart, score_screen.dart)*.
- **P2 · S**: Follow-ups to the day-key fix (PR #2). Record the day key when the daily starts (finishing after midnight resets the streak), and use UTC dates in `daysBetween` so daylight-saving days count correctly *(day_key.dart, stats_provider.dart)*.
- **P2 · S**: Charge a heart only when `QuizProvider` actually records the answer (`selectAnswer` returns bool). This closes the double-tap and timeout-frame race. Ship it with decision ① *(quiz_screen.dart, quiz_provider.dart)*.

### UI/UX
- **P1 · M**: On 360×640 phones the 4th answer is below the fold while the timer runs. Add a compact layout below ~700 dp, scroll the feedback panel into view, and check the tall-device gap in the same pass *(quiz_screen.dart, answer_option.dart)*.
- **P1 · S**: No-hearts dialog. Its only button, «متابعة اللعب», should say "OK". Hide the daily-challenge advice once the daily is done, and add a «العب تحدي اليوم» button and a 200-coin refill button *(hearts_bar.dart)*.

### Content
- **P1 · S**: Count-noun grammar is wrong. Add one helper for days, stars, levels and points, and use it in the share text («1 أيام», «12 أيام») and the task title «أجب إجابة صحيحة». Fix the two tests that assert the wrong forms.
- **P1 · M**: Answers made wrong by 2024–26 events: 1021, 1051, 1084, 4030, 8083, 6037, 10009, 10091, 1079/10024, 1011, 3048, 5048, 6099, 5022, 2097, 8008, 1014, 1044. Re-check each fact on the day you edit it.
- **P1 · M**: Answers that were never right, or that contradict their own explanation: 10086, 10063, 10082, 5040, 5056, 10092, 3072/10052, 3081, 4081, 7097, 5092, 10095, 9073, 3087, 5096, 3090, 6082, 6091, 7093.
- **P1 · S**: Remove the second correct option from 1080/10043, 1096, 10081, 8089, 8088, 3083 and 2098. Weaker cases: 10099 and 5098.
- **P1 · S**: Fix the spelling of Koeman, Rooney, Passarella, Yaya Touré, Rocco, Sepp Maier, Halilhodžić, Atalanta, Stupar, Barbados, Villalonga, Nándor and Xavi. Fix the wording of 3086, 5090, 5093, 5099 and 6098, and remove the invisible U+200F character.
- **P1 · L**: Have a person review levels 7–10 in every category; a sample of levels 9–10 found about 1 in 10 wrong. Reviewer checklist: a source for every answer, no wrong option that is also true, and no «الوحيد» or «حتى الآن» without a year.
- **P2 · S**: Question-bank tests. Ban «كلتاهما», add a test for invisible characters, and run the duplicate check's noise words through `_normalize`. Owner to confirm a bare «لا شيء» is acceptable in laws *(question_bank_test.dart)*.

### Release & tech debt
- **P0 · S**: The Data safety form under-declares what AdMob collects. Add Approximate location, App interactions and Diagnostics, each for advertising, analytics and fraud prevention. Make DATA_SAFETY_EN.md and PRE_PUBLISH.md match.
- **P0 · M**: Ad consent. Wait for the consent check (UMP) to finish and load ads only when `canRequestAds()` is true. Add a Settings privacy row that opens `showPrivacyOptionsForm`, plus an in-app privacy policy link. Test with the EEA debug geography *(admob_ad_service.dart, settings_screen.dart)*.
- **P0 · M**: Production gate. Only 5 of the 12 required testers have joined. Recruit 15–20 as a buffer and record the date the 12th joins. Replace the crashing versionCode 1 on the internal track.
- **P1 · S**: Privacy policy. Remove the offline promise, disclose Android Auto Backup, add IP address and diagnostics, and describe the privacy options. Update the date, deploy to privacy-site, and check the live page (it still shows 6 September).
- **P1 · S**: Play Console and GitHub tasks:
  - Read and fix the "Some languages have errors" warning.
  - Set the displayed developer name to Oasis Forge.
  - Confirm content rating.
  - Host app-ads.txt at the oasis-forge.github.io root and set it as the listing's Website.
- **P1 · M**: Error visibility (see the Telemetry decision). Set `FlutterError.onError` and `PlatformDispatcher.onError` in main.dart, and send errors at least to a local log and a "send feedback" email.
- **P1 · M**: Check on a release build or real phone and log results in PRE_PUBLISH §1:
  - Level pass and fail.
  - Daily challenge shows no replay button.
  - Reminder fires, including after a reboot.
  - EEA consent form.
  - Backup import and export.
  - Shop purchases and the +70-coin ad.
  - 360×640 layout.
- **P1 · M**: Widget tests for result-screen button visibility (pass, fail, daily, quick play) and locked/unlocked levels, plus a provider test that imports a backup, saves, and checks the imported data survives.
- **P2 · S**: Settings → About shows «الإصدار 1.0.0». Read the real version with `package_info_plus` *(app_strings.dart, settings_screen.dart)*.
- **P2 · S**: Add `android:appCategory="game"` so Android 16 keeps the portrait lock on tablets and foldables *(AndroidManifest.xml)*.

### Features
- **P1 · S**: The share text has no link to the app. Add the Play Store URL with a UTM referrer on its own line *(build_share_text.dart, share_text_test)*.
- **P1 · S**: Ask for an in-app review only at good moments (3rd daily with a streak of 3 or more, or a 3-star pass), at least 30 days apart, never after a failed level or an ad.
- **P1 · S**: Add a "report this question" flag after the answer is revealed and in the review list. It opens the share sheet or an email with the question id, reason and app version; nothing is sent automatically.
- **P1 · S**: Skip the reminder on days the daily is already done, mention the streak in its text, and take the question count from AppConfig (the text currently hardcodes seven) *(local_notification_scheduler.dart)*.

---

## Phase 2: first update after launch

### Bugs
- **P2 · S**: The quiz timer keeps running while the app is in the background, so a phone call costs the question. Pause and resume with the app lifecycle and hide the question while paused *(quiz_provider.dart, quiz_screen.dart)*.
- **P2 · S**: «العب مرة أخرى» after a quick-play round ignores the chosen category. Keep the category and pass it back *(quiz_provider.dart, score_screen.dart)*.
- **P2 · S**: Raw exception text shows in SnackBars, and the categories screen spins forever if loading fails. Show a friendly error with a retry button *(quiz_provider.dart, categories_screen.dart)*.
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
  - Delete the Arabic DATA_SAFETY.md copy.
  - Add a release-notes template for updates.
- **P3 · S**: Release guardrails:
  - The archive tool checks that both files exist and that versionCode and signer are correct.
  - Release builds fail when key.properties is missing.
  - Fix the manifest comment that calls the live AdMob ID a test ID.

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