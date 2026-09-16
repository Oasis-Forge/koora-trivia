# Question bank

> Moved from CLAUDE.md on 14 September 2026. Read it before editing any question.

```
assets/data/categories.json             index of the ten categories
assets/data/questions/<slug>.json       100 questions per category
assets/data/en/categories.json          the same index with English names
assets/data/en/questions/<slug>.json    English translation, same ids and answers
```

Question schema: `id` · `level` · `question` · `options` (4) · `answerIndex` · `explanation`.

| # | slug | Display name (Arabic) | Display name (English) | ID range |
|---|---|---|---|---|
| 1 | `world_cup` | كأس العالم | World Cup | 1001–1100 |
| 2 | `continental_cups` | البطولات القارية | Continental Cups | 2001–2100 |
| 3 | `champions_league` | دوري أبطال أوروبا | Champions League | 3001–3100 |
| 4 | `top_leagues` | الدوريات الكبرى | Top Leagues | 4001–4100 |
| 5 | `arab_football` | الكرة العربية | Arab Football | 5001–5100 |
| 6 | `players` | اللاعبون | Players | 6001–6100 |
| 7 | `clubs` | الأندية | Clubs | 7001–7100 |
| 8 | `coaches` | المدربون | Managers | 8001–8100 |
| 9 | `laws` | القوانين | Laws of the Game | 9001–9100 |
| 10 | `moments_records` | لحظات وأرقام قياسية | Moments & Records | 10001–10100 |

Each category = **10 levels × 10 questions**. Each question **stores** `level` in the JSON, and it
must equal `((id − idBlock − 1) ÷ 10) + 1` — all 1000 match and `question_bank_test` enforces it.
Difficulty derives from the level (1–3 easy · 4–7 medium · 8–10 hard) — **there is no `difficulty`
field in the JSON**.

**Option shuffling** (in `quiz_repository_impl.dart`): levels use `SeededRandom(q.id)` · the daily
challenge uses `SeededRandom(seed + q.id)` · quick play is random.

### Rules for writing questions — mandatory

1. **Four distinct options**, no exceptions.
2. **No «كل ما سبق» (all of the above), «لا يوجد» (none), «كلاهما» (both)** or similar — nor a bare «لا شيء» (nothing), «لا أحد» (no one) or «لم يحدث» (it never
   happened), per the owner's decision of 14 September 2026. The app
   shuffles options before display, which makes that phrasing meaningless. Guarded by a test.
3. **`answerIndex` balanced** — run `tool/rebalance_answers.dart` after any addition.
4. **No duplicates across categories** — neither in wording nor in meaning. Guarded by two tests
   (exact match + approximate fingerprint).
5. **Evergreen questions only.** "Who won the 2022 World Cup?" stays true forever; "Who is La
   Liga's top scorer?" needs maintenance every season.
6. **No invisible direction or format characters** (U+200E/U+200F, U+061C, U+202A–U+202E,
   U+2066–U+2069, U+200B–U+200D, U+FEFF). Harmless in Arabic, but they silently reorder text in a
   left-to-right translation. Guarded by a test.
7. **Every change goes into both languages.** Editing, adding or rebalancing an Arabic question needs the same
   change in `assets/data/en/questions/<slug>.json` — same `id`, `level`, `answerIndex`, option order, and
   numeric options unchanged. English is British, with football wording and English Wikipedia's spelling of
   names. `english_bank_test` fails on any mismatch.

8. **No time-relative wording without a year** — «حالياً», «الحالي», «حتى الآن», «حتى اليوم», «العقد الأخير» /
   currently, current, so far, to date, last decade. Guarded by `question_content_test`.
   Counts and records that could change within a few years (title counts, "most" records, caps, all-time top scorers
   near active players) use one of two anchors, preferably at the start (owner's decision, 16 September 2026):
   - club football, including the Ballon d'Or: «حتى نهاية موسم 2025-2026،» / "By the end of the 2025-26 season,"
   - national teams: «بعد كأس العالم 2026،» / "After the 2026 World Cup,"

   One-off feats (fastest goal, youngest scorer), rules and formats, and finished careers stay unanchored.
9. **An explanation never names the answer of a later question in the same level.** Levels play in id order and
   the explanation shows right after each answer. Guarded by `question_content_test` (implied spoilers need a
   reader).
10. **The correct option must not stand out.** Not by length (1.6× the longest wrong option and 8 or more characters
    longer, in either language), and not by being the only option that repeats a word from the question. Wrong options
    share the correct one's form and detail. Guarded by `question_content_test` (the word check runs on the English
    text; harmless repeats are listed in `_harmlessEchoes`).

> Rule 4's near-duplicate check normalises its filler words the same way as the question text
> (`_fingerprint` in `question_bank_test.dart`, fixed 14 September 2026). Since 15 September 2026
> `question_content_test` also compares the English wording (same answer and ≥ 50% shared words, or ≥ 70%
> shared words; questions naming different years are a series, not duplicates).

**After every World Cup, Euro, Copa América, Africa Cup of Nations, Asian Cup and Champions League final**, re-check
the questions about records, counts and "first/only/most" claims in both languages. Grep for the two anchor phrases
first; when moving them forward (e.g. to the 2026-27 season), confirm every answer at the new anchor.

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
