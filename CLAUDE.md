# CLAUDE.md — Project context and handoff notes

> Loaded at the start of every session and into every subagent, so it stays short: rules, current
> status, traps and pointers. Details live in `docs/` — read a file only when the task touches it.
> **Update the status and next steps here, and `docs/PLAN.md`, whenever work is completed.**
> Last updated: **18 September 2026**.

## Working conventions — agreed with the owner on 14 September 2026
Tokens cost the owner real money.
- **Micro tasks:** one small, clearly scoped change per branch and PR.
- **No workflows or subagents unless the owner asks.** Review your own diff; for a risky change,
  suggest one Sonnet reviewer and wait for a yes.
- **Testing:** `flutter analyze` and the related tests while working; the full suite once before the
  PR; no mutation runs unless asked.
- **Release-build check on the emulator once per version**, before shipping — not per PR, unless the
  change can only break in a release build.
- **Docs:** one or two lines per change here and in `docs/PLAN.md`.
- **Output:** one status line per step and a short summary. Never paste full command output or file
  contents — tail/grep for the relevant lines.

---

## 🚦 Current status — start here

**Stage:** closed testing on Google Play since 9 September 2026. **Not published publicly yet.**

**On Play:** `v1.0.3+4` live on the closed track. `v1.0.4+5` (`releases/v1.0.4_build5_2026-09-14/`, PRs #2, #3
and #5–#14) was uploaded by the owner on 14 September 2026 to internal and closed testing. `v1.0.5+6`
(`releases/v1.0.5_build6_2026-09-14/`, PRs #16–#29) was archived but never uploaded (skipped). `v1.0.6+7`
(`releases/v1.0.6_build7_2026-09-14/`, PRs #31–#42: redesign, English, in-app updates) was uploaded by the owner on
14 September 2026 to internal and closed testing, with the English store listing and both screenshot sets in the new
design; it is in Google's review and contains everything in v1.0.5. The "Some languages have errors" warning is gone. `v1.0.7+8`
(`releases/v1.0.7_build8_2026-09-16/`, PRs #51–#52: daily challenge mix and no-repeat cycle, «21 / 10» task count,
question bank clean-up) was uploaded by the owner on 16 September 2026 to closed testing (no full test run or emulator
check before it, owner's call). `v1.0.8+9` (`releases/v1.0.8_build9_2026-09-18/`, PRs #55–#58: banner and interstitial
ads, Play Billing shop, full-width banner and «إزالة الإعلانات» link, support email) was uploaded by the owner on
18 September 2026 to closed testing and is in Google's review (release-checked on the emulator first).

**Privacy policy:** published from this repo — `docs/privacy_policy.html` is the only copy, and merging a change to it
publishes https://oasis-forge.github.io/koora-trivia/privacy/ (`.github/workflows/privacy-pages.yml`). The old
`/koora-trivia-privacy/` address forwards there from the root site repo. Details in RELEASE.md.

### Next steps, in order
The prioritised plan is **[docs/PLAN.md](docs/PLAN.md)** — the source of truth for what's open.
1. **Testers (critical path):** 5 of 12 opted in; production needs 12 opted in for 14 consecutive days.
2. **Content:** section A of v1.0.5 is done. Still open: a person reviewing levels 7–10 (PLAN.md).
3. **After Google approves v1.0.7 (owner):** check the pre-launch report (crashes, and its screenshots in both languages).
4. **Purchases (owner):** the three in-app products exist and are active (18 September 2026). Add licence testers, wait
   a few hours, then test coins, the bundle and a restore from the Play install (steps in RELEASE.md).

### Decisions waiting on the owner
- **② Name and address on the store page** (personal account) vs. an organization account. Undecided.
- **Decided 14 September 2026:** themes are color variations of the current design only · a bare «لا شيء»
  option is not acceptable · the language follows the phone, and a Settings choice overrides it · ① one heart
  per failed attempt, not per wrong answer (built in v1.0.5) · no answer recap on the result screen, in any mode · ③ English is added now: Arabic and English only, the bank
  translated with the same IDs, `arab_football` kept and translated, not waiting for the levels 7–10 review
  ([docs/I18N_PLAN.md](docs/I18N_PLAN.md)) · arrows follow Android's right-to-left convention: Back is `arrow_back`
  (points right in Arabic), Next is `arrow_forward`; media icons (play, skip) don't flip.

### Identity and secrets — never break these
- **Never write the owner's personal name, personal account names, or personal email into tracked
  files.** The repo (https://github.com/Oasis-Forge/koora-trivia) is **public**.
- Store name **Oasis Forge** · package `com.oasisforge.kooratrivia` (**final**) · public support contact
  `oasisforge.support@gmail.com` (since 18 September 2026; was `thepromptkitchen@gmail.com`) · commit
  identity is local to the repo (`The Prompt Kitchen`).
- The upload key password lives only in `android/key.properties`. **Never copy it into any other file.**
- **Never tap your own live ads** — the AdMob account gets suspended. Emulators get test ads.
- **Pushing:** PowerShell 5.1 drops `""` arguments, so Git Credential Manager (the owner's personal
  account) answers. Push through Git Bash with
  `-c credential.helper= -c "credential.helper=!'C:/Program Files/GitHub CLI/gh.exe' auth git-credential"`,
  then check `gh api repos/Oasis-Forge/koora-trivia/activity --jq ".[0].actor.login"` is
  `thepromptkitchen-alt`.

---

## What the project is
An Arabic (RTL) and English Flutter football trivia app for Android: 1000 questions across ten categories,
levels · quick play · daily challenge, a local day streak, hearts/coins economy, rewarded ads.
Storage is local only for now (owner's decision). **User-facing text must not promise offline play nor
state a fixed number of questions or categories.**

## Environment
Flutter is at `C:\src\flutter` and **not on PATH**:

```bash
$env:Path = "C:\src\flutter\bin;$env:Path"; flutter analyze
```

```bash
$env:Path = "C:\src\flutter\bin;$env:Path"; flutter test
```

- `adb`: `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe` · `gh`: `C:\Program Files\GitHub CLI\` —
  neither on PATH. Emulator: `Medium_Phone` (1080×2400, Play Store image).
- The only JDK is **Java 25 — never downgrade Gradle** (9.1.0 / AGP 9.0.1 / Kotlin 2.3.20).
  `* What went wrong: 25.0.2` means a version mismatch.
- **R8 is off in release** (it crashed launch through WorkManager). Re-enabling needs keep rules and a
  release-build test. Some bugs only show in release builds.
- Build, shipping and emulator details: [docs/RELEASE.md](docs/RELEASE.md).

## Architecture
`lib/core` (constants · theme · utils · DI) · `lib/domain` (entities · contracts · use cases — **never
imports Flutter or third-party packages**) · `lib/data` (models · datasources · implementations) ·
`lib/presentation` (providers · screens · widgets). Direction: `presentation → domain ← data`.

### Known traps
- `Category` clashes with `foundation.Category` → `import 'package:flutter/foundation.dart' hide Category`.
- **Never return `Map<String, XModel>` where `Map<String, X>` is promised** — its runtime type rejects
  entities (broke star saving). Use `Map<String, X>.from(...)` at the repository boundary.
- Errors inside async `addPostFrameCallback` callbacks go unnoticed on screen — test that logic through
  the provider. Since PR #8 the local error log records them. End-of-round saving lives in `RecordRound`, not
  `ScoreScreen`.
- `ChangeNotifierProvider` is **lazy** — anything that must start at launch needs `lazy: false`.
- **Providers write all their in-memory data on the next save** — reload them after changing
  SharedPreferences behind their back (see `RestoreBackup`).
- `map['x'] as int?` throws `TypeError`, not `FormatException` — datasources' static `decode` converts it.
- An unguarded `Navigator.pop` after an `await` can close the screen underneath — check the route is
  still current.
- **The quiz timer pauses while the app is in the background** and the question is hidden (`QuizScreen`
  observes the lifecycle). `QuizProvider.selectAnswer` returns `false` when nothing was recorded.
- Question assets don't refresh on hot reload — full restart. Every language folder under `assets/data` must be listed in
  `pubspec.yaml` (Flutter doesn't bundle subfolders; `question_datasource_language_test` fails otherwise).

### Rules that are easy to break — details in [docs/HOW_IT_WORKS.md](docs/HOW_IT_WORKS.md)
- **Every button that starts a level goes through `NoHeartsDialog.startLevel`**: it checks hearts and charges
  the attempt's heart at the start; `ScoreScreen` refunds it on a pass. Quick play and the daily challenge stay
  free (no hearts, hints or ads).
- **Ads:** no SDK init or ad load unless `canRequestAds()`; rewards only on `RewardResult.earned`;
  never an interstitial after the daily; `google_mobile_ads` must stay ≥ 9. The bottom banner is
  `BannerSlot` in `Scaffold.bottomNavigationBar`, full width (standard adaptive, not the 128 dp
  "large") — it reserves its height before the ad arrives, so nothing above it moves under the
  player's finger (AdMob suspends accounts over invalid taps). No «إزالة الإعلانات» link on the quiz.
- **Arabic counts:** never `'$n يوم'` — use `ArabicCount.format(n, ArabicNoun.day)`.
- **A new stored key** must be added to `_decoders` in `BackupRepositoryImpl` — except
  `entitlements_v1_ads_removed`, kept out on purpose: a backup code is shareable, so a purchase
  carried in it would be free for anyone who copies it.
- **Purchases:** product ids (`coins_small` · `remove_ads` · `remove_ads_bundle`) must match Play Console
  and never change · every purchase is completed so it is acknowledged within Google's 3 days · **an
  unacknowledged purchase is new, whatever its status** (the plugin calls everything a restore returns
  "restored") · coin packs from a restore are consumed by the app · the bundle's coins come once ·
  money buys coins, never hearts — hearts never go above 5.
- **Reminders:** one-shot per day (ids 1001–1007); the manifest receivers are required;
  `MY_PACKAGE_REPLACED` stays undeclared; never mix one-shot and repeating reminders.
- **Economy balance:** full daily income (130 🪙) stays below the cheapest purchase (200 🪙).
- **Button icons sit on the left of their text** (after it in RTL) through `iconAlignment` in `AppTheme` —
  owner's request, 14 September 2026. Don't override it per button.
- **Player text lives only in `AppStrings`** (`localization_groundwork_test` fails otherwise): Arabic in `AppText`
  (`app_strings.dart`), English in `EnglishText` (`app_strings_en.dart`; a missing string won't compile). Never keep text in a
  `static const`/`static final` field — it freezes the first language; use a getter. Layout sides use
  `EdgeInsetsDirectional` / `AlignmentDirectional` / `PositionedDirectional`. The locale comes only from
  `AppSettings.languageCode` (`null` = phone language, the default for new players; `AppLanguageScope` in `MaterialApp.builder` applies the
  resolved language to `AppStrings`) — never hard-code one or wrap
  the app in a `Directionality`.
- **Colors:** read `AppColors.x` (getters over the current `AppPalette`) at build time — never inside `const`, never
  cached in a field or default parameter. A new color is a new `AppPalette` field in all four palettes.
- **Screens use the shared design widgets** — `Surface` / `StatusPill` (`surface.dart`), `GoldButton` ·
  `SolidButton` · `OutlineButton` (`koora_buttons.dart`), `SectionHeading` · `RowsCard` · `KooraRow` ·
  `KooraProgress` (`rows_card.dart`). Don't hand-roll card or button styling (v1.0.6 redesign).
- Tunable numbers go in `app_config.dart`; player-facing text in `app_strings.dart`.
- **Every `IconButton` has a `tooltip`** (screen readers; `hints_and_a11y_test` fails otherwise).
- **In-app updates** (`PlayAppUpdater`, checked at launch and resume): flexible by default; only a release with Play
  priority ≥ `AppConfig.forceUpdatePriority` forces the full-screen update. Works only for Play installs.

## Question bank
`assets/data/questions/<slug>.json`, 10 levels × 10 questions per category. Before editing any
question read [docs/QUESTION_BANK.md](docs/QUESTION_BANK.md) (categories, id ranges, overlap rules).
Mandatory: four distinct options · no «كل ما سبق», «لا يوجد», «كلاهما», «كلتاهما», «لا شيء», «لا أحد» or «لم يحدث» · balanced
`answerIndex` (`dart run tool/rebalance_answers.dart`) · no duplicates across categories · evergreen
facts only · no invisible direction characters · `level` matches the id · no «حالياً», «حتى الآن» or "currently"
without a year, and changeable counts or records anchored to one · no explanation naming a later answer in its level ·
the correct option never stands out by length or by alone repeating a word from the question.
Run `question_bank_test`, `english_bank_test` and `question_content_test` after any change. **After every major
tournament or Champions League final, re-check record, count and "first/only/most" questions in both languages.**

## Tests
Shared fakes are in `test/fakes/`. `small_screen_layout_test` renders every screen at 320 and 360 dp in Arabic and
English — add new screens there. Per-file coverage, the current count and what isn't covered:
[docs/TESTS.md](docs/TESTS.md).

## Docs map

| File | Read it when |
|---|---|
| [docs/PLAN.md](docs/PLAN.md) | Choosing or finishing work — the prioritised plan |
| [docs/RELEASE.md](docs/RELEASE.md) | Building, shipping, emulator testing, Play Console status, store assets, privacy site |
| [docs/HOW_IT_WORKS.md](docs/HOW_IT_WORKS.md) | Touching ads, consent, economy, coins, reminders, daily challenge, levels, backup, layout, feedback/error log — plus design decisions not to reopen |
| [docs/QUESTION_BANK.md](docs/QUESTION_BANK.md) | Editing questions |
| [docs/TESTS.md](docs/TESTS.md) | Adding tests or checking coverage |
| [docs/PRE_PUBLISH.md](docs/PRE_PUBLISH.md) | Publishing checklist and verification log |
| [docs/I18N_PLAN.md](docs/I18N_PLAN.md) | Anything about a second language |
| [docs/ECONOMY.md](docs/ECONOMY.md) | Economy design (still in Arabic) |
| `docs/STORE_LISTING.md` · `docs/DATA_SAFETY_EN.md` · `docs/privacy_policy.html` | Store text · Data safety answers · privacy policy source |
| `design-system/` · `.design-sync/NOTES.md` | Exporting the app's design to Claude Design, or re-syncing it |

## Expected way of working
- **One branch off the latest `origin/main` per task, then a PR:** `git fetch origin`,
  `git switch --no-track -c <feature|fix|docs>/<short-name> origin/main`, commit, push, `gh pr create`.
  Never commit to `main`, never stack branches, never leave a superseded branch. **Merging is the
  owner's call.**
- **English** with the owner and in CLAUDE.md and `docs/`. **Arabic** only for what players read (app
  strings, question bank, store text, release notes). Code comments are Arabic and explain *why*.
- When the owner reports a bug from their phone, reproduce it before fixing.
- Before saying a fix has reached users, it must have passed a release-build check on the emulator.
