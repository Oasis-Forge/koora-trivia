# Question bank

> Moved from CLAUDE.md on 14 September 2026. Read it before editing any question.

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
   left-to-right translation. Guarded by a test.

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
