# CLAUDE.md — Project context and handoff notes

> **Why this file exists:** it's loaded automatically at the start of every Claude Code
> session, so a new conversation can pick up without re-explaining anything.
>
> **⚠️ Update this file whenever work is completed.** Move items from "Remaining" to
> "Done", and record any new design decision or trap you discover.
> Last updated: **13 September 2026**.

## Working conventions
Keep output minimal — this burns real tokens:

Don't dump full command output (flutter test, flutter analyze,flutter build, git log, etc.) into responses; run with tail/grep
for the relevant lines, or just state pass/fail and the error if any.
Don't paste full file contents back after a Read/Edit/Write unless the
user needs to review them — the tool result already confirms the
change.
Summarize instead of narrating every tool call; report outcomes, not
process.

---

## 🚦 Current status — start here

**Stage:** closed testing on Google Play since 9 September 2026. **Not published publicly yet.**

**Latest build:** `v1.0.3+4` in `releases/v1.0.3_build4_2026-09-08/` — **live on the closed testing
track** (`app-release.aab` is what was uploaded, `app-release.apk` installs directly on a device).
It contains every fix: launch crash (R8) · star saving and level unlocks · replay button
hidden after the daily challenge · rewarded-ad reward granted. Verified on the emulator
with a release build. No app code has changed since that build (checked 13 September 2026).

**Git:** PRs #1–#3 (English docs, multilingual plan, branch rule, handoff notes) were merged into
`main` on 13 September 2026. Their branch `docs/english-docs-and-i18n-plan` still exists on GitHub
and should go — recreating the repo (decision ④) removes it anyway. Start any new work from the
latest `main`, following the branch rule in "Expected way of working".

### Publishing identity

| Item | Value |
|---|---|
| Store / developer name | **Oasis Forge** |
| Package name | `com.oasisforge.kooratrivia` — **final, can never change after the first publish** |
| App name on the store | «تحدي كرة القدم» (Arabic is the default listing language) |
| Public contact email | `thepromptkitchen@gmail.com` (same as the privacy policy) |
| AdMob | app "Koora Trivia" · publisher `pub-8287765177319119` |
| Privacy policy | https://oasis-forge.github.io/koora-trivia-privacy/ — moved from the old personal-account URL (now 404) on 13 September 2026; Play Console was updated to it the same day |
| Upload key | `%USERPROFILE%/keys/koora-upload.jks` (alias `upload`) — the password is in `android/key.properties`, outside Git. **Never copy it into any other file.** |
| Repository | https://github.com/Oasis-Forge/koora-trivia — **public**, owned by the **Oasis-Forge organization** (transferred from the `thepromptkitchen-alt` account on 13 September 2026) · branch `main` |

> **Git — what to know:** the repository is **public**, so every file added is visible to
> everyone. The commit identity is local to this repo
> (`The Prompt Kitchen <thepromptkitchen@gmail.com>`) so the owner's personal email doesn't
> appear. Pushes go through the `gh` account (`thepromptkitchen-alt`) with a local credential
> helper — **not** through the owner's personal GitHub account stored in Git Credential
> Manager. `gh` is installed at `C:\Program Files\GitHub CLI\` and may not be on PATH.
> Intentionally excluded in `.gitignore`: `.aab`/`.apk` bundles (`NOTES.md` is kept) ·
> `privacy-site/` (a separate repo) · `key.properties` · `*.jks`.
>
> **Never write the owner's personal name, personal account names, or personal email into
> tracked files.** The owner does not want their name public.

### Play Console status

| Section | Status | Notes |
|---|---|---|
| Developer account registration | ✅ | Shows the legal name and address from the payments profile — see decision ② below |
| App created | ✅ | Game · Free · Arabic default |
| Store settings | ✅ | Category **Trivia** · contact email |
| Store listing | ✅ uploaded | Text from [STORE_LISTING.md](docs/STORE_LISTING.md) · 512 icon · feature graphic · 5 screenshots. ⚠️ A "Some languages have errors" warning appeared and **was never resolved** — open the Review step and read the error |
| AI asset declaration | ✅ | Icon and feature graphic labeled; screenshots are real captures, so not labeled |
| Data safety | ✅ | Per [DATA_SAFETY_EN.md](docs/DATA_SAFETY_EN.md) |
| Financial · health features | ✅ | None |
| Advertising ID | ✅ Yes | Advertising · analytics · fraud prevention |
| Content rating · target audience | ✅ | Everyone · 13+. App content shows nothing needing attention (checked 13 September 2026) |
| Displayed developer name | ❓ | Should be set to Oasis Forge in Account details |
| Developer verification | ✅ | Play reports all apps registered (deadline 30 September 2026) |
| Privacy policy URL | ✅ | Changed to the oasis-forge.github.io URL by the owner on 13 September 2026 |
| Internal testing | ⚠️ | Still serves the 6 September release — the bundle list shows `1.0.0` (versionCode 1, the **launch-crash** build) still active. Replace it with versionCode 4 or stop using the track |
| Closed testing | ✅ running · ⚠️ testers | Track **Alpha**: v1.0.3 (versionCode 4), available since **9 September 2026**, 177 countries. Only **5 of 12** testers opted in (13 September). New personal accounts need **12 testers opted in for 14 consecutive days** before requesting production, so the clock hasn't started |
| Production | ⏳ | |

### Next steps, in order
1. **Get 7+ more testers opted in** to the closed test (5 of 12). This is the critical path to production.
2. **Internal testing:** replace the crashing versionCode 1 with versionCode 4, or stop using that track.
3. Install v1.0.3 from the closed test on a **real phone** and verify: pass a level ⇒ star + "Next level"
   button + next level unlocked; daily challenge ⇒ no replay button.
4. Resolve the store listing's "Some languages have errors" warning (not checked yet).
5. While the 14-day clock runs: fix the §0 audit bugs (the daily challenge repeating every other day
   first) as v1.0.4 for the closed track, and review a sample of level 9–10 questions.
6. Before production: the owner's decisions ① and ② below.

### Decisions waiting on the owner
- **① Heart deduction.** Currently one heart per wrong answer; a single failed attempt drained
  all five on the emulator. Proposal on the table: one heart per **failed attempt**. Owner said
  "not now".
- **② Name and address shown publicly.** A personal developer account shows the owner's name and
  address on the store page. The alternative is an organization account (needs D-U-N-S).
  Undecided.
- **③ Multiple languages** — deliberately deferred until the Arabic version proves itself. The full plan,
  the decisions it needs, and a verified codebase audit are in [docs/I18N_PLAN.md](docs/I18N_PLAN.md).
- **④ Owner's personal name in public GitHub history — approved twice, owner to run the script.** On
  13 September 2026 the owner approved recreating both repos, in two separate sessions. Both times
  Claude Code's auto-mode permission check blocked the GitHub commands (repo create/rename/visibility),
  so **nothing on GitHub has changed yet**. What's known:
  - **App repo:** only the two oldest commits on `main` contain the strings, in 13 lines across
    `CLAUDE.md`, `docs/PRE_PUBLISH.md` and `android/key.properties.example`. Commit authors and
    messages are clean everywhere.
  - **Privacy repo:** its single commit is clean. Only its public Activity page shows the personal account.
  - A local rewrite of `main` was verified: identical final files, zero matches.

  **The owner runs the recreation script Claude prepared.** It's kept outside the repo because it contains
  the strings. It refuses to run while PRs are open (PRs don't survive recreation), then:
  1. Backs up both repos.
  2. Rewrites `main` and verifies it, then asks for confirmation.
  3. Renames the old repos to `<name>-old` and makes them private.
  4. Creates fresh repos and pushes through the `gh` account.
  5. Re-enables Pages; the privacy URL stays the same.
  6. Verifies fresh public clones.

  Afterwards the owner deletes the `-old` repos (Claude must never delete them) and this item moves to
  Done. The exact strings are in Claude's private memory, never in this repo.

---

## What the project is

A fully Arabic (RTL) Flutter football trivia app. A bank of **1000 questions** across ten
categories, with a daily challenge, a locally saved day streak, and a share-your-score button.
Targets Android. **Question content works offline; only ads need a connection.**

> User-facing text **must not promise** offline play **nor state a fixed number** of questions
> or categories — both were removed deliberately (owner's decision) so the text stays true as
> content is added. Keep it that way in any new text, including release notes and the store
> listing.

---

## ⚙️ Environment — read this first

**Flutter is installed at `C:\src\flutter` but is not on PATH.** Export it before any command:

```bash
$env:Path = "C:\src\flutter\bin;$env:Path"
```

| Component | Value |
|---|---|
| Flutter | 3.44.8 · Dart 3.12.2 |
| JDK | **Java 25** (bundled with Android Studio) |
| Gradle / AGP / Kotlin | **9.1.0 / 9.0.1 / 2.3.20** |
| OS | Windows 11 · PowerShell |
| `adb` | `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe` (not on PATH) |
| `keytool` | `C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe` |

**Don't downgrade Gradle.** The only JDK on the machine is Java 25; Gradle 8.x doesn't support it
and fails with a cryptic message that is just the Java version (`* What went wrong: 25.0.2`).
That message means a version mismatch and nothing else.

AGP 9 doesn't accept `kotlinOptions` — use a top-level `kotlin { compilerOptions { … } }` block
in `android/app/build.gradle.kts`.

> 🐛 **Critical release-build crash, fixed (8 September 2026):** AGP 9 enables R8 (shrinking and
> obfuscation) **by default** in `release`, even without `isMinifyEnabled`. That renames Room's
> generated classes (`WorkDatabase_Impl`), which WorkManager loads by reflection (WorkManager is
> pulled in by the AdMob SDK). Result: the app **crashes immediately on launch in release only**
> with `Failed to create an instance of androidx.work.impl.WorkDatabase` via
> `androidx.startup.InitializationProvider`. **It never shows in debug** (debug doesn't run R8).
> Fix: `isMinifyEnabled = false` and `isShrinkResources = false` in the `release` block. Verified:
> the release build launches and runs. To re-enable R8 later, add `-keep` rules for Room and
> WorkManager first and test a release build by hand.

> 🛡️ **Smart App Control is turned off on this machine** (owner's decision; it can't be turned back
> on without resetting Windows). It was blocking `gen_snapshot` for `android-arm`, so release
> builds failed with `An Application Control policy has blocked this file`. On a new machine,
> that symptom means the same cause. Workaround without turning it off:
> `--target-platform android-arm64` (drops 32-bit devices).

**Non-fatal build messages — ignore them:** `failed to strip debug symbols` (the bundle is still
produced) · Kotlin Gradle Plugin warnings from `flutter_timezone` and `share_plus`.

### Common commands

```bash
$env:Path = "C:\src\flutter\bin;$env:Path"; flutter test
```

```bash
$env:Path = "C:\src\flutter\bin;$env:Path"; flutter analyze
```

```bash
$env:Path = "C:\src\flutter\bin;$env:Path"; flutter run
```

```bash
$env:Path = "C:\src\flutter\bin;$env:Path"; dart run tool/rebalance_answers.dart
```

### Shipping a new version to Play — in this order

1. Bump `version` in `pubspec.yaml` — Google rejects a reused `versionCode`. Format:
   `1.0.3+4` ⇒ versionName 1.0.3, versionCode 4.
2. `flutter analyze` and `flutter test`.
3. Build **both**: `flutter build appbundle --release` then `flutter build apk --release`.
4. **Install the APK on the emulator and exercise the affected flow** — R8 and signing bugs don't
   show in debug.
5. Archive:

```bash
$env:Path = "C:\src\flutter\bin;$env:Path"; dart run tool/archive_release.dart "reason for this release"
```

> ⚠️ **The tool copies whatever `.aab`/`.apk` exists without checking that it matches the current
> version.** Build only one of them and the stale other one gets archived under the new version's
> name (this actually happened with v1.0.2). That's why step 3 always builds both.

### Testing on the emulator

- Emulator: `Pixel_6_Pro` (1440×3120, density 560, 145 px status bar).
  Launch it: `flutter emulators --launch Pixel_6_Pro`.
- **Switching between a debug and a release install on the same device** fails with
  `INSTALL_FAILED_UPDATE_INCOMPATIBLE` (different signatures) ⇒
  `adb uninstall com.oasisforge.kooratrivia` first.
- **Launch crashes:** `adb logcat -c` → launch the app → `adb logcat -d` and look for `AndroidRuntime`.
- **Flutter's UI is invisible to `uiautomator dump`.** To drive the screen with
  `adb shell input tap`, locate buttons by scanning screenshot pixel colors (gold buttons ≈ RGB
  245,197,66) — eyeballing is off by tens of pixels, and option positions shift with question
  text length.
- **Passing a level automatically:** level option order is deterministic (`SeededRandom(q.id)`,
  questions sorted by id), so the correct answer's position can be computed from the JSON.
- The timer is 20 seconds: any automation slower than that records "time's up" and costs hearts.

---

## Architecture

```
lib/
├── core/          constants · theme · utils · dependency container
├── domain/        entities · abstract contracts · use cases   ← never imports Flutter
├── data/          models · data sources · contract implementations
└── presentation/  Providers · screens · widgets
```

Dependency direction: `presentation → domain ← data`. **The `domain` layer must stay free of any
Flutter or third-party import.** That constraint has held so far — keep it.

### Known traps

- **`Category` clashes with `foundation.Category`.** Any file that imports
  `package:flutter/foundation.dart` directly and uses the `Category` entity needs
  `hide Category`. See [quiz_provider.dart](lib/presentation/providers/quiz_provider.dart).
- **Assets don't refresh on hot reload.** `AssetQuestionDataSource` caches the bank in memory,
  so any change to the question files needs a full restart.
- 🐛 **Never return a map of Models from a repository that promises a map of Entities.**
  The compiler accepts `Map<String, XModel>` where `Map<String, X>` is expected (covariance), but
  its **runtime** type stays a model map, so assigning a plain entity into it throws a
  `TypeError`. This actually happened in `ProgressRepositoryImpl.loadAll` and broke star saving
  and level unlocks (8 September 2026) — and the error was **swallowed** inside an async callback
  in the result screen, so the player saw nothing. Fix: `Map<String, X>.from(models)` at the
  repository boundary. Now guarded by `test/progress_provider_test.dart`.
- **Async callbacks in `addPostFrameCallback` swallow exceptions.** The result screen records
  stats, stars, and tasks there; any error disappears silently and leaves the UI incomplete. When
  adding logic there, test it through the provider directly, not through the screen.

---

## Question bank

```
assets/data/categories.json          index of the ten categories
assets/data/questions/<slug>.json    100 questions per category
```

Question schema: `id` · `level` · `question` · `options` (4) · `answerIndex` · `explanation`.

| # | slug | Display name (Arabic) | English | ID range |
|---|---|---|---|---|
| 1 | `world_cup` | كأس العالم | World Cup | 1001–1100 |
| 2 | `continental_cups` | البطولات القارية | Continental cups | 2001–2100 |
| 3 | `champions_league` | دوري أبطال أوروبا | Champions League | 3001–3100 |
| 4 | `top_leagues` | الدوريات الكبرى | Top leagues | 4001–4100 |
| 5 | `arab_football` | الكرة العربية | Arab football | 5001–5100 |
| 6 | `players` | اللاعبون | Players | 6001–6100 |
| 7 | `clubs` | الأندية | Clubs | 7001–7100 |
| 8 | `coaches` | المدربون | Coaches | 8001–8100 |
| 9 | `laws` | القوانين | Laws of the game | 9001–9100 |
| 10 | `moments_records` | لحظات وأرقام قياسية | Moments & records | 10001–10100 |

Each category = **10 levels × 10 questions**. Each question **stores** `level` in the JSON, and it
must equal `((id − idBlock − 1) ÷ 10) + 1` — all 1000 match and `question_bank_test` enforces it.
Difficulty derives from the level (1–3 easy · 4–7 medium · 8–10 hard) — **there is no `difficulty`
field in the JSON**.

**Option shuffling** (in `quiz_repository_impl.dart`): levels use `SeededRandom(q.id)` · the daily
challenge uses `SeededRandom(seed + q.id)` · quick play is random.

### Rules for writing questions — mandatory

1. **Four distinct options**, no exceptions.
2. **No «كل ما سبق» (all of the above), «لا يوجد» (none), «كلاهما» (both)** or similar. The app
   shuffles options before display, which makes that phrasing meaningless. Guarded by a test.
3. **`answerIndex` balanced** — run `tool/rebalance_answers.dart` after any addition.
4. **No duplicates across categories** — neither in wording nor in meaning. Guarded by two tests
   (exact match + approximate fingerprint).
5. **Evergreen questions only.** "Who won the 2022 World Cup?" stays true forever; "Who is La
   Liga's top scorer?" needs maintenance every season.
6. **No invisible direction or format characters** (U+200E/U+200F, U+061C, U+202A–U+202E,
   U+2066–U+2069, U+200B–U+200D, U+FEFF). Harmless in Arabic, but they silently reorder text in a
   left-to-right translation. One U+200F exists at `arab_football.json:120`; no test guards this yet.

> ⚠️ Rule 2's test lists only the masculine «كلاهما»; the feminine «كلتاهما» slipped through at
> `laws.json:946` (question 9073). Rule 4's near-duplicate check is also weaker than it looks: the
> stopwords «على» and «إلى» never match after normalisation (`question_bank_test.dart:256-263`).

### Rules for resolving category overlap

When a question could fit more than one category, apply these in order:

1. **`arab_football` has absolute priority** — a question about Morocco at the World Cup goes to
   Arab football, not World Cup. Deliberate: the most important category for this audience must
   stay rich. *Exception:* non-Arab African and Asian content (Senegal, Cameroon, Japan, Iran)
   stays in `continental_cups`.
2. **A tournament owns its records** — the World Cup's all-time top scorer goes to `world_cup`.
3. **Iconic moments beat the tournament** — the "Hand of God" and "the Istanbul night" go to
   `moments_records`.
4. **`clubs` for identity, `top_leagues` for competition** — Barcelona's stadium vs. who won the league.
5. **Records spanning tournaments** go to `moments_records`.

> ⚠️ `moments_records` and `coaches` are the most prone to duplicating the competition categories.
> Run the tests immediately after adding to either — the test caught 26 real duplicates when the
> bank was first built.

---

## Tests

**137 tests across 15 files, all passing.** `flutter analyze` is clean.

| File | Count | Covers |
|---|---|---|
| `quiz_provider_test.dart` | 22 | Scoring · speed bonus · multipliers · timer · sequencing · result building |
| `economy_test.dart` | 18 | Heart regen (remainder · clock going backward · corrupt date) · daily limits · `EconomyProvider` (deduction · daily-challenge grant · rewarded-ad cap · hints) |
| `level_progress_test.dart` | 13 | Star calculation · progressive unlocks · stars never decrease (entity and use case) |
| `tasks_coins_test.dart` | 12 | Daily tasks (completion · claim once · chest · daily reset) · shop (heart refill · insufficient coins · hint pack and consumption order) |
| `ads_test.dart` | 10 | `AdsProvider` (earned/dismissed · no two ads at once · isReady) · interstitials (round counting · remove-ads) · ad rewards — **through a fake service** |
| `reminder_test.dart` | 9 | Permission · scheduling and cancel · permission revoked at launch · next-fire calculation |
| `share_text_test.dart` | 8 | Result grid · daily-challenge date · category and level · Arabic dual form · doesn't leak questions |
| `quiz_repository_test.dart` | 8 | Levels · daily-challenge stability · filtering |
| `question_bank_test.dart` | 8 | Bank integrity: counts · IDs · structure · balance · banned options · **duplicates** · matches `AppConfig` |
| `update_streak_test.dart` | 5 | Day-streak logic in every case |
| `settings_screen_test.dart` | 5 | **Widget test** — stats display · confirmation dialog · reset |
| `progress_provider_test.dart` | 5 | **Provider-to-storage wiring** — pass ⇒ stars ⇒ next unlocked · survives restart (guards the covariance bug) |
| `daily_guard_test.dart` | 5 | `isDailyDone` after completion · persists across restart · quick play doesn't set it |
| `backup_test.dart` | 5 | Export then import · corrupt code · extra whitespace · newer version rejected |
| `economy_balance_test.dart` | 4 | Daily income below cheapest purchase · purchase within two days · interstitials off · chest is worth it |

### Not covered — and it has bitten us

- **The real AdMob bridge (`AdMobAdService`).** `ads_test` uses a fake service, which is why the
  "reward is never granted" bug slipped through every test. Test it by hand on the emulator.
- **The quiz, result, and levels screens** have no widget tests. The visibility of the "Next level"
  and "Replay level" buttons, and hiding the replay button after the daily challenge, are
  **not covered automatically**.
- **Release-build-only failures** (R8, signing) — `flutter test` can't catch them.
- No integration tests (`integration_test`).
- No guard against hardcoded user-visible strings — 28 literal lines already bypass `app_strings.dart`.
- `quiz_repository_test` "daily differs between two days" **only passes east of UTC** (see Remaining
  §0); it would fail on a UTC or western CI machine.

**Timer tests:** `quiz_provider_test.dart` uses `fakeAsync` from the `fake_async` package
(declared in `dev_dependencies`) to fast-forward time instead of waiting. Required patterns:
`async.flushMicrotasks()` after an un-awaited `start*` call, and `quiz.dispose()` **inside** the
`fakeAsync` block, otherwise the test fails with a pending timer.

---

## ✅ Done

**The game**
- Complete, verified 1000-question bank · three-layer Clean Architecture + Provider
- Three modes: levels (category grid → level grid → quiz) · quick play · daily challenge
- Deterministic daily challenge (same questions for everyone, no server, date-derived seed), once per day
- Day streak `user_stats_v1` · level progress with stars and progressive unlocks `level_progress_v1`
- Result screen: level stars · "Next level" on a pass · "Replay level" · answer review · share
- Economy: regenerating hearts + hints + daily limits · coins + 3 daily tasks + chest + shop
- Rewarded ads (heart · 70 coins) and interstitials (off) + UMP consent — production IDs in release
- Daily reminder on device time · haptics and sound via system sounds (no audio files), two toggles
- One-time onboarding · settings with stats and safe reset · progress export/import (Base64)
- Full RTL + stadium theme · level grid is 3 centered columns (was 4 with a big empty gap)

**Publishing**
- Final `applicationId` · release signing · `.aab` ≈57 MB and `.apk` ≈60 MB (R8 off)
- Professional icon in every size + adaptive · store assets · privacy policy published
- Release archive `releases/` + `tool/archive_release.dart`
- Full emulator verification on a release build (8 September 2026) — see [PRE_PUBLISH.md](docs/PRE_PUBLISH.md)

**Four critical bugs fixed after the first upload** (none visible in debug or in tests):
R8 crashing launch · a covariance bug blocking star saving and the Next-level button · rewarded-ad
reward never granted · a replay button implying the daily challenge could be repeated. Details in
each section.

### Store assets and docs

| File | What it is |
|---|---|
| `assets/branding/play_store_icon_512.png` | Store icon — **full green square to the edges** (Play rounds the corners itself; never upload a pre-rounded icon) |
| `assets/branding/app_icon_source.png` | Launcher icon source · `app_icon_foreground.png` for adaptive · `app_icon_cutout.png` transparent cutout |
| `assets/branding/feature_graphic_1024x500.png` | Feature graphic with title · `feature_art.png` raw art without text |
| `screenshots/store_9x16/` | **The uploaded screenshots** — 5 × 1080×1920 |
| `screenshots/store/` | ⚠️ 1440×2975 (ratio 2.07) — **rejected by Play**, don't use |
| [docs/STORE_LISTING.md](docs/STORE_LISTING.md) | App name · short description · full description (Arabic payload) |
| [docs/DATA_SAFETY_EN.md](docs/DATA_SAFETY_EN.md) | Data safety answers in Play Console's English terms · Arabic copy [DATA_SAFETY.md](docs/DATA_SAFETY.md) |
| [docs/privacy_policy.html](docs/privacy_policy.html) | Privacy policy source (English + Arabic) |
| `docs/app-ads.txt` | Ready, **not published** (needs a root domain) |
| [docs/PRE_PUBLISH.md](docs/PRE_PUBLISH.md) | Publishing checklist and verification log |
| [docs/ECONOMY.md](docs/ECONOMY.md) | Economy design — **still in Arabic** |

- The icon and feature graphic were **AI-generated** (Higgsfield) and then processed with PIL —
  hence labeled in Play's declaration. The Arabic title on the feature graphic was drawn with PIL
  plus `arabic_reshaper` and `python-bidi` (generators garble Arabic script).
- **The privacy policy is published from `privacy-site/`** — a separate git repo pushing to
  `Oasis-Forge/koora-trivia-privacy` (GitHub Pages, served at
  https://oasis-forge.github.io/koora-trivia-privacy/). Since 13 September 2026 it pushes through the
  `gh` account with the same local credential helper as this repo, not the personal account in Git
  Credential Manager. ⚠️ **Renaming or transferring that repo changes the public URL with no
  redirect** — the old URL returned 404 after the move to the organization, so Play Console's
  privacy policy link must be updated whenever that happens. To update the page: edit
  `docs/privacy_policy.html` → copy it to `privacy-site/index.html` → commit → push.

### Ads — what to know

> 🐛 **Critical bug, fixed (8 September 2026):** `AdMobAdService.showRewarded` returned as soon as
> the ad was *shown* (`await ad.show`), not when it was dismissed, so the reward flag was read
> before the `onUserEarnedReward` callback arrived ⇒ it always returned `dismissed` and the reward
> was **never** granted (heart or 70 coins). Fix: wait for dismissal with a `Completer` completed
> in `onAdDismissedFullScreenContent`, then read the flag. Verified on the emulator: watching the ad
> now actually grants the heart (0 → 1). No automated test covers it because it depends on the SDK;
> test by hand after any change to the rewarded-ad path.

| Type | Where | Reward |
|---|---|---|
| Rewarded | No-hearts dialog | +1 heart (max 4 per day) |
| Rewarded | Shop | +70 🪙 (no limit) |
| Interstitial | After the result | Every 3 rounds, 3-minute cap — **off at launch** |

- **`AppConfig.interstitialsEnabled = false` at launch, deliberately.** First-days ratings on Play
  carry a lot of weight, and interstitials hurt them most. Launch clean, then enable in a later
  update with a one-line change. A test guards this — flip it when enabling.
- **Never an interstitial after the daily challenge** — deliberate, to protect the daily ritual.
- The reward is granted on `RewardResult.earned` **only**, never on early dismissal.
- The rewarded-ad button shows disabled with «يتطلب اتصالاً بالإنترنت» ("requires an internet
  connection") until the ad has loaded (a few seconds after launch or after a previous watch) —
  expected, not a bug.

> ✅ **Production IDs set (8 September 2026)** — the app ID is in `AndroidManifest.xml`, the
> rewarded and interstitial unit IDs are in
> [`admob_ad_service.dart`](lib/data/services/admob_ad_service.dart), and test-vs-production is
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
| Hearts | 5, deducted per wrong answer **in level mode only** |
| Regen | One heart every 30 minutes, computed on read, not by a timer |
| Daily challenge | Grants one free heart on completion |
| Rewarded ad | +1 heart, max 4 per day (`heartsPerRewardedAdWatch`) |
| Hints | 3 per day: remove two answers · skip · extra time |

- **The daily challenge and quick play are completely free** — no hearts, no hints, no ads. That
  protects the streak from being broken by monetization.
- The balance is computed from `hearts + lastRegenAtIso`, and the remainder is kept, so waiting
  minutes aren't lost between reads.
- A device clock going backward resets the reference instead of producing a negative balance.
- Stored under `economy_v1`.
- Hearts are checked only **before starting** a level; if they run out mid-round, the round finishes.

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
- `SettingsProvider.init()` re-checks the permission at every launch and turns the toggle off if
  the permission was revoked in system settings while the app was closed.
- The economy design is documented in [docs/ECONOMY.md](docs/ECONOMY.md).

### Daily challenge — once per day

- `StatsProvider.isDailyDone` (from `lastDailyDayKey`) is the source of truth; the home card
  disables its play button on it and shows a countdown to tomorrow's challenge.
- 🐛 **Fixed (8 September 2026):** the result screen showed a "Play again" button after the daily
  challenge, which actually started a random **quick play** round — so players thought they were
  replaying the challenge. Now `_showReplayButton => !_result.isDaily` hides it after the daily
  challenge; "Replay level" remains in level mode and "Play again" in quick play.
  `daily_guard_test` covers `isDailyDone`; **the button's visibility itself has no widget test**.
- Leaving the challenge before finishing doesn't mark it complete (deliberate).

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

## 📋 Remaining — by priority

> Play Console status and steps are in **"Current status"** at the top of this file. Detailed
> verification and form answers are in **[docs/PRE_PUBLISH.md](docs/PRE_PUBLISH.md)**. Update both
> together.

### 0. Bugs found by the codebase audit — visible in the Arabic app today
Found by the read-only audit on 13 September 2026; file:line details and lower-priority items are in
[docs/I18N_PLAN.md §0](docs/I18N_PLAN.md). **None is fixed yet.**
- **The daily challenge repeats on two consecutive days.** `SeededRandom` does
  `(seed & 0x7FFFFFFF) | 1` (`seeded_random.dart:5`), so day numbers 2k and 2k+1 give the same
  shuffle — every other day, players get yesterday's 7 questions again and can ace them for a streak day.
- **The daily seed depends on the time zone** (`day_key.dart:30`): the Gulf and UTC/west get different
  sets on the same date.
- **Wrong Arabic grammar on screen** — a count plus a noun with no agreement on 13 lines: «N يوم متتالية»
  (home, settings, score), «ستفقد N نجمة» (reset dialog), «نقطة» after any score, and the share text's
  «1 أيام» / «12 أيام». `settings_screen_test` and `share_text_test` currently assert the wrong forms.
- **Raw exception text reaches players:** `quiz_provider.dart:150` shows `e.toString()` in a SnackBar.
- **Stale version string:** Settings → About shows «الإصدار 1.0.0» (`app_strings.dart:88`).
- **Misspelled names in the Arabic bank** — e.g. Koeman «روناد كومان» on 4 lines, «ويين روني»,
  «باساريا», «ياي توريه» — and the ambiguous «تشابي» in the 2010 final question (`world_cup.json:649`:
  Xavi or Xabi Alonso?).

### 1. Heart deduction ← **owner decision ①**
**Observed on the emulator:** one failed attempt (10 wrong answers) drained **all** five hearts ⇒
new players get frustrated fast. Options: one heart per **failed attempt** instead of per wrong
answer (the proposal) · raise the cap · lower the pass threshold. The other `AppConfig` numbers
(question timer, regen) haven't been tuned on a real phone yet.

### 2. Publishing on Play
See "Current status". Closed testing has been running since 9 September 2026, but only 5 of the 12
opted-in testers are there, so the 14-day clock hasn't started.

### 3. Question accuracy review
No human has reviewed the 1000 questions. Start with a sample of levels 9–10 in each category.

### 4. Quiz screen on tall devices
There may be a gap between the last option and the hints bar in level mode. Not addressed.

### 5. In-app purchases
Not built. Three products (two consumable heart packs + a non-consumable remove-ads).
⚠️ Consumables must be **acknowledged within 3 days** or the payment is refunded.

### 6. `app-ads.txt`
The file is ready in `docs/`; it needs a root domain declared in Play/AdMob. Doesn't block ads
from serving.

### Housekeeping
- R8 is off ⇒ a bigger bundle. Re-enable later with `-keep` rules for Room/WorkManager and a
  release-build test.
- The archive tool has no guard against stale artifacts (see "Shipping a new version to Play").
- The splash screen `launch_background.xml` still uses the old `ic_ball` drawing.
- `UserStats.lastPlayedDayKey` is saved but never displayed.
- 13 `AppStrings` constants are never used (listed in `docs/I18N_PLAN.md`).
- Back buttons use `arrow_forward` and the quiz Next button uses `arrow_back`; both auto-mirror, so
  Arabic shows ← for Back — the reverse of Material's RTL convention. Fixing it changes Arabic
  visuals, so it needs owner approval.
- Icon-only back and quit buttons have no tooltip, so TalkBack gives them no name.
- `docs/ECONOMY.md` and `docs/DATA_SAFETY.md` are still in Arabic.
- `README.md` is stale (old test count, single questions file, a `difficulty` field) and publicly
  claims the app works fully offline (line 180) — contradicts the no-offline-promise rule.
- `cmdline-tools` missing from the Android SDK (builds work without it) · `share_plus` is 10.x
  while 13.x is available.

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
| Interstitials off at launch | First-days ratings matter more than their revenue |
| R8 off in release | Turned off to fix the launch crash; re-enabling needs keep rules and a release-build test |

---

## Expected way of working

- **Every new feature or fix gets exactly one branch off `main` and a PR (pull request)** —
  owner's rule, 13 September 2026. Never commit straight to `main`, never stack branches, and
  never leave a superseded branch behind: one branch per piece of work.
  1. `git fetch origin`, then branch from the **latest `origin/main`**:
     `git switch --no-track -c <type>/<short-name> origin/main` (`feature/…` · `fix/…` · `docs/…`).
  2. Commit the work on that branch.
  3. Push it and open a pull request against `main` with `gh pr create` — summary plus how it was
     tested.
  4. Merging is the owner's call: don't merge or enable auto-merge unless asked.
- **Talk to the owner in English, and write `CLAUDE.md` and everything in `docs/` in English.**
  Arabic is the product's language, not the working language — only text players read is Arabic
  (app strings, the question bank, store listing text, release notes, tester invites). Never infer
  a language rule from a file's current language; ask.
- All user-facing text is **Arabic**, collected in
  [app_strings.dart](lib/core/constants/app_strings.dart).
- Code comments are in Arabic (existing codebase convention) and explain **why**, not **what**.
- Run `flutter analyze` and `flutter test` before calling anything done.
- **Before saying a fix has reached users, try it on a release build on the emulator.** Three of
  the four critical bugs showed neither in debug nor in tests.
- The owner tests on their own phone and reports bugs — when they report one, reproduce it before
  fixing, and don't assume the cause from reading the code alone.
- Tunable numbers go in [app_config.dart](lib/core/constants/app_config.dart), not scattered
  through the code.
