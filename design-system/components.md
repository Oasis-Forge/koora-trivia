# Koora Trivia — how each part looks today

Values are the app's own (Flutter widgets under `lib/presentation/widgets` and `lib/presentation/screens`),
expressed with the tokens in `styles.css`.

## Screen frame
- **Pitch background** behind everything (see overview). Content scrolls over it.
- **Header row:** back arrow button (→, `--chalk`) at the start, a bold title (`--text-title`, weight 900),
  and an optional pill at the end (hearts, coins or star total). Padding: 8px top, `--space-page` at the start.
- **Page padding:** `--space-page` on both sides; `--space-section` between sections, each with a small
  gold section heading.

## Buttons
- **Primary (filled):** background `--gold`, text `--pitch-dark`, height `--button-height`, full width,
  radius `--radius-button`, label `--text-button` weight 700, icon on the left of the label.
- **Secondary (outlined):** transparent, border `--border-outlined`, text `--chalk`, same size and radius.
- **Tertiary (text):** no border or fill; `--chalk-muted` text with an icon, e.g. «الرئيسية».
- **Result screen accent:** «العب مستوى» uses `--pitch-light` as its fill with `--chalk` text.
- **Disabled:** fill `rgba(255,255,255,0.07)`, text `--chalk-muted`; the shop shows the reason in
  `--text-caption` under the button.

## Cards and tiles
- **Card:** `--card-surface`, `--border-card`, radius `--radius-card`, padding `--space-card`.
- **Stat tile:** a small card with a gold icon, a big bold number and a `--chalk-muted` label; three in a row.
- **Daily challenge card:** large gold-gradient card (`--gold-gradient`) with dark text: title with a flame
  icon, a line of question count and points multiplier, a streak pill, and a dark full-width button.
  Once done, it shows a check and the time until the next challenge.
- **Category card:** card with a gold icon in a rounded square, the category name, a thin progress bar,
  «n / 10» levels and a star count. Two columns.
- **Level tile:** radius `--radius-tile`, three states:
  - completed: `--card-surface`, border gold at 55%, number plus earned stars;
  - available: `--pitch-light` at 22%, border `--pitch-light`, number and empty stars;
  - locked: `--locked-surface`, `--card-border`, a lock icon.
  The selected tile gets a 2.2px `--gold` border. Three columns.
- **Level footer:** dark translucent bar with a top border: «المستوى 1 · سهل · 10 أسئلة», the pass mark and
  star thresholds («للاجتياز 7 من 10 · ⭐⭐ 9 · ⭐⭐⭐ 10»), the heart cost, then the gold start button.

## Quiz
- **Top bar:** close button (✕, start side), the counter «سؤال 1 من 10» (`--text-subtitle`, weight 800) with
  points under it in gold, and the timer ring at the end; a thin progress bar below in `--pitch-light`.
- **Timer ring:** `--timer-size` circle, 5px stroke in `--gold` (`--wrong` in the last 5 seconds), seconds in the middle.
- **Question card:** card with small chips (category, difficulty in gold outline) and the question in
  `--text-question`, weight 800.
- **Answer option:** radius `--radius-card`, `--card-surface`, 1.2px `--card-border`, padding 16px × 14px,
  12px apart. A letter badge («أ ب ج د») at the start: `--answer-badge-size` square, radius `--radius-badge`,
  gold at 18% with gold text. Answer text `--text-subtitle` weight 600. After answering:
  - correct: `--correct` at 22% fill, 1.8px `--correct` border, check icon at the end;
  - the wrong pick: `--wrong` at 20% fill, 1.8px `--wrong` border, cross icon;
  - removed by the 50/50 hint: 28% opacity.
- **Feedback panel:** under the answers: verdict («صحيح!» / «خطأ» / «انتهى الوقت!»), the correct answer,
  a short explanation, «أبلغ عن خطأ», and the gold «التالي» button.
- **Hint bar (levels only):** three equal buttons (height `--hint-button-height`, radius `--radius-hint`),
  each a gold icon over a `--text-micro` caption: «حذف إجابتين», «تخطّي السؤال», «وقت إضافي»; then the
  remaining hint count with a bulb. Used or unavailable hints fade and explain why when tapped.

## Status pills and small parts
- **Hearts bar:** pill (`--radius-pill`), `--card-surface` with `--card-border`, a red heart and «3/5»;
  with missing hearts it adds the time to the next heart. Empty: red-tinted with a broken heart.
- **Coin badge:** pill with a gold coin icon and the coin count.
- **Stars:** three small stars, filled `--gold`, empty white at 22%.
- **Chips:** pill buttons for categories; the selected one is `--gold` with dark text.
- **Dialog:** `--card-surface`, radius 28px (Material default), title weight 800, text buttons; destructive
  action in `--wrong`.
- **Snackbar:** floating, `--card-surface`, `--chalk` text.

## Result screen
Rank line at the top (`--text-title`, weight 900), a 200px gold-gradient medal ring with a dark center
showing the score (`--text-score`) and a gold glow (`--shadow-gold-glow`), level stars banner, three stat
tiles, notes (heart earned or lost, streak kept, the daily reminder card), then share (gold), the next
action, and home. Quick play and the daily also list every answer below; levels don't.
