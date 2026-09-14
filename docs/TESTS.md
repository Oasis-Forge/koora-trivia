# Tests

> Moved from CLAUDE.md on 14 September 2026. Update the count and the table when tests are added.

**359 tests across 42 files, all passing.** `flutter analyze` is clean. Shared test code lives in
`test/fakes/`: `fake_ad_service.dart` (add any new `AdService` member there), `fake_repositories.dart`
(in-memory repositories, a scheduler and `fakeQuestions`), and `score_screen_harness.dart`
(`pumpScoreScreen` plays a full level, quick-play or daily round and shows the result screen).

| File | Count | Covers |
|---|---|---|
| `quiz_provider_test.dart` | 26 | Scoring · speed bonus · multipliers · timer · sequencing · result building · a load error shows a friendly message and is reported to `FlutterError` · an answer is recorded once, never after time-up · pause freezes the timer · the daily keeps the day it started |
| `should_ask_for_review_test.dart` | 5 | Review prompt rules: daily streak threshold · 3 stars only · never after quick play · never after an ad · 30-day gap |
| `score_screen_review_test.dart` | 9 | **Widget test** — the result screen asks for a review after a 3-day daily streak or 3 stars, not after a shorter streak, 2 stars, a failed level, a recent ask or an interstitial · not once the player has left for the next round · «أعد المستوى» waits for a review request in progress · every review row has «أبلغ عن خطأ» |
| `email_builders_test.dart` | 7 | `mailto` encoding (`%20`, newlines, `&`) · question report: recipient, subject, id, category, level, text, options with the approved one marked, version · distinct reason labels · feedback email: version, "no errors", newest errors only with date and time, long ones cut |
| `report_question_button_test.dart` | 6 | **Widget test** — reasons sheet, the chosen reason opens the email · dismissing opens nothing · no mail app shows the address · compact icon with tooltip · the sheet stays until the mail app is asked, and a second tap doesn't open twice · dismissing it meanwhile doesn't close the screen under it |
| `error_log_test.dart` | 7 | `PrefsErrorLog`: newest first with stack top · cap · long messages cut · rapid writes all kept · corrupt log recovers · `installErrorHandlers`: framework errors logged and passed on · uncaught async errors logged and still printed by the engine |
| `platform_services_test.dart` | 3 | Review prompt time recorded even when Play's dialog fails · none before the first ask · `PackageAppInfo` version and build |
| `economy_test.dart` | 18 | Heart regen (remainder · clock going backward · corrupt date) · daily limits · `EconomyProvider` (deduction · daily-challenge grant · rewarded-ad cap · hints) |
| `level_progress_test.dart` | 13 | Star calculation · progressive unlocks · stars never decrease (entity and use case) |
| `tasks_coins_test.dart` | 12 | Daily tasks (completion · claim once · chest · daily reset) · shop (heart refill · insufficient coins · hint pack and consumption order) |
| `ads_test.dart` | 14 | `AdsProvider` (earned/dismissed · no two ads at once · isReady · notifies when an ad loads · privacy options and resume pass through · dispose detaches) · interstitials (round counting · remove-ads) · ad rewards — **through a fake service** |
| `admob_ad_service_test.dart` | 21 | **Consent gate** — no SDK init or ad request before the consent form closes · previous-session consent loads at once · nothing loads when consent disallows · consent withdrawn during SDK init · a failed consent update retried on resume or ad request, never two at once, not re-run after a successful one · load retry after the delay and on resume · privacy-options changes applied both ways · unsupported platform · init once · **rewarded show path with a fake `RewardedAd`**: result decided on dismissal, not on show (the 8 September bug) · earned · dismissed · failed to show · reload afterwards |
| `retrying_ad_loader_test.dart` | 11 | Load once · rising retry delays capped at the last · success resets the delay · take once · retry now · stop cancels and disposes · an ad arriving after stop is disposed · a stale callback after stop and a new load · synchronous SDK error |
| `reminder_test.dart` | 16 | `SettingsProvider` — permission · schedule and cancel · permission revoked at launch cancels · launch always reschedules · finishing the daily moves the first reminder to tomorrow with the streak · a broken streak isn't named · no reschedule for an unchanged plan · after midnight the new day isn't treated as done · reminder body names the streak and the question count from `AppConfig` |
| `plan_reminders_test.dart` | 8 | Which days get a reminder: today before the time · tomorrow after the daily or after the time · consecutive days, streak only in the first · month end · minutes |
| `arabic_count_test.dart` | 17 | Count-noun forms for 0 · 1 · 2 · 3–10 · 11–99 · 100+ · dual after a verb · every noun has distinct forms |
| `android_config_test.dart` | 5 | Notification receivers declared, without `MY_PACKAGE_REPLACED` · `appCategory="game"` · `mailto` and `https` queries · status-bar icon in every density · kept from resource shrinking |
| `hearts_refresh_test.dart` | 8 | Countdown moves and notifies without saving · a regenerated heart saves · a granted heart keeps the countdown · the first lost heart shows the countdown · **widget:** the hearts bar updates itself every 30 s, and does nothing when hearts are full |
| `no_hearts_dialog_test.dart` | 8 | **Widget test** — no dialog with hearts · daily-challenge button starts the daily · hidden once the daily is done · refill disabled without coins · refill buys and closes · closes by itself when a heart regenerates · a save finishing after it closed doesn't pop the screen underneath · «حسناً» closes only the dialog |
| `daily_challenge_card_test.dart` | 1 | **Widget test** — the card's question count and multiplier line |
| `share_text_test.dart` | 9 | Result grid · daily-challenge date · category and level · streak count forms (1 · 2 · 5 · 11) · the Play Store link with referrer on the last line · doesn't leak questions |
| `quiz_repository_test.dart` | 11 | Levels · daily-challenge stability · **a full year with no day sharing more than 2 of 7 questions with the day before** · epoch day independent of time zone · neighbouring seeds shuffle differently · filtering |
| `question_bank_test.dart` | 9 | Bank integrity: counts · IDs · structure · balance · banned options, including bare «لا شيء», «لا أحد» and «لم يحدث» · no hidden direction characters · **duplicates** · matches `AppConfig` |
| `update_streak_test.dart` | 6 | Day-streak logic in every case · daylight-saving days count as one day |
| `settings_screen_test.dart` | 19 | **Widget test** — stats display · the built version number · «أرسل ملاحظاتك» opens an email with the version and recent errors, or shows the address without a mail app · confirmation dialog with the loss in correct Arabic, including the dual after a verb · reset · privacy: ad-options row only where required, opens the form, failure message · policy link opens the published URL, failure message · backup import shows the imported progress without a restart · an invalid code changes nothing · picking a color theme saves it and marks the swatch · the language panel stays hidden with one language, and with two saves the phone language or the picked one |
| `restore_backup_test.dart` | 4 | **Real datasources over mock SharedPreferences** — imported data shows at once and survives the first save from every provider · without the reload the first save overwrites it (why `RestoreBackup` exists) · a code with reminders off cancels the device's reminders and nothing reschedules them · a corrupt code changes nothing |
| `score_screen_buttons_test.dart` | 6 | **Widget test** — result screen: level pass shows "Next level" and "Replay level" · fail shows only "Replay level" · last level has no "Next level" · daily has no replay or next · quick play shows "Play again" · a skipped question reads as a skip in the review |
| `button_icons_test.dart` | 1 | **Widget test** — with the app theme in RTL, the icon of every filled, outlined and text button sits left of its label |
| `theme_test.dart` | 7 | Four themes, unknown id falls back to green · text contrast in every theme, none less readable than the original green · theme saved and read back, old settings stay green · the provider saves the choice · backups carry it · **widget:** a switch rebuilds const widgets with the new colors · the result screen builds under every theme |
| `localization_groundwork_test.dart` | 4 | No Arabic player text in string literals outside `AppStrings` (developer messages and the `ArabicCount` table excepted) · translation files hold Arabic only and the app title matches `AppStrings.appName`, as does the launcher name · **widget:** an English device still gets Arabic, right to left · the formats moved into `AppStrings` produce the same text |
| `language_choice_test.dart` | 5 | New players get Arabic while it's the only language, the phone language once there are two · the phone language and a picked one are saved and read back, older settings read as Arabic · `copyWith` can switch to the phone language · the provider saves the choice · backups carry the phone-language choice |
| `level_attempt_test.dart` | 4 | The thresholds shown before a level match the evaluation (no 0.7 × 10 rounding error) · **widget:** `NoHeartsDialog.startLevel` charges one heart when the level starts · with no hearts it shows the dialog and starts nothing · a level that fails to load charges nothing |
| `categories_and_replay_test.dart` | 3 | A categories load failure is flagged and logged, and a retry succeeds · **widget:** the categories screen shows the error and a retry button instead of spinning · «العب مرة أخرى» after quick play in a category replays that category |
| `levels_screen_test.dart` | 6 | **Widget test** — completed, available and locked tiles · the first open level is auto-selected · a locked tap explains and keeps the selection · level 10 fully visible above the footer on 360×640 and 411×731 · the footer shows the pass mark, star thresholds and heart cost from the evaluation |
| `quiz_screen_layout_test.dart` | 11 | **Widget test** — «أبلغ عن خطأ» appears in the feedback panel only after the answer · on 360×640 the 4th option sits above the hints bar in the compact size · on a tall screen the options sit right above the hints bar · the feedback panel scrolls fully into view · the next question starts at the top again · a panel taller than the screen shows its title · a short question's card is as wide as the options · Skip reads as a skip, time-up still as time-up · a quick double tap on a wrong option records one answer and charges no heart · leaving the app pauses the timer and hides the question |
| `progress_provider_test.dart` | 5 | **Provider-to-storage wiring** — pass ⇒ stars ⇒ next unlocked · survives restart (guards the covariance bug) |
| `daily_guard_test.dart` | 6 | `isDailyDone` after completion · persists across restart · quick play doesn't set it · a daily started before midnight counts for its start day |
| `backup_test.dart` | 13 | Export then import · corrupt code · extra whitespace · newer version rejected · one badly typed value rejects the whole code and writes nothing · non-string value · unreadable day key · no known key · every datasource reads a badly typed stored value as defaults instead of throwing |
| `economy_balance_test.dart` | 4 | Daily income below cheapest purchase · purchase within two days · interstitials off · chest is worth it |
| `score_screen_hearts_test.dart` | 4 | **Widget test** — result screen: a failed level keeps the charged heart and shows «فقدت قلباً», and "Replay level" with zero hearts shows the no-hearts dialog · a pass refunds the heart, so "Next level" starts and charges it · replay with hearts starts · quick play stays free |
| `rewarded_button_test.dart` | 4 | **Widget test** — enables by itself when the ad loads and disables again if it's lost · daily limit · reward only on earned |
| `app_lifecycle_hooks_test.dart` | 3 | Returning to the app retries ads, regenerates hearts and reschedules the reminder for a new day · finishing the daily reschedules at once · no lifecycle or stats listener left after removal |

### Not covered — and it has bitten us

- **The real AdMob SDK.** `admob_ad_service_test` drives the consent gate, retries and the rewarded
  show path through fakes (including a fake `RewardedAd` that fires callbacks in the SDK's order),
  but the real UMP form and the SDK's own callback timing still need a hand test on the emulator.
  Before PR #5 nothing covered this, which is how the "reward is never granted" bug slipped through.
- **The quiz screen's gameplay through the UI** — the hints bar and the quit dialog — has no widget test
  (a double tap recording one answer and the background pause do); only its layout and feedback panel do (`quiz_screen_layout_test`).
  Result-screen buttons and the level grid are covered since PR #7.
- **Release-build-only failures** (R8, signing) — `flutter test` can't catch them.
- No integration tests (`integration_test`).
- No guard against hardcoded user-visible strings — 28 literal lines already bypass `app_strings.dart`.
- **The in-app review dialog and real mail apps.** `score_screen_review_test` covers when the prompt is
  requested and `report_question_button_test` the `mailto` link, but Play shows the dialog only to
  Play installs, and each mail app parses `mailto` its own way — check both from the closed test.
- **Real notification delivery.** `reminder_test` uses a fake scheduler, which is how the missing
  manifest receivers went unnoticed until PR #6. `android_config_test` now guards the receivers and
  the icon, but actual firing still needs a check on a device after any change to the reminder.

**Timer tests:** `quiz_provider_test.dart` uses `fakeAsync` from the `fake_async` package
(declared in `dev_dependencies`) to fast-forward time instead of waiting. Required patterns:
`async.flushMicrotasks()` after an un-awaited `start*` call, and `quiz.dispose()` **inside** the
`fakeAsync` block, otherwise the test fails with a pending timer.

---
