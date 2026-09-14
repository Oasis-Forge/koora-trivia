# Koora Trivia — design overview

«تحدي كرة القدم» is an Arabic football trivia game for Android phones. This design system describes the
app **as it looks today**, so redesigns start from it. The real app is Flutter; the tokens in
`styles.css` are copied from its theme files, and `guidelines/components.md` describes each part.

## Platform and language
- **Portrait phone.** Design for 360–412 px wide. Short phones (height under 700 px) use a compact quiz layout.
- **Arabic, right to left.** Set `dir="rtl"` and `lang="ar"`. Start is the right edge; back arrows point right (→).
- **Dark only.** There is no light mode.
- **Numbers** are written with Western digits (0–9), e.g. «10 / 3», «200».

## Look and feel
- **A football pitch at night.** Every screen sits on the pitch background: a vertical gradient
  (`--pitch-gradient`), faint horizontal mowing stripes, and thin white pitch lines (a center circle and
  halfway line about 42% down, and a penalty box at the bottom).
- **Gold is the action color.** The main button on a screen is a gold pill-rounded button with dark text.
  Gold also marks stars, points, the timer, and the selected item.
- **Green means correct, red means wrong** — only for answers, lost hearts and destructive actions.
- **Cards** are a slightly lighter surface (`--card-surface`) with a thin light border.
- **Chalk white** text, with `--chalk-muted` for secondary lines.

## Themes
The player picks one of four color themes in Settings. They change only the pitch and card colors; gold,
chalk, correct and wrong keep their meaning. Set `data-theme` on the root element:

| data-theme | Name | Note |
|---|---|---|
| `green` | «ملعب أخضر» | default and original |
| `blue` | «ليلي أزرق» | the screenshots in `guidelines/screens/` use this theme |
| `purple` | «بنفسجي» | |
| `red` | «كلاسيكو أحمر» | `--wrong` is lighter so it stays visible |

## Rules to keep
- **Button icons sit on the left of their label** (after the text in right-to-left).
- Text must not promise offline play or state a fixed number of questions or categories.
- Quick play and the daily challenge are free; only levels use hearts and hints.
- Keep tap targets at least 48 px, and keep text readable when the system font is large.

## Screens
Current screenshots (blue theme, 540 × 1200) are in `guidelines/screens/`:

| File | Screen |
|---|---|
| `01_home.png` | Home: title, hearts and coins, daily challenge card, stats, category chips, quick play, levels |
| `02_settings.png` | Settings: stats list, daily reminder, sound and vibration |
| `03_tasks.png` | Daily tasks with progress bars and the chest |
| `04_shop.png` | Shop: heart refill, hint pack, watch an ad for coins |
| `05_categories.png` | Category grid with progress and stars |
| `06_levels.png` | Level grid (completed, available, locked) and the start footer |
| `07_quiz.png` | Quiz: close, question counter, points, timer, question card, four answers, hint bar |
| `08_quit_dialog.png` | The quit-round dialog over the quiz |
