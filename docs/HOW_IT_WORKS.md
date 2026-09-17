# How the app works

> Moved from CLAUDE.md on 14 September 2026. Read the section for the system a task touches. The rules that are easy to break are summarised in CLAUDE.md.

## ✅ Done

**The game**
- Complete, verified 1000-question bank · three-layer Clean Architecture + Provider
- Three modes: levels (category grid → level grid → quiz) · quick play · daily challenge
- Deterministic daily challenge (same questions for everyone, no server, date-derived seed), once per day
- Day streak `user_stats_v1` · level progress with stars and progressive unlocks `level_progress_v1`
- Result screen: level stars · "Next level" on a pass · "Replay level" · no answer review after any round (owner, 14 September 2026) · share
- Economy: regenerating hearts + hints + daily limits · coins + 3 daily tasks + chest + shop
- Rewarded ads (heart · 70 coins) and interstitials (off) — production IDs in release · UMP consent
  gate, privacy row in Settings and retried ad loads (PR #5)
- Daily reminder on device time, one per day that skips days the daily is done (PR #6) · haptics and sound via system sounds (no audio files), two toggles
- One-time onboarding · settings with stats and safe reset · progress export/import (Base64)
- Full RTL + stadium theme · level grid is 3 centered columns (was 4 with a big empty gap)

**Publishing**
- Final `applicationId` · release signing · `.aab` ≈57 MB and `.apk` ≈60 MB (R8 off)
- Professional icon in every size + adaptive · store assets · privacy policy published
- Release archive `releases/` + `tool/archive_release.dart`
- Full emulator verification on a release build (8 September 2026) — see [PRE_PUBLISH.md](PRE_PUBLISH.md)

**Four critical bugs fixed after the first upload** (none visible in debug or in tests):
R8 crashing launch · a covariance bug blocking star saving and the Next-level button · rewarded-ad
reward never granted · a replay button implying the daily challenge could be repeated. Details in
each section.

**Two more fixed on 13 September 2026** (PRs #2 and #3 — merged, not yet in a Play build):
- **The daily challenge repeated every other day.** `SeededRandom` forced seeds odd with `| 1`, so
  day numbers 2k and 2k+1 shuffled identically; and `DayKey.epochDay` depended on the time zone. The
  day number is now computed in UTC. One-time effects when v1.0.4 ships: that day's set may change for
  players who haven't played it yet, and level questions with an even id get a new option order once.
- **Zero hearts let players replay levels.** The result screen's "Replay level" and "Next level"
  buttons skipped the levels screen's check. **Every button that starts a level must go through
  `NoHeartsDialog.startLevel`** (checks hearts, charges one heart at the start, refunded on a pass); quick play and the daily challenge stay free.

### Design system (v1.0.6 redesign)

The look comes from the owner's Claude Design project «تحدي كرة القدم تصميم جديد», built on the app's own tokens
(exported as «Koora Trivia — current design»). Shared pieces, all palette-driven so the four themes still work:

- **`PitchBackground`** — pitch gradient, mowing stripes every 120 dp at 2% white, halfway line and circle at 42% of
  the height, a penalty box at the bottom, a 520 dp ball watermark at 1.8% white, and a soft glow from the top.
- **`Surface`** — card colour, thin border, a white sheen over the top 46%, and a soft shadow. `StatusPill` is the
  48 dp pill built on it (hearts, coins, stars, and short buttons).
- **`GoldButton`** (56 dp, gold gradient, sheen, warm glow), **`SolidButton`** (56 dp, pitch-light gradient) and
  **`OutlineButton`** (52 dp, 3% fill, 1.4 dp border). The icon is written after the label, so it sits on its left in
  Arabic.
- **`SectionHeading`** (gold, 17 dp), **`RowsCard`** + **`KooraRow`** (48 dp rows with hairline dividers, gold lead
  icon, bold value) and **`KooraProgress`** (6 dp, green or gold).

Every screen uses them (one PR, owner's request): home, categories, levels, quiz and its quit dialog, settings (its extra
sections kept), tasks, shop, plus the result screen, onboarding and the no-hearts dialog, which the redesign didn't cover.

### In-app updates (v1.0.6)

- `AppLifecycleHooks` asks Play at launch and on every resume (`CheckForUpdate` → `PlayAppUpdater`, plugin
  `in_app_update`). `ChooseUpdateMode` decides:
  - **Normal release (priority 0–3):** Play's flexible update — a Play dialog, a background download, then a
    «نُزّل تحديث جديد للتطبيق · إعادة التشغيل» snackbar. Offered at most every `AppConfig.flexibleUpdateAskEveryDays`
    (3) days; the last offer time is device-local (`update_prompt_v1`, not in backups).
  - **Priority ≥ `AppConfig.forceUpdatePriority` (4):** Play's full-screen immediate update, shown again on every resume
    until the player updates. Use it only for crash or data-loss fixes.
- **Priority can't be set in the Play Console website** — only through the Google Play Developer API when creating the
  release (`edits.tracks.update` → `releases[].inAppUpdatePriority`).
- **Only apps installed from Play** get updates; on the emulator or a sideloaded APK Play answers with an error that
  is swallowed (debug print only). Test through internal app sharing or a testing track with an older build installed.
- Players on v1.0.5 or older can't be forced — they don't have this code.

### Ads — what to know

> 🐛 **Critical bug, fixed (8 September 2026):** `AdMobAdService.showRewarded` returned as soon as
> the ad was *shown* (`await ad.show`), not when it was dismissed, so the reward flag was read
> before the `onUserEarnedReward` callback arrived ⇒ it always returned `dismissed` and the reward
> was **never** granted (heart or 70 coins). Fix: wait for dismissal with a `Completer` completed
> in `onAdDismissedFullScreenContent`, then read the flag. Verified on the emulator: watching the ad
> now actually grants the heart (0 → 1). Since PR #5 `admob_ad_service_test` guards it with a fake
> `RewardedAd`; still test by hand after any change to the rewarded-ad path.

| Type | Where | Reward |
|---|---|---|
| Rewarded | No-hearts dialog | +1 heart (max 4 per day) |
| Rewarded | Shop | +70 🪙 (no limit) |
| Interstitial | After the result | Every 3 rounds, 3-minute cap — on since 17 September 2026 |
| Banner | Bottom of home, categories, levels, tasks, shop, settings and the quiz | `BannerSlot`, owner's decision of 17 September 2026 |

- **`AppConfig.interstitialsEnabled = true` since 17 September 2026 (owner's decision),** before the
  public launch, so closed testers meet it first. It was off until then because first-days ratings on
  Play carry a lot of weight. `economy_balance_test` now guards the two caps instead of the flag:
  without them the ad would come after every round.
- **Never an interstitial after the daily challenge** — deliberate, to protect the daily ritual.
- **`BannerSlot` reserves its 58 dp before the ad arrives** (`AppConfig.bannersEnabled` turns it
  off). A band that appears only once the ad loads would push the answer buttons up under the
  player's finger, and AdMob counts the resulting tap as invalid traffic. For the same reason the
  size is the fixed `AdSize.banner`, not an adaptive one, and the slot keeps an 8 dp gap above it.
  It is `Scaffold.bottomNavigationBar`, so it never scrolls with the content. The score screen has
  none — that is where the interstitial shows.
- `BannerSlot.testAdBuilder` replaces the real ad in widget tests (there is no platform to load one).
- The reward is granted on `RewardResult.earned` **only**, never on early dismissal.
- The rewarded-ad button shows disabled with «يتطلب اتصالاً بالإنترنت» ("requires an internet
  connection") until the ad has loaded (a few seconds after launch or after a previous watch), then
  enables by itself. Before PR #5 it stayed disabled until the screen rebuilt for another reason,
  and a failed load was never retried.

### Consent and ad loading — how it works (PR #5)

- **Order at launch:** read `canRequestAds()` (consent from a previous session lets ads start at
  once) → `gather()` (consent info update, then the form if required; it completes only after the
  form closes) → read again. `MobileAds.instance.initialize()` and every ad load happen **only**
  while `canRequestAds()` is true. Never add a load path that skips `_canLoad`.
- **Settings → «الخصوصية»:** «خيارات خصوصية الإعلانات» appears only when UMP says privacy options
  are required, and opens `showPrivacyOptionsForm`; the consent state is re-applied as soon as it
  closes. «سياسة الخصوصية» opens `AppConfig.privacyPolicyUrl` through `LinkOpener` (url_launcher).
- **Retries:** `RetryingAdLoader` retries a failed load after `AppConfig.adRetryDelaysSeconds`
  (15 s rising to a 5-minute cap), and at once when the app returns to the foreground
  (`AppLifecycleHooks`, wrapped around every screen in `MaterialApp.builder`). The service calls
  `onChanged` whenever an ad becomes ready or is used, so `AdsProvider` notifies the UI. A consent
  update that **failed** (offline on first launch) is retried on resume or when an ad is
  requested; one that succeeded but still disallows ads is not, so the form doesn't chase the
  player on every return to the app.
- **Testing the EEA form:** clear the app's data, then run
  `flutter run --dart-define=UMP_DEBUG_EEA=true` on the emulator. The flag is ignored in release
  builds; a real phone would also need its hashed test-device ID, which isn't wired up.
- `AdMobAdService` has test seams (`consent`, `supportedPlatform`, `initializeSdk`, `loadRewarded`,
  `loadInterstitial`). Production passes only `consent`.
- `AdsProvider` is created with `lazy: false` in `app.dart`, so all of this starts at launch — see
  the lazy-provider trap in "Known traps".
- ⚠️ **The EEA form needs a published European regulations message in AdMob** → Privacy & messaging.
  The owner published one on 13 September 2026. Without it the consent update fails with
  `Publisher misconfiguration`, and the gate falls back to whatever `canRequestAds()` answers.

> ✅ **Production IDs set (8 September 2026)** — the app ID is in `AndroidManifest.xml`, the
> rewarded, interstitial and banner unit IDs are in
> [`admob_ad_service.dart`](../lib/data/services/admob_ad_service.dart), and test-vs-production is
> chosen in `injector.dart` via `useTestIds: !kReleaseMode` (debug builds stay on test IDs to
> protect the account). **Never tap your own live ads — the account gets suspended.**
> `com.google.android.gms.permission.AD_ID` is merged into the manifest automatically from the ads
> SDK (verified with `aapt2 dump permissions` on v1.0.3 — it isn't in the source manifest). The
> merge also brings `FOREGROUND_SERVICE` along with WorkManager's `SystemForegroundService`, but
> **no service declares a `foregroundServiceType`** and there are no type-specific
> `FOREGROUND_SERVICE_*` permissions — so Play shouldn't ask for the foreground-service form. If it
> does: the source is WorkManager, pulled in by AdMob, and the app itself never starts a foreground
> service.

> ⚠️ **`google_mobile_ads` must stay on version 9 or later.** Version 6 uses
> `configurations.all`, which Gradle 9 removed, so the build fails with
> `Could not get unknown property 'all'`.

### In-app purchases — how they work (v1.0.8)

Three products, ids exactly as in Play Console: `hearts_small` (5 hearts), `hearts_large`
(20 hearts) and `remove_ads`. **Never rename an id** — old purchases stop restoring.

- **The rows appear only when Play returns the products.** `PlayBillingService.isAvailable` is
  store-reachable *and* products found, so the shop keeps its «قريباً» row while the payments
  profile is under verification or the products don't exist yet. That is what let this ship before
  the account was ready to sell.
- **Delivery goes through `PurchasesProvider`, not the shop screen.** A purchase can complete while
  the app is closed (a pending bank payment, or a buy on another device) and arrives at the next
  launch with no screen open.
- **Bought hearts go above the 5-heart cap** (`grantPurchasedHearts`). `RegenerateHearts` returns
  early when hearts ≥ max, so the extra hearts survive; free regen still stops at 5. Paying at
  4 hearts and getting 1 would read as a rip-off.
- **`remove_ads` stops the banner and interstitials, never the rewarded ad** — that one is optional
  and is how players get hearts and coins (see ECONOMY.md).
- **The entitlement is not in the backup code.** `entitlements_v1_ads_removed` is deliberately
  missing from `_decoders` in `BackupRepositoryImpl`: a backup code is shareable, so carrying the
  purchase in it would make Remove-ads free for anyone who copies it. Play is the source of truth
  (`restorePurchases()` at every launch) and the local key is only an offline cache.
- **Consumables are not restored.** Only non-consumables are re-delivered on restore, or hearts
  would be granted again at every launch.
- **Every purchase is completed** (`completePurchase`), which acknowledges it. Google refunds
  anything unacknowledged after 3 days. `buyConsumable` also consumes, so a pack can be bought again.
- A revoked or refunded purchase is **not** revoked locally on its own: wrongly cutting off a paying
  player is worse than the rare refund keeping its benefit.

### Coins and tasks — how they work

Coins are an intermediate currency: actions grant coins, and coins buy hearts or hints. That lets
many different actions be rewarded with one currency, and lets prices stay fixed later.

| Daily task | Target | Reward |
|---|---|---|
| Correct answers | 10 | 20 🪙 |
| Complete the daily challenge | 1 | 40 🪙 |
| Pass a level | 1 | 30 🪙 |
| Chest | Claim all | 40 🪙 |
| **Daily total** | | **130 🪙** |

| Shop | Price |
|---|---|
| Refill hearts to the cap | 200 🪙 |
| Pack of 3 hints | 200 🪙 |
| Remove ads | Shows «قريباً» ("Soon") — in-app purchases aren't built |

> ⚖️ **Balance rule:** full daily income stays **below** one purchase (130 vs. 200 ⇒ about 1.5 days
> per purchase). If they were equal, buying would happen daily, hearts would lose their scarcity,
> and the rewarded ad would lose its point. Guarded by `test/economy_balance_test.dart`.
> **70 coins per ad** = 200 − 130: a player who finished their tasks needs exactly one ad to buy.
> The owner discussed lowering it to 50 and decided to keep 70.

- **We sell "refill hearts", not a fixed count**, because the cap is five — selling twenty hearts
  would be meaningless.
- Purchased hints (`bonusHints`) **don't reset daily**, unlike the free ones; free hints are
  consumed first, then purchased.
- Task progress resets daily inside `RegenerateHearts`; coins and purchased hints persist.
- The correct-answers task counts in **every mode**; the level task counts only on a **pass**.
- The shop opens by tapping the **coin badge on the home screen** (not from the tasks screen).

### Economy — how it works

| Item | Value |
|---|---|
| Hearts | 5, **level mode only**: one per attempt, charged at the start by `NoHeartsDialog.startLevel` and refunded on a pass, so failing, quitting or closing the app costs one |
| Regen | One heart every 30 minutes, computed on read, not by a timer |
| Daily challenge | Grants one free heart once per daily (`dailyHeartDayKey` in the economy); «كسبت قلباً!» only when a heart was added. The result screen offers a one-tap reminder card and «العب مستوى» |
| Rewarded ad | +1 heart, max 4 per day (`heartsPerRewardedAdWatch`) |
| Hints | 3 per day: remove two answers · skip · extra time (once per question; the speed bonus stays capped at 50) |

- **The daily challenge and quick play are completely free** — no hearts, no hints, no ads. That
  protects the streak from being broken by monetization.
- The balance is computed from `hearts + lastRegenAtIso`, and the remainder is kept, so waiting
  minutes aren't lost between reads.
- A device clock going backward resets the reference instead of producing a negative balance.
- Stored under `economy_v1`.
- Hearts are checked only **before starting** a level; if they run out mid-round, the round finishes.
- **Keeping the screen live (PR #6):** `HeartsTicker` (inside `HeartsBar` and `NoHeartsDialog`) calls
  `EconomyProvider.refresh()` every `AppConfig.heartsRefreshSeconds` while hearts are below max, and
  `AppLifecycleHooks` calls it on resume. `refresh()` notifies when the displayed minute changes, not
  only when something is saved. Granting or losing a heart recomputes the countdown from
  `lastRegenAtIso` — it used to jump back to 30 minutes after every granted heart.
- `EconomyProvider` takes a `clock` for tests; production uses `DateTime.now`.
- **No-hearts dialog:** «العب تحدي اليوم» (hidden, with different body text, once the daily is done) ·
  the rewarded ad · «ملء القلوب · 200» (disabled with «عملاتك لا تكفي») · «حسناً» to close. It
  closes itself as soon as a heart exists (regenerated, earned or bought). Every close goes through
  `_close`, which pops only while the dialog is still the top route — an unguarded `pop` after an
  `await` would close the screen underneath.

### Arabic counts — how to write a number with a noun (PR #6)

- **Never write `'$n يوم'`, `'$n نقطة'` or similar.** Use `ArabicCount.format(n, ArabicNoun.day)`
  ⇒ «يوم واحد» · «يومان» · «5 أيام» · «11 يوماً» · «100 يوم».
- After a verb or in an idafa, pass `object: true` for the accusative dual: «ستفقد نجمتين».
- When the number is shown separately (the big score with «نقطة» under it), use `ArabicCount.nounFor`.
- Nouns available: day · star · point · level · question · correctAnswer. Add new ones to
  `ArabicNoun` with all six forms; `arabic_count_test` checks their forms differ.
- Strings that embed a count are functions in `AppStrings` taking the already-formatted count
  (`taskAnswers`, `resetProgressLoss`, `streakKeptFor`, `reminderBody`, `reminderBodyStreak`).

### Feedback, reports, review prompt and error log — how they work (PR #8)

- **Error log:** `installErrorHandlers` (called first thing in `main.dart`) wraps
  `FlutterError.onError` and `PlatformDispatcher.instance.onError`; both keep the previous handler.
  With no previous handler the platform one returns `false`, so the engine still prints the error to
  logcat — returning `true` would hide it (and doesn't change whether the app keeps running).
  `PrefsErrorLog` keeps the last `AppConfig.errorLogMaxEntries` (20) errors under `error_log_v1` —
  message cut to 300 characters, first 4 stack lines — with writes chained so two errors in one frame
  don't overwrite each other. It never throws. **Not part of the backup**, deliberately. Caught errors
  that should still be logged go through `FlutterError.reportError` (see `QuizProvider._start`, which
  now shows `AppStrings.loadQuestionsFailed` instead of the raw exception).
- **Nothing is sent automatically.** «أرسل ملاحظاتك» (Settings → About) and «أبلغ عن خطأ» open a ready
  email in the player's own mail app to `AppConfig.contactEmail`, built by `BuildFeedbackEmail`
  (version + the last `AppConfig.feedbackEmailErrors` errors) and `BuildQuestionReport` (reason ·
  question id · category · level · text · options as shown with the approved one marked ✓ · version).
  `EmailDraft.toMailtoUri` encodes spaces as `%20` — `Uri(queryParameters:)` would put `+`, which some
  mail apps show literally. No mail app ⇒ a SnackBar with the address.
- «أبلغ عن خطأ» sits in the quiz feedback panel (only after the answer is revealed, when the timer is
  stopped) and, as an icon with a tooltip, in every result-review row. The reasons sheet stays open
  until the mail app has been asked to open — its barrier keeps «التالي» from starting the next
  question's timer behind the mail app — and a second tap doesn't open a second email. If the player
  dismisses the sheet meanwhile, the late result pops nothing.
- **Review prompt:** `ShouldAskForReview` — never after an interstitial; at most every
  `AppConfig.reviewPromptMinDaysBetween` (30) days; a daily with streak ≥ `reviewPromptMinStreak` (3)
  or a 3-star level, nothing else. The result screen checks it last, after stats and stars are saved.
  Play's sheet must never open over a new round (the quiz timer pauses in the background, but the round would
  still start under the sheet):
  no prompt once the result screen is no longer the current route, and «أعد المستوى» · «المستوى
  التالي» · «العب مرة أخرى» wait for a request already in progress (`_pendingReview`).
  `InAppReviewPrompter` records the time **before** calling Play, so a failed call isn't retried every
  round; it's stored under `review_prompt_v1`, not in the backup. ⚠️ Play only shows the dialog to
  apps installed from Play — a sideloaded APK shows nothing, so check it from the closed test.
- **Share text** ends with `BuildShareText.shareLink`: `AppConfig.playStoreUrl` +
  `&referrer=` + the encoded `AppConfig.shareReferrer`. The link only works for non-testers once the
  app is in production.
- **Version:** `AppInfo` (`PackageAppInfo`, package_info_plus) gives «1.0.4 (5)» for Settings and the
  emails — no more hand-edited version string.
- `android:appCategory="game"` keeps the portrait lock on large screens in Android 16. The manifest
  also declares a `mailto` `SENDTO` query for url_launcher on Android 11+.

### Color themes — how they work (v1.0.5)

- `AppPalette` holds each theme's colors; `AppPalette.all` is green (default) · blue · purple · red. All four keep the
  stadium design: the pitch and card colors change, gold, chalk and correct stay (red uses a lighter «wrong»).
- `AppColors.x` are getters over `AppColors.current`. `app.dart` selects `SettingsProvider.themeId`, calls
  `AppColors.use` before building `MaterialApp`, and `PaletteScope` marks every element for rebuild after a switch,
  so open screens change color without losing navigation.
- The choice is `AppSettings.themeId` in `app_settings_v1` (old settings read as green) and travels in backups.
- `theme_test` checks that no theme is less readable than the original green.

### Backup import — how it works (PR #7)

- `BackupRepositoryImpl.import` checks **every** value with the datasource's own `decode` (the same
  parsing the app uses to read it) before writing any of them. One bad value, a non-string value, an
  unreadable day key, or a code with no known key rejects the whole code and writes nothing.
- The four keys and their parsers live in one map (`_decoders`); a new stored key must be added there
  to be exported, imported and validated.
- `RestoreBackup` (presentation) runs the import, then reloads settings **first** and then stats,
  progress and economy. Order matters: reloading stats notifies `AppLifecycleHooks`, which reschedules
  the reminder and must see the imported settings. `SettingsProvider.init` cancels reminders whenever
  the loaded settings have them off, so importing a code with reminders off clears the old ones.
  The success message is «تم الاستيراد» — a restart is no longer needed.
- Keys missing from a code are left as they are on the device (not deleted).

### Layout on short and tall screens (PR #7)

- **Level grid:** the tile ratio is computed with `LayoutBuilder` so all ten levels fit above the
  footer; a tile never gets shorter than 64 dp, and below that the grid scrolls.
- **Quiz screen:** below `AppConfig.compactLayoutMaxHeight` (700 dp) the question card and options
  use smaller sizes. Free space goes above the options (`Spacer`s around the question card), so on
  tall screens the options sit right above the hints bar. After an answer, the feedback panel
  scrolls itself into view 240 ms later, once the options' border animation has finished; a panel
  taller than the viewport aligns its top (verdict and correct answer) instead of its bottom. The
  scroll view is keyed by the question index, so each question starts at the top — otherwise the
  panel's scroll offset carried into the next question. The card's two tags `Wrap` for large fonts, so the card sets `width: double.infinity` — the old
  tags `Row` was what stretched it, and without it a short question's card shrank narrower than the
  options (seen on the emulator).
- Skip is shown as «تخطّيت هذا السؤال» in gold with a skip icon, on the quiz screen and in the result
  review — not as «انتهى الوقت!» or a red wrong answer. Scoring is unchanged (decision 3 in PLAN.md).

### Daily reminder — important traps

- **`tz.local` defaults to UTC.** `initializeTimeZones()` alone isn't enough; you need
  `flutter_timezone` to read the zone name and then `tz.setLocalLocation`. Without it, an 8 pm
  reminder fires at 8 pm GMT, not the user's time.
- **`flutter_local_notifications` requires core library desugaring** —
  `isCoreLibraryDesugaringEnabled = true` + the `desugar_jdk_libs` dependency, or the build fails.
- **`flutter_timezone` conflicts with Gradle 9** (Java 11 vs. Kotlin 1.8). The fix is in
  `android/build.gradle.kts`: a `subprojects` block that aligns the Kotlin target for that package
  alone.
- Scheduling is **inexact** on purpose (`inexactAllowWhileIdle`) to avoid the heavy
  `SCHEDULE_EXACT_ALARM` permission on Android 12+.
- `SettingsProvider.init()` re-checks the permission at every launch and turns the toggle off (and
  cancels the reminders) if the permission was revoked in system settings while the app was closed.
- 🐛 **The reminder never fired up to v1.0.3 (fixed in PR #6):** `flutter_local_notifications` needs
  `ScheduledNotificationReceiver` and `ScheduledNotificationBootReceiver` declared in
  `AndroidManifest.xml`. Without them `zonedSchedule` succeeds silently and nothing is ever shown.
  `android_config_test` guards both.
- **`MY_PACKAGE_REPLACED` is deliberately not declared.** The plugin's example manifest has it, but on
  an update it would re-arm v1.0.3's cached repeating reminder before v1.0.4 is ever opened. Alarms
  survive an update anyway, and the app reschedules at launch. Remaining edge: a tester who had the
  reminder on in v1.0.3 and **reboots** before first opening v1.0.4 gets the old reminder (old text,
  launcher icon) daily until they open the app, which cancels id 1001.
- **One notification per day, not a repeating one (PR #6):** `PlanReminders` plans one-shot reminders
  for the next `AppConfig.reminderDaysAhead` days (7), skipping today once the daily is done or once
  today's time has passed, and naming the streak only in the first (when it's still alive).
  `SettingsProvider` reschedules at launch, when the time or toggle changes, and via
  `syncReminder(UserStats)` whenever `StatsProvider` changes or the app resumes
  (`AppLifecycleHooks`); "today" is computed at scheduling time, not at sync time. A player who
  stays away a week stops getting reminders. Ids are 1001–1007; 1001 is also v1.0.3's repeating
  reminder, so rescheduling cancels it.
- 🧪 **Don't mix a one-shot with a repeating reminder.** Tried on 13 September 2026: a one-shot for
  tomorrow plus a `matchDateTimeComponents: time` reminder dated the day after. On Android the
  plugin **ignores the repeating reminder's date** and arms it for the next occurrence of the time,
  so both fired on the same day (seen on the emulator) — and a repeating reminder can't skip a day
  the daily is done.
- ⚠️ **Accepted risk:** before Android 12, an inexact alarm may be delayed by up to 75% of the time
  left until it, with no one-hour cap. Reminders several days out (a player who hasn't opened the app
  since) may arrive hours late. Raising `reminderDaysAhead` makes it worse.
- **Status-bar icon:** `res/drawable-*/ic_stat_notification.png`, a white football on transparent
  (drawn from the Material `sports_soccer` glyph). The launcher icon shows as a blank shape in the
  status bar. `res/raw/keep.xml` keeps it if resource shrinking is turned on later.
- The economy design is documented in [docs/ECONOMY.md](ECONOMY.md).

### Daily challenge — once per day

- `StatsProvider.isDailyDone` (from `lastDailyDayKey`) is the source of truth; the home card
  disables its play button on it and shows a countdown to tomorrow's challenge.
- 🐛 **Fixed (8 September 2026):** the result screen showed a "Play again" button after the daily
  challenge, which actually started a random **quick play** round — so players thought they were
  replaying the challenge. Now `_showReplayButton => !_result.isDaily` hides it after the daily
  challenge; "Replay level" remains in level mode and "Play again" in quick play.
  `daily_guard_test` covers `isDailyDone`, and `score_screen_buttons_test` covers the button's
  visibility (PR #7).
- Leaving the challenge before finishing doesn't mark it complete (deliberate).
- **Which questions (15 September 2026):** 7 questions split by the bank's difficulty shares (3 easy · 4 medium · 3
  hard levels) → 2 easy, 3 medium, 2 hard, played easiest first. Each difficulty pool is shuffled once per cycle, and
  each day takes its next slice, so no question repeats inside a cycle (133 days with the current bank: 400 medium ÷ 3).
  Seeds come from the UTC day number, so everyone gets the same set in both languages
  (`getDailyQuestions` in `quiz_repository_impl.dart`).

### Level system — how it works

| Item | Value |
|---|---|
| Passing a level | 7 of 10 (`AppConfig.passRatio`) |
| One star | 7–8 correct |
| Two stars | 9 correct |
| Three stars | 10 correct |
| Unlocking the next | By passing the current one (one star or more) |

- Stars **never decrease** when replaying a level with a worse score.
- `highestUnlockedLevel` relies on the **first unpassed level**, not a count of passed ones, so a
  gap in saved data can't unlock a whole run of levels.
- Stored under `level_progress_v1`, keyed by **`slug`**, not the Arabic name:
  ```json
  { "version": 1, "categories": { "world_cup": [3,3,2,0,0,0,0,0,0,0] } }
  ```
- `AppConfig.levelsPerCategory` must match `categories.json` — guarded by a test.
- The levels screen is built via `onGenerateRoute` because it needs a `Category` argument, unlike
  the other screens in the `routes` table.
- The levels screen auto-selects the first unpassed level when opened.

---

## Design decisions already made — don't reopen without a reason

| Decision | Why |
|---|---|
| Levels unlock **progressively** | Gives each category's 100 questions a sense of progression |
| Difficulty **rises** with the level number | What players expect from a level system |
| Keep all three modes (levels · quick · daily) | Each serves a different need |
| Hearts in **level mode only** | Protects the daily streak from being broken by monetization |
| One file per category, not one file | A 10,000-line file can't be reviewed |
| Difficulty is **derived**, not stored | It can never contradict the level |
| Level option order is seeded by the question ID | The answer position stays stable across replays of the same level |
| Stars never decrease | Replaying to improve shouldn't punish the player |
| Unlocking relies on the first incomplete level | A gap in the data can't unlock a whole run |
| Storage is keyed by `slug` | Arabic names can change; the slug can't |
| **Local storage only — for now** | Owner's decision (4 August 2026): start local, move to Firebase/a server **if the app proves successful**. Don't build anything that makes that move harder. |
| Package namespace `com.oasisforge` | The owner's store name, reused for all their apps, and it doesn't reveal their personal name |
| Arabic store name «تحدي كرة القدم» | The audience is Arabic and searches in Arabic; "Koora Trivia" gets added as an English listing if one is ever opened |
| No offline promise and no fixed counts in any text | Text stays true as content is added, and ads need a connection anyway |
| 70 coins per ad | Closes the 200−130 gap with one ad; confirmed by the owner after discussing 50 |
| Interstitials on before launch (17 Sep 2026) | Owner's call: closed testers meet them first, so their effect is known before the public launch |
| R8 off in release | Turned off to fix the launch crash; re-enabling needs keep rules and a release-build test |

---
