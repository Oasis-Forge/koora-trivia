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
- 14 September 2026 (answers batch 1): 10086, 10063, 4030, 8083 and 3048 corrected.
- 14 September 2026: button icons moved to the left (PR #14) · privacy policy published · v1.0.4+5 built, release-checked on the emulator and archived.
- 14 September 2026 (answers batch 2): 5040, 3072, 10052, 1021, 1051 and 6099 corrected.
- 14 September 2026 (answers batch 3): 1084, 6037, 10009, 5056, 1079 and 10024 corrected.
- 14 September 2026 (answers batch 4): 10082, 10092, 3081, 10091, 2097 and 5022 corrected.
- 14 September 2026 (answers batches 5–7): 4081, 7097, 5092, 10095, 3087, 5096, 3090, 6082, 6091, 7093, 1011, 5048, 8008, 1014 and 1044 corrected. Both answer lists from the audit are done.
- 14 September 2026: the bank test bans bare «لا شيء», «لا أحد» and «لم يحدث» options (9006, 9052, 9053, 9060, 9085, 9089, 10048 fixed), normalises the duplicate check's filler words, and 1093 has a single correct answer. Section A of v1.0.5 is done.
- 14 September 2026 (B1): a daily challenge counts for the day it started · day gaps are counted in UTC · a heart is charged only when the answer is recorded · the quiz timer pauses and hides the question while the app is in the background.
- B2: four color themes (ملعب أخضر · ليلي أزرق · بنفسجي · كلاسيكو أحمر) with a «المظهر» picker in Settings, saved with the settings and the backup.
- Language groundwork: no forced locale or RTL (direction follows the language) · side-based paddings, the Tasks badge and gradients made directional · the last hard-coded player text moved into `AppStrings` · `lib/l10n` translation files (Arabic only, used for the app title) · launcher name from `strings.xml` · a test that blocks new hard-coded player text.
- Language choice: the app follows the phone's language unless the player picks one in a «اللغة» panel in Settings, hidden while Arabic is the only language · settings saved before it, and new players until a second language ships, are stored as Arabic so nobody's app switches language later.
- v1.0.6 — design: the current design (four color themes, type, spacing, shape) plus written guidelines and eight current-screen screenshots are exported to the Claude Design project «Koora Trivia — current design» (sources in `design-system/`, sync config in `.design-sync/`). Next: the owner redesigns screens there, then each screen is rebuilt in Flutter in its own PR.
- v1.0.6 — redesign foundation: the new pitch background, `Surface`/`StatusPill`, the three buttons, section headings, rows cards and progress bars, from the owner's Claude Design project, applied to every screen in PRs #34 and #35 (result screen, onboarding and the no-hearts dialog restyled to match).
- v1.0.6 — owner's request, 14 September 2026: the result screen no longer shows the answer recap after any round — level, quick play or the daily (reporting a question stays in the quiz's feedback panel).
- v1.0.6 — the daily card reads «نقاط ×1.5» instead of «نقاط مضاعفة» (the multiplier is ×1.5, not double), and so does the store description · 11 unused strings deleted.
- English, step 1 (app text): `AppStrings` returns Arabic (`AppText`) or English (`EnglishText`), the owner's choice over ARB files · counts in English («1 day», «5 days») · players still see Arabic until the language choice is turned on. The 10 English question files are translated and checked, waiting for step 2.
- 14 September 2026 (owner, Play Console): the crashing versionCode 1 replaced on the internal track · displayed developer name set to Oasis Forge · the "Some languages have errors" warning is left for when a second language is added.
- Hearts and two bugs: a level attempt costs one heart, charged at the start and refunded on a pass (failing, quitting or closing the app keeps it) · the level footer shows the pass mark, star thresholds and heart cost from the real evaluation, and the failed-level hint no longer hard-codes 7 · «العب مرة أخرى» keeps the quick-play category · the categories screen shows an error with a retry button instead of spinning forever.
- Economy leaks and the end of the daily: Extra time once per question · the speed bonus can't pass 50 · the daily heart is granted once per daily (stored `dailyHeartDayKey`) and «كسبت قلباً!» shows only when a heart was added · the daily result screen offers a one-tap «ذكّرني» reminder card (asks permission then) and an «العب مستوى» button to the categories.
- Hints clarity and accessibility: captions under the hint icons, and a disabled hint says why when tapped · disabled shop buttons show their reason · the review list shows the player's pick in red and the correct answer in green (a timeout reads «انتهى الوقت!») · every IconButton has a tooltip (a test enforces it) · screen-reader labels for hearts, the timer and stars.
- End-of-round saving moved into `RecordRound`: stats, daily heart and task, level heart refund, stars and level task in one tested place · each step logs its error and doesn't block the rest · saving no longer stops when the player leaves the result screen, and runs before any interstitial.
- v1.0.6 — Play in-app updates: checked at launch and on resume · a normal release offers Play's flexible update (download in the background, «إعادة التشغيل» when ready), at most every 3 days · a release with priority 4–5 forces the full-screen update · works only for Play installs.
- English, content: the 10 question files and the category names translated by 10 Sonnet agents into `assets/data/en/` (same ids, answers and option order; British English, English Wikipedia spellings) · `english_bank_test` guards the match · not loaded by the app until step 2.
- English, step 2 (questions): the app reads `assets/data/en` when English is active, one cached bank per language · a language change refreshes every open screen the way a theme change does, reloads the category names and reschedules the reminder in the new language · the English folders are declared in `pubspec.yaml`. Players still see Arabic until step 4.
- English, step 3 (layout): arrows follow Android's right-to-left convention (owner) · the reminder time uses the phone's format like the time picker («8:00 م», "8:00 PM") · the share date and the Σ icon no longer assume Arabic · buttons, the daily card button, pills and the home status row shrink long text instead of overflowing · the home stats card's watermark no longer breaks debug builds · every screen is checked at 320 and 360 dp in both languages.
- English, step 4 (on): `app_en.arb` makes English a supported language · new players follow the phone, players who started in Arabic stay on it · the Settings «اللغة» panel appears · `AppLanguageScope` applies `MaterialApp`'s language, so a phone-language change while the app runs is followed too · launcher name «Koora Trivia» in English and Android 13 per-app language (`locales_config.xml`) · English store listing text in `docs/STORE_LISTING.md` · checked on the emulator in English; the question card tags size to their text again (they stretched across the card since #35).
- v1.0.6+7: full test run on `main` (analyze clean, 449 tests) · AAB and APK built · release-checked on the emulator (launch, a full quick-play round to the result screen, Settings version and language) · archived in `releases/v1.0.6_build7_2026-09-14/` with Arabic and English release notes · not uploaded yet.
- English store screenshots: 5 × 1080×1920 in `screenshots/store_9x16_en/` (home, categories, levels, question, answer feedback) for the en-US listing. The Arabic set in `screenshots/store_9x16/` was recaptured the same way in the v1.0.6 design.
- 14 September 2026 (owner): v1.0.6+7 uploaded to Play Console for review with the English (en-US) store listing; v1.0.5 was skipped.
- 15 September 2026 (owner, Play Console): v1.0.6 is on internal and closed testing · the Arabic and English v1.0.6-design screenshots and the English feature graphic are uploaded · the "Some languages have errors" warning is gone. Left: the pre-launch report once Google approves.
- 15 September 2026: the daily challenge plays 2 easy, 3 medium and 2 hard questions, easiest first, and repeats no question within a 133-day cycle · a claimed task's count stops at its goal instead of «21 / 10».
- 16 September 2026, question bank in both languages: 40 questions that repeated a fact from another question replaced (the overlap rules pick the copy kept) · no explanation gives away a later answer in its level · no time-relative wording, and counts and records that can change within a few years anchored to «حتى نهاية موسم 2025-2026» / "By the end of the 2025-26 season" or «بعد كأس العالم 2026» / "After the 2026 World Cup" (owner's decision) · more than a dozen wrong facts found on the way corrected (e.g. 4080, 9030, 10023) · `question_content_test` guards all three.
- 16 September 2026, answer giveaways: in 75 questions the correct option no longer stands out by length or by alone repeating a word from the question (26 of them in laws), in both languages · 10026 is anchored · 2091's options are all name pairs · wrong options that were also true were replaced (e.g. 9055, 9063, 10077) · 8086 and 9068 reworded for accuracy · `question_content_test` guards length and repeated words.
- 18 September 2026: v1.0.8+9 (PRs #55–#58) built, release-checked on the emulator — full-width banner on home, quiz and Settings, an interstitial after the third round, the shop on «قريباً» until the products exist, «Version 1.0.8 (9)», feedback opening the email app to the new address — and archived. Uploaded by the owner to closed testing the same day; in Google's review. The in-app products get created after approval.
- 18 September 2026 (owner's decision): the privacy policy is published from this repo at https://oasis-forge.github.io/koora-trivia/privacy/ by a GitHub Action, and the separate `koora-trivia-privacy` repo is retired; its old address forwards from the root site. The policy gained an "In-app purchases" section (Google Play processes payments; the app keeps Remove ads on the device and restores it from Play). The app links to the new address from the next release. The owner changed the privacy URL in Play Console the same day (it goes to review after v1.0.8 is approved). Left for the owner: archiving the old `koora-trivia-privacy` repo.
- 18 September 2026 (owner's request): the support email is `oasisforge.support@gmail.com` — in the app's feedback and report emails and in the privacy policy source. The live privacy page (effective 18 September 2026) and the Oasis Forge home page carry it too, published through Oasis-Forge/koora-trivia-privacy#1 and Oasis-Forge/oasis-forge.github.io#1. Play Console's store contact changed by the owner the same day.
- 18 September 2026 (owner's request): the banner is full width (standard adaptive, 64 dp on a 411 dp phone; the 128 dp "large" size was measured and rejected), capped at 10% of the screen on the quiz, and a small «إزالة الإعلانات» link above it opens the shop on the menu screens once the products exist. Release-checked on the emulator: banner on home and quiz, interstitial after the third round, shop shows «قريباً» until the products exist.
- 17–18 September 2026: Play Billing — `coins_small` (200 coins), `remove_ads`, and `remove_ads_bundle` (Remove ads + 500 coins, coins on the original purchase only). Money buys coins, never hearts, so hearts stay capped at 5 (owner's decision of 18 September). Remove ads stops the banner and interstitials but not the rewarded ad, purchases are acknowledged on completion, and the entitlement stays out of the backup code (it is shareable). The shop keeps its «قريباً» row until Play returns the products, so this ships before the payments profile is verified.
- 17 September 2026 (owner's decision): interstitials on — after the result screen, every 3 rounds, at least 3 minutes apart, never after the daily challenge and never before the review prompt.
- 17 September 2026 (owner's decision): a bottom banner on home, categories, levels, tasks, shop, settings and the quiz. It reserves its height before the ad arrives so nothing above it shifts under the player's finger, and `AppConfig.bannersEnabled` switches it off.
- 16 September 2026: app-ads.txt set as the Play listing's Website and verified in AdMob (owner) · the 32 merged PR branches deleted · v1.0.7+8 built, archived and uploaded by the owner to closed testing (no full test run or emulator check, owner's call).
- PR #7, merged 14 September 2026: the level grid fits all ten levels on 360×640 and 411×731 · compact quiz layout below 700 dp, options anchored above the hints bar, feedback panel scrolls into view · Skip shown as a skip on the quiz screen and in the review · backup import validates every value, reloads every provider, and datasources survive badly typed values · widget tests for result-screen buttons, the level grid, the quiz layout, and a real-storage import test.
- PR #6, merged 13 September 2026: the daily reminder fires (receivers and a status-bar icon; verified on a release build on the emulator, including after a reboot); one reminder per day for the next week, skipping today once the daily is done, naming the streak in the first, and taking the question count from AppConfig · hearts, the countdown and tasks refresh on resume and every 30 s, and a granted heart no longer resets the countdown · the no-hearts dialog offers the daily challenge (only if not done), an ad and a 200-coin refill, with «حسناً» · count-noun grammar helper used for days, stars, levels, points, questions and correct answers.
- PR #5, merged 13 September 2026: ads wait for UMP consent (`canRequestAds()`) and start at launch instead of when Settings, the result screen or the shop first opens · Settings privacy row with ad privacy options and the policy link · the rewarded-ad button enables when an ad loads and failed loads retry with backoff and on resume, as does a failed consent update · Data safety docs list what AdMob collects · privacy policy source updated · the manifest's AdMob comment fixed · the Arabic DATA_SAFETY.md copy deleted.

---

## Phase 1: before production (during the 14-day closed test)

### Bugs

### UI/UX

### Content
- **P1 · L**: Have a person review levels 7–10 in every category; a sample of levels 9–10 found about 1 in 10 wrong. Reviewer checklist: a source for every answer, no wrong option that is also true, and no «الوحيد» or «حتى الآن» without a year. Also check laws 9058: VAR can't normally review an offside once the flag has stopped play.

### Release & tech debt
- **P0 · S · owner**: Finish the payments profile (under verification on 17 September 2026), then create the three products in Play Console with ids `coins_small`, `remove_ads`, `remove_ads_bundle`, set their prices (owner's plan: $1.99 · $2.99 · $4.99), and add a licence tester to buy without paying. Nothing sells until this is done.
- **P0 · M**: Production gate. Only 5 of the 12 required testers have joined. Recruit 15–20 as a buffer and record the date the 12th joins.
- **P1 · M**: Check on a real phone (the emulator release check passed on 14 September 2026) and log results in PRE_PUBLISH §1:
  - The in-app review sheet, from a closed-test install.
  - Quiz screen and level grid on a real short phone and a real tall one.

### Features
- **P1 · S**: English is built (steps 1–4, see Done). Left: a person fluent in English spot-checks the translated questions (the English store listing went up with v1.0.6).

---

## Phase 2: first update after launch

### Bugs
- None open.

### UI/UX
- **P2 · S**: The coin badge looks like a shop button, has a 48 dp tap target, and also works on the Tasks screen.
- **P2 · M**: Large system font sizes:
  - Cap text scaling at 1.3.
  - Make onboarding pages scrollable.
  - Compute the category grid and chip heights.
  - Check the home status row on 320 dp phones.
- **P2 · M**: Accessibility:
  - Use a red that is readable as text (the current one is 2.6:1).
  - Announce answer feedback to TalkBack.

### Content

### Release & tech debt
- **P2 · S**: CI: GitHub Actions runs analyze and test on every PR with Flutter 3.44.8, once in UTC and once in a western time zone.
- **P2 · M**: Upgrade plugins: flutter_timezone 5 (removes the Gradle workaround), share_plus 13, flutter_local_notifications 22, google_mobile_ads 9.1. Retest the reminder, sharing and ads on a release build. Builds already warn that some plugins don't support Flutter's Built-in Kotlin yet.
- **P2 · M**: Docs:
  - Replace the stale public README (offline claim, 11 tests, debug key).
  - Rewrite ECONOMY.md in English to match AppConfig.
  - Add a release-notes template for updates.
- **P3 · S**: Release guardrails:
  - The archive tool checks that both files exist and that versionCode and signer are correct.
  - Release builds fail when key.properties is missing.

### Features
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
- **P3 · S**: A checksum on backup codes (was bundled with the in-app purchases item, now in phase 1).
- **P3 · L**: Revisits local-only storage: Play Games cloud save and achievements, and downloadable question packs (needs privacy policy and Data safety updates).

---

## Decisions only the owner can make
1. **① Heart deduction** — **decided 14 September 2026:** one heart per failed attempt (done in v1.0.5).
2. **② Name and address on the store page** (before production).
   - Options: personal account with a non-home address · organization account (needs a D-U-N-S number, which takes weeks).
   - **Recommend:** if your name must stay private, apply for D-U-N-S now.
3. **Skip hint scoring.**
   - Options: counts as a miss (and say so in the app) · left out of the level total · replaced by another question.
   - **Recommend:** leave it out of the total, as the code's own comment intends, but no 3 stars on a level with a skip.
4. **Telemetry.** The local error log and feedback email shipped (PR #8). Still open: Crashlytics and about 8 analytics events in the first update (needs Data safety and privacy policy updates).
5. **Timer while the app is in the background** — done in v1.0.5 (B1): the quiz pauses and hides the question.
6. **Shop and monetization** — **decided 17 September 2026:** banners and interstitials now, then Play Billing for Remove ads and heart packs. The «قريباً» row stays until it can be bought.
7. **Streak protection.**
   - Options: none · protection bought with coins.
   - **Recommend:** at least 200 coins, so a full day of tasks (130 coins) can't buy it, and hold at most one.
8. **World Cup 2026 pack.**
   - Options: a new category · add to world_cup and arab_football (every category needs exactly 100 questions).
   - **Recommend:** a new category, allowing Arab-team 2026 questions in it as a recorded exception to overlap rule 1 (Arab content normally goes to arab_football).
9. **Back-arrow direction** — **decided 14 September 2026:** follow Android's right-to-left convention (Back points right in Arabic and left in English, the quiz's Next the opposite). Done in English step 3.
10. **Tuning:** 20-second timer, 30-minute heart regen, 3 hints a day, level 10 difficulty.
    - Options: keep · adjust.
    - **Recommend:** ask testers directly now and change the numbers in the first update.
11. **Deferred bets** (revisiting decisions): interstitials, cloud save, R8, locking the daily after a quit-and-preview, clock and backup exploits.
    - **Recommend:** keep all deferred and review after about 30 days of production data.

---

## Parked
- Correct answers cluster in one screen position in some levels. Re-run the check after the seed fix.
- After a level pass, make "Next level" the main button instead of Share.
- The home category chips look like they apply to Levels too, and the app uses two different words for "category".
- The splash screen still shows the old `ic_ball` drawing.
- `UserStats.lastPlayedDayKey` is saved but never used. Keep it for a future cloud move.
- New question formats: "Who am I?" clues and picture questions that avoid rights issues.
- `cmdline-tools` is missing from the Android SDK (builds work without it).
