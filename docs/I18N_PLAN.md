# Multilingual plan — Koora Trivia (تحدي كرة القدم)

> **Status: deferred by owner decision** until the Arabic version proves itself. Nothing in this
> document is implemented.
>
> **Source:** a read-only audit of the whole codebase on **13 September 2026** — six inventories
> (strings, layout direction, content, platform, architecture, tests), a completeness critic that
> re-verified the counts, and seven follow-ups on areas nobody had covered. **353 findings**
> survived; **29 false positives** were removed. File:line references are as of that date — re-check
> before editing, since files move.

---

## TL;DR

- **Feasible, and the storage layer is already ready.** Progress, stats and the economy are keyed by
  slug and number, so they survive a language switch untouched.
- **Two very unequal halves.** Engineering is roughly **1–2 weeks**. Content is the real project:
  **6,010 text fragments** plus a mandatory glossary for **878 proper names**.
- **One hard blocker to render LTR at all:** `app.dart` forces `Locale('ar')` (line 69) and wraps the
  whole app in an RTL `Directionality` builder (lines 76–79).
- **Decide before building** (section 1): translate vs. native editions, US vs. UK English, device
  language vs. in-app picker, and what happens to `arab_football`.
- **The audit also found bugs in the Arabic app today** (section 0). Those are worth fixing whether or
  not a second language ever ships.

---

## 0. Bugs in the Arabic app today (found by the audit, independent of languages)

| # | Bug | Where | Impact |
|---|---|---|---|
| 1 | **Daily challenge repeats on two consecutive days.** `SeededRandom` does `(seed & 0x7FFFFFFF) \| 1`, so day numbers 2k and 2k+1 produce the same shuffle | `lib/core/utils/seeded_random.dart:5`, used by `quiz_repository_impl.dart:80` | Every other day, players get yesterday's 7 questions again — and can ace them for a streak day |
| 2 | **Daily seed depends on the time zone.** `epochDay` uses local midnight minus UTC epoch | `lib/core/utils/day_key.dart:30` | The Gulf and UTC/west get different sets on the same date. `quiz_repository_test.dart:89` ("daily differs between two days") only passes east of UTC — it would fail on a UTC or western CI machine |
| 3 | **Wrong Arabic grammar on screen:** a count plus a noun with no agreement — 13 lines, 14 nouns | «N يوم متتالية» `home_screen:97`, `settings_screen:46`, `score_screen:270`; «ستفقد N نجمة» `settings_screen:113-114`; «نقطة» after any score `quiz_screen:247`, `score_screen:387`; share text `build_share_text:56` gives «1 أيام», «12 أيام» | Visible to every player. `settings_screen_test:267` and `share_text_test:60, 88-89` currently **assert the wrong forms** |
| 4 | **Raw exception text reaches players** | `quiz_provider.dart:150` sets `_errorMessage = e.toString()`, shown in a SnackBar at `home_screen:65`, `levels_screen:65`; Arabic `FormatException` messages from `question_model.dart:29, 34` and `question_local_datasource.dart:58` | Players see developer diagnostics |
| 5 | **Stale version string** | `app_strings.dart:88` «الإصدار 1.0.0» vs `pubspec.yaml` 1.0.3+4 | Settings → About shows the wrong version |
| 6 | **Banned "both" option slipped past the test** | `laws.json:946` «كلتاهما مستخدمة» (feminine form) is the correct answer to question 9073, which lists three technologies; the test only lists masculine «كلاهما» | Meaningless answer once options are shuffled |
| 7 | **Near-duplicate check weaker than documented** | `question_bank_test.dart:256-263`: stopwords «على» and «إلى» never match after normalisation (3 dead entries, 1 redundant) | Fewer duplicates caught |
| 8 | **Misspelled or inconsistent names in the Arabic bank** | Koeman «روناد كومان» (`players:377, 972, 1064`, `coaches:400`) · Rooney «ويين روني» (`top_leagues:1024`) · Passarella «باساريا» (`world_cup:1183`) · Yaya Touré «ياي توريه» (`players:505`) · Nereo Rocco «ريكو» (`coaches:660`) · Sepp Maier «سيبماير» (`world_cup:1037`, `moments_records:559`) · Mourinho spelled two ways across 13 option lines · Halilhodžić two unrelated spellings · Atalanta «أتلانتا» reads as Atlanta (`clubs:1243`) | Wrong names shown today |
| 9 | **Ambiguous answer** | «تشابي» in the 2010 World Cup final question (`world_cup.json:649`) could be Xavi or Xabi Alonso | Needs the author to confirm |
| 10 | **Arrow direction** | `Icons.arrow_forward_rounded` is the Back button on 5 screens, `arrow_back_rounded` the quiz Next button. Both auto-mirror, so Arabic shows ← for Back and → for Next — the reverse of Material's RTL convention | Fixing it changes Arabic visuals — **owner approval needed** |
| 11 | **Icon-only controls with no spoken name** | 5 back buttons + quiz quit `IconButton` have no tooltip; the coin badge and shop buy button read as bare numbers | TalkBack users get "button" or "200" |
| 12 | **Tight layouts at 320 dp** | Home status row (`home_screen:270`) estimated ~325 dp in Arabic vs 280 dp available on a 320 dp phone. No `Flexible`/`FittedBox`/`Wrap` anywhere in `lib`; no small-screen tests | Possible overflow on small phones |
| 13 | **Mirrored Σ icon** | `functions_rounded` at `settings_screen:59` auto-mirrors in Arabic | Cosmetic |
| 14 | **Dead strings** | 13 `AppStrings` constants are never used | Housekeeping |
| 15 | **One invisible U+200F** | `arab_football.json:120` (question 5009 explanation) | Harmless in Arabic; reorders text if copied into an English file |

**Suggested priority:** 1, 3, 4, 5 first (players see them) → 2, 6, 8, 9 → the rest.

---

## 1. Decisions to make before any work

1. **Content strategy.** *Translate* the bank with identical question IDs (the daily challenge stays
   identical worldwide; progress stays comparable) **or** write *native editions* per language
   (better content, but separate dailies and effectively two games on one engine). Trivia translates
   poorly — especially `arab_football`.
2. **Which English.** en-US or en-GB (or both). It decides: football/soccer, manager/coach, draw/tie,
   clean sheet/shutout, 12-hour vs 24-hour time, "Aug 4" vs "4 Aug", and the Play listing code.
   Using **"Koora Trivia"** as the English name sidesteps football/soccer in the title.
3. **How the language is chosen.** Follow the device only, or add an in-app picker (and optionally
   Android 13 per-app language via `locales_config.xml`). **Existing users need a migration:** saved
   settings with no language would suddenly follow the device — an Arabic speaker with an English
   phone would see the app flip. Suggested: if settings exist and `onboardingSeen` is true, set `ar`.
4. **Fallback language** for unsupported device languages — today the first entry in
   `supportedLocales` (`ar`).
5. **`arab_football` for non-Arab audiences.** 100 questions, ~83 of which name an Arab country or
   club directly. Keep and translate, rename, or hide from the grid. The overlap rule that funnels
   Arab content into it (QUESTION_BANK.md) may not hold for other audiences.
6. **Digits.** Western digits today (and intl's `ar` default) vs Arabic-Indic.
7. **Gendered address.** 36 strings address the player in the masculine. Keep generic masculine, or add
   an ICU `select` on a gender setting that doesn't exist yet.
8. **Arrow convention for Arabic** (bug 10).
9. **Does the language travel in backups?** `app_settings_v1` is included in export/import.
10. **Share text.** Which language the shared text uses, and whether to prefix the emoji grid with a
    left-to-right mark so it reads the same in every language.

---

## 2. Engineering work (≈1–2 weeks)

### 2.1 Localization infrastructure
- `pubspec.yaml`: add `intl` as a **direct** dependency (it only arrives transitively today, 0.20.2)
  and `flutter: generate: true`; add `l10n.yaml`, `lib/l10n/app_ar.arb` (template) and `app_en.arb`.
- Convert the **144** `static const String` constants to ARB. Skip the **13 unused** ones. **Don't**
  carry over the **7 fragment constants** built for gluing sentences (`of`, `question`, `day`, `level`,
  `levelsDone`, `nextHeartIn`, `streakKept`) — replace each use with a full ICU message.
- Replace **153 references in 18 files** with `AppLocalizations.of(context)`. Drop `const` where it
  blocks this (e.g. `const Text(AppStrings.quitTitle)`, the static onboarding page list, the static
  `_TaskCard._title` helper).
- **24 concatenated sentence sites** become single parameterized messages; **13 lines with 14
  count-dependent nouns** get ICU plurals (Arabic needs zero/one/two/few/many/other).
- Extract the **28 hardcoded literal lines** outside `app_strings.dart` (18 presentation, 5 domain,
  2 core, 3 data) plus `android:label` in `AndroidManifest.xml:8`.

### 2.2 App shell
- `app.dart:69` remove the forced `Locale('ar')`; `app.dart:76-79` remove the RTL builder —
  `GlobalWidgetsLocalizations` (already registered) sets direction from the locale.
- Add `AppLocalizations.localizationsDelegates`; replace `title` with `onGenerateTitle` (the task
  switcher shows the Arabic title today).
- **In-app picker only:** `MaterialApp` is built above `MultiProvider` (`app.dart:32/62`), so it can't
  watch settings. Wrap it in `Selector<SettingsProvider, String?>` (not `Consumer`, so toggling sound
  doesn't rebuild the app).
- `AppSettings.languageCode` (nullable, null = follow device) + read/write in
  `settings_local_datasource.dart`. `copyWith` uses `??` and can't reset to null — use a sentinel.
- Settings screen: a language panel (system · العربية · English), each name in its own language.
- Launcher name: point `android:label` at `@string/app_name` with `values/` and `values-en/`
  `strings.xml`.

### 2.3 Keep the domain layer pure
Generated localizations import Flutter, which the domain layer must never do. **7 domain members
return display text** and must return enums/keys instead, with presentation mapping them to text:
`Difficulty.arabicLabel` · `Question.categoryName` · `Category.name` · `QuizResult.rankLabel` ·
`AppSettings.reminderLabel` · `BuildShareText.call` · `BuildShareText._dayWord`. Two domain files
import `AppStrings` (`quiz_result.dart:1`, `build_share_text.dart:1`). For share text: keep `grid()` in
domain; assemble the words in presentation or inject a pure-Dart strings interface.

**23 `AppStrings` references in 6 files have no `BuildContext`:** the notification scheduler (4),
`QuizResult` (4), `BuildShareText` (5), `MaterialApp.title` (1), `_TaskCard._title` (3), the onboarding
list (6). Use `lookupAppLocalizations(Locale)` or pass the strings in.

### 2.4 What must reload on a language change
- **Question bank cache** — `question_local_datasource.dart:33`, one instance, no language key, no way
  to clear it.
- **Copied category names** — into every `Question` (`:67`), `QuizProvider._categories` (loaded only in
  Home/Categories `initState`), `Category` route arguments, and the result answers used for share text.
  Clearing the cache alone leaves old names on screen.
- **Scheduled reminder** — title, body and channel name are baked into the OS alarm
  (`local_notification_scheduler.dart:70-93`). Reschedule on change; set
  `channelAction: update` or the old channel name stays in system settings.
- **Any round in memory** — abandon it.
- **Nothing else** — stats, progress and economy are keyed by slug/number.

### 2.5 Layout direction
- **6 arrow icons** (bug 10): the 5 back buttons → `BackButton` (free localized tooltip, mirrors
  correctly); quiz Next → `arrow_forward_rounded`.
- **6 side-encoded paddings** → `EdgeInsetsDirectional`: the 5 headers using `fromLTRB(8, 8, 20, …)`
  (categories 104, levels 178, settings 173, shop 31, tasks 26) and `settings_screen:199` (`right: 4`).
- **`Positioned(left: -3)`** on the home Tasks badge (`home_screen:186-188`) → `PositionedDirectional(end:)`.
- **Optional:** 2 fixed `topRight→bottomLeft` gradients (cosmetic).
- **Already fine:** the other 18 paddings, `LinearProgressIndicator`, `PageView`, the chips list, all 21
  `Cross/MainAxisAlignment` uses, the symmetric pitch painter. No `TextAlign.left/right`, no rotation.

### 2.6 Formatting
- Two duration formatters with «س»/«د» (`daily_challenge_card:105-110`, `hearts_bar:66-70`, rounding
  differently) → one shared localized formatter.
- `DayKey.arabicShortDate` month names → `DateFormat.MMMd(locale)` in presentation.
- `reminderLabel` is always 24-hour while the time picker is 12-hour — already mismatched in Arabic →
  `MaterialLocalizations.formatTimeOfDay`.
- Percent (`score_screen:213`) → `NumberFormat.percentPattern`; the `1.5` multiplier →
  `decimalPattern`.
- Answer letters «أ ب ج د» (`answer_option:29`) → localized.

### 2.7 English text length
- **Must fix:** home status row (`home_screen:270`, ~323 dp English vs 320 available with 4-digit coins
  and a countdown); tasks claim button fixed at 96 dp (`tasks_screen:178`) — "Claimed" wraps.
- **Should fix:** score stat tiles, the question-card tag row, category-card fixed aspect ratio, daily
  card title, no-hearts dialog title, home stat tile on 320 dp phones.
- Test on the emulator in English at 320 dp and at 1.3× font scale.

### 2.8 Platform limits (document, can't fix)
- The UMP consent form and ad creatives follow the **device** language, not an in-app choice —
  `google_mobile_ads` 9.0.0 exposes no language option.
- The notification channel's name persists in system settings until the channel is updated.

---

## 3. Content work — the real cost

| Item | Count |
|---|---|
| Questions · options · explanations · category names | 1,000 · 4,000 · 1,000 · 10 |
| **Translatable fragments** | **6,010** (126,690 characters, 22,508 words) |
| Options needing no translation (years, scores, counts) | 550 |
| Unique option strings | 1,884 of 4,000 |
| **Unique person/club/stadium names** | **878** (643 people · 193 clubs · 44 stadiums), 1,933 uses |
| Questions with at least one name option | 511 |
| Questions about nicknames («لقب/يلقب») | ~146 |
| Existing glossary | none |

**A proper-name glossary is mandatory** — keyed by a stable entity ID, not the Arabic string:
- **7 Arabic strings map to several entities:** «الأهلي» = three clubs (Egypt, Saudi Arabia, UAE) ·
  «الاتحاد» = Etihad Stadium and Al-Ittihad · «الإمارات» = UAE and Emirates Stadium · «رونالدو» =
  Ronaldo Nazário and Cristiano Ronaldo · «مولر» = Gerd/Thomas Müller, Andreas Möller, Richard Møller
  Nielsen · «تشابي» · «كارلوس ألبرتو» (two people).
- **14 same-entity spelling variants and 17 short-vs-full forms** already in the Arabic.
- **Transliteration gives wrong names** for North African and Gulf players and clubs, which use French
  or registered spellings (Ziyech, Madjer, Aboutrika, USM Alger, JS Kabylie, Espérance). Sócrates is
  written with the philosopher's Arabic name.
- **Nicknames:** restore the original-language nickname; don't back-translate.
- **Language-about questions** need rewriting per language, e.g. `clubs.json:1061` ("why is Milan
  written *in English* as Milan?").

**Regional vocabulary glossary** (only if English variants differ): «كرة القدم» 19 (4 are proper names
that stay "Football") · «مدرب» 54 · «تعادل» 11 (4 are equaliser/equalizer) · clean sheet 4 · extra time
22 · stoppage time 4 · shirt/jersey 16 · boots/cleats 2 · pitch/field 14 in `laws.json` · «ملعب/ملاعب»
69 lines to check one by one · «مباراة» 138.

**Recommended layout:** `assets/data/<lang>/categories.json` + `assets/data/<lang>/questions/<slug>.json`
with identical `id`, `level`, `answerIndex` and option order.
- ⚠️ **Flutter doesn't bundle subfolders of a listed asset folder** — declare every language folder in
  `pubspec.yaml`. The bank test reads straight from disk, so it would still pass while the app ships
  without questions.
- Remove the U+200F (bug 15) before extracting for translation.
- Run `tool/rebalance_answers.dart` on the source language only; generate translations that copy
  `answerIndex` and option order position by position.

---

## 4. Tests and tooling

**Will certainly break:**
- `question_bank_test.dart` — hard-wired Arabic paths; ID uniqueness checked across the whole load
  (shared IDs would all fail); 7 banned phrases, a 7-rule Arabic normaliser and 20 Arabic stopwords.
- `settings_screen_test.dart` — finds buttons through `AppStrings`; asserts «9 نجمة»; hardcodes an
  RTL harness. With gen-l10n its harness would crash.
- `share_text_test.dart` — 9 Arabic output assertions, including the wrong «12 أيام».

**Need edits depending on design:** `reminder_test` and the settings fake scheduler (signature has no
text); `quiz_repository_test` and `quiz_provider_test` fakes (no language parameter, single-string
category names); `daily_guard`, `progress_provider` and `share_text` fixtures (Arabic `categoryName`);
`backup_test` (where the language lives).

**Unaffected:** `level_progress`, `update_streak`, `tasks_coins`, `economy`, `ads`, `economy_balance`.

**New tests to add:**
1. ARB key and placeholder parity across languages.
2. Per-language bank parity: same IDs, levels, categories, `answerIndex`; same day ⇒ same daily set.
3. Every category has a name in every language.
4. A language switch reloads the bank and keeps progress.
5. LTR and RTL widget tests per screen — **only 1 of 8 screens has any widget test today**.
6. Notification text per language, rescheduled on change.
7. English share text (date, level label, plurals, no answer leaks).
8. Every language asset folder is declared in `pubspec.yaml`.
9. Numeric correct answers match across languages.
10. No text in the wrong script per bank.
11. No invisible bidi or format characters in any bank.
12. **A guard against hardcoded user-visible strings** scanning `lib/` — none exists, which is how 28
    literals slipped past `AppStrings`. It must handle lines mixing `AppStrings` with a literal (5 today),
    multi-line `FormatException` messages, `debugPrint` anywhere on a line, and future Latin literals.

**Tools:** `rebalance_answers.dart` hard-codes the Arabic paths. `archive_release.dart` writes one
release note; Play needs one per listing language (`<ar-SA>` / `<en-US>`).

---

## 5. Store listing and project docs

- **Resolve the existing "Some languages have errors" warning first** — it appeared with Arabic only.
- Add an English listing translation (name ≤ 30, short ≤ 80, full ≤ 4000), an English feature graphic
  rendered from the textless `assets/branding/feature_art.png`, an English screenshot set, and an
  English release-notes block.
- `docs/STORE_LISTING.md` claims the game is «عربية بالكامل» (fully Arabic) — false once English ships.
- CLAUDE.md and QUESTION_BANK.md rules that contradict a second language and must be rewritten when this lands: all
  user-visible text lives in `app_strings.dart`; the project is described as fully Arabic RTL; the
  question-bank rules are only test-guarded in Arabic; the English store name is still conditional.
- `README.md` is stale (11 tests, a single `questions.json`, a `difficulty` field).
- `docs/ECONOMY.md` assumes Arab-region ad revenue and pricing — revisit for other markets.

---

## 6. Suggested order when approved

1. **Fix the section 0 bugs** — valuable with or without a second language.
2. **Make the section 1 decisions.**
3. **Infrastructure with no visible change:** ARB files, domain purity, literal extraction, the
   hardcoded-string guard — still Arabic-only. Ship it as an Arabic release.
4. **English UI:** LTR fixes, English strings, formatting, text-length fixes; verify on the emulator in
   English at 320 dp.
5. **Glossary → translate the bank → parity tests.**
6. **Store listing, assets, release notes;** run a closed test with English testers.

---

## Appendix — verified counts

| Measure | Count |
|---|---|
| String constants in `app_strings.dart` | 144 (131 used, 13 unused) |
| References to them outside the file | 153 in 18 files |
| Hardcoded user-visible literal lines outside it | 28 (18 presentation · 5 domain · 2 core · 3 data) + manifest label |
| Concatenated sentence sites | 24 |
| Count-dependent noun sites | 13 lines, 14 nouns |
| Masculine-addressed constants | 36 |
| Domain members returning display text | 7 |
| Context-less `AppStrings` references | 23 in 6 files |
| Side-encoded layout sites | 9 (6 paddings · 1 `Positioned` · 2 cosmetic gradients) |
| Arrow icons pointing the wrong way in LTR | 6 |
| Padding sites total | 24 (18 harmless) |
| Test files that break / need edits / unaffected | 3 / 6 / 6 |
| New tests proposed | 12 |
| Icon-only controls with no spoken name | 6 buttons + 2 controls + 12 status indicators |
