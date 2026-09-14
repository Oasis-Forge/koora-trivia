# CLAUDE.md — Project context and handoff notes

> Loaded at the start of every session and into every subagent, so it stays short: rules, current
> status, traps and pointers. Details live in `docs/` — read a file only when the task touches it.
> **Update the status and next steps here, and `docs/PLAN.md`, whenever work is completed.**
> Last updated: **14 September 2026**.

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

**On Play:** `v1.0.3+4` (`releases/v1.0.3_build4_2026-09-08/`) on the closed track. **On `main`, not in
a Play build yet:** PRs #2, #3 and #5–#8 (daily-challenge seed, zero-heart replay, ad consent,
reminders, small screens, backup import, reports/feedback/review prompt/error log). They ship as v1.0.4.

**Privacy policy:** `docs/privacy_policy.html` gained "Messages you send us" in PR #8 (effective
14 September 2026) but is **not published** — publish to `privacy-site/` only with the owner's go-ahead,
before v1.0.4 reaches testers.

### Next steps, in order
The prioritised plan is **[docs/PLAN.md](docs/PLAN.md)** — the source of truth for what's open.
1. **Testers (critical path):** 5 of 12 opted in; production needs 12 opted in for 14 consecutive days.
2. **Content fixes** from PLAN.md Phase 1 → Content, one micro PR each: never-right answers (~5 per PR) → outdated answers (~5 per PR).
3. **Ship v1.0.4:** steps in [docs/RELEASE.md](docs/RELEASE.md); log the release-build check in
   PRE_PUBLISH §1.
4. **Owner's Play Console tasks:** replace the crashing versionCode 1 on the internal track · the
   "Some languages have errors" warning · displayed developer name · app-ads.txt (PLAN.md P1 · S).

### Decisions waiting on the owner
- **① Heart deduction:** one heart per wrong answer drains all five in one failed attempt; proposal is
  one per failed attempt. Owner said "not now".
- **② Name and address on the store page** (personal account) vs. an organization account. Undecided.
- **③ Multiple languages:** deferred — [docs/I18N_PLAN.md](docs/I18N_PLAN.md).

### Identity and secrets — never break these
- **Never write the owner's personal name, personal account names, or personal email into tracked
  files.** The repo (https://github.com/Oasis-Forge/koora-trivia) is **public**.
- Store name **Oasis Forge** · package `com.oasisforge.kooratrivia` (**final**) · public contact
  `thepromptkitchen@gmail.com` · commit identity is local to the repo (`The Prompt Kitchen`).
- The upload key password lives only in `android/key.properties`. **Never copy it into any other file.**
- **Never tap your own live ads** — the AdMob account gets suspended. Emulators get test ads.
- **Pushing:** PowerShell 5.1 drops `""` arguments, so Git Credential Manager (the owner's personal
  account) answers. Push through Git Bash with
  `-c credential.helper= -c "credential.helper=!'C:/Program Files/GitHub CLI/gh.exe' auth git-credential"`,
  then check `gh api repos/Oasis-Forge/koora-trivia/activity --jq ".[0].actor.login"` is
  `thepromptkitchen-alt`.

---

## What the project is
A fully Arabic (RTL) Flutter football trivia app for Android: 1000 questions across ten categories,
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
  neither on PATH. Emulator: `Pixel_6_Pro`.
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
  the provider. Since PR #8 the local error log records them.
- `ChangeNotifierProvider` is **lazy** — anything that must start at launch needs `lazy: false`.
- **Providers write all their in-memory data on the next save** — reload them after changing
  SharedPreferences behind their back (see `RestoreBackup`).
- `map['x'] as int?` throws `TypeError`, not `FormatException` — datasources' static `decode` converts it.
- An unguarded `Navigator.pop` after an `await` can close the screen underneath — check the route is
  still current.
- **The quiz timer doesn't pause in the background** — nothing (Play's review sheet, the mail app) may
  open over a running question.
- Question assets don't refresh on hot reload — full restart.

### Rules that are easy to break — details in [docs/HOW_IT_WORKS.md](docs/HOW_IT_WORKS.md)
- **Every button that starts a level goes through `NoHeartsDialog.ensureHearts`**; quick play and the
  daily challenge stay free (no hearts, hints or ads).
- **Ads:** no SDK init or ad load unless `canRequestAds()`; rewards only on `RewardResult.earned`;
  `AppConfig.interstitialsEnabled` stays `false`; never an interstitial after the daily;
  `google_mobile_ads` must stay ≥ 9.
- **Arabic counts:** never `'$n يوم'` — use `ArabicCount.format(n, ArabicNoun.day)`.
- **A new stored key** must be added to `_decoders` in `BackupRepositoryImpl`.
- **Reminders:** one-shot per day (ids 1001–1007); the manifest receivers are required;
  `MY_PACKAGE_REPLACED` stays undeclared; never mix one-shot and repeating reminders.
- **Economy balance:** full daily income (130 🪙) stays below the cheapest purchase (200 🪙).
- **Button icons sit on the left of their text** (after it in RTL) through `iconAlignment` in `AppTheme` —
  owner's request, 14 September 2026. Don't override it per button.
- Tunable numbers go in `app_config.dart`; player-facing text in `app_strings.dart`.

## Question bank
`assets/data/questions/<slug>.json`, 10 levels × 10 questions per category. Before editing any
question read [docs/QUESTION_BANK.md](docs/QUESTION_BANK.md) (categories, id ranges, overlap rules).
Mandatory: four distinct options · no «كل ما سبق», «لا يوجد», «كلاهما» or «كلتاهما» · balanced
`answerIndex` (`dart run tool/rebalance_answers.dart`) · no duplicates across categories · evergreen
facts only · no invisible direction characters · `level` matches the id. Run `question_bank_test`
after any change.

## Tests
Shared fakes are in `test/fakes/`. Per-file coverage, the current count and what isn't covered:
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

## Expected way of working
- **One branch off the latest `origin/main` per task, then a PR:** `git fetch origin`,
  `git switch --no-track -c <feature|fix|docs>/<short-name> origin/main`, commit, push, `gh pr create`.
  Never commit to `main`, never stack branches, never leave a superseded branch. **Merging is the
  owner's call.**
- **English** with the owner and in CLAUDE.md and `docs/`. **Arabic** only for what players read (app
  strings, question bank, store text, release notes). Code comments are Arabic and explain *why*.
- When the owner reports a bug from their phone, reproduce it before fixing.
- Before saying a fix has reached users, it must have passed a release-build check on the emulator.
