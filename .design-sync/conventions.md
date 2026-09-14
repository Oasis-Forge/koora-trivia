# Koora Trivia («تحدي كرة القدم») — building with this design system

**This is a tokens-only design system.** The real app is Flutter, so there are no importable components:
build every screen yourself with plain HTML/JSX styled by the CSS variables below. Everything you need is in
`styles.css` (its `@import` closure defines every variable) and in `guidelines/overview.md`,
`guidelines/components.md` and the screenshots in `guidelines/screens/`. Read those before styling.

## Setup
- Portrait phone frame, 360–412 px wide. Dark only.
- Arabic, right to left: `<html dir="rtl" lang="ar" data-theme="green">`. `styles.css` already sets
  `direction: rtl` and the font on the page.
- `data-theme` picks the colors: `green` (default), `blue`, `purple`, `red`. Without it you get green.
- Paint screens on `background: var(--pitch-gradient)`.

## Token vocabulary (use these, never raw hex)
- **Colors:** `--pitch-dark`, `--pitch-deep`, `--pitch-mid`, `--pitch-light`, `--card-surface`,
  `--card-border`, `--gold`, `--gold-deep`, `--chalk`, `--chalk-muted`, `--correct`, `--wrong`,
  `--pitch-stripe`, `--pitch-line`, `--locked-surface`, `--pitch-gradient`, `--gold-gradient`.
- **Type:** `--font-family`; sizes `--text-score` 46, `--text-headline` 24, `--text-title` 22,
  `--text-question` 21, `--text-level` 20, `--text-button` 18, `--text-section` 17, `--text-subtitle` 16,
  `--text-label` 15, `--text-body` 14.5, `--text-meta` 13, `--text-caption` 12, `--text-micro` 10.5;
  weights `--weight-regular`, `--weight-semibold`, `--weight-bold`, `--weight-extrabold` (most text),
  `--weight-black` (titles).
- **Shape:** `--radius-pill`, `--radius-card`, `--radius-button`, `--radius-tile`, `--radius-hint`,
  `--radius-badge`; `--border-card`, `--border-outlined`; `--shadow-gold-glow`.
- **Size and space:** `--button-height`, `--hint-button-height`, `--timer-size`, `--answer-badge-size`;
  `--space-page` 20, `--space-section` 26, `--space-card` 14, `--space-lg` 16, `--space-md` 12,
  `--space-sm` 8, `--space-xs` 4.

## Meaning of color
Gold = the main action, stars, points, selection. Green (`--correct`) = right answer. Red (`--wrong`) =
wrong answer, lost heart, destructive action. Cards sit on `--card-surface` with `--border-card`.

## Example
```jsx
<main style={{ minHeight: '100vh', background: 'var(--pitch-gradient)', padding: '0 var(--space-page)' }}>
  <section style={{ background: 'var(--card-surface)', border: 'var(--border-card)', borderRadius: 'var(--radius-card)', padding: 'var(--space-card)' }}>
    <h2 style={{ fontSize: 'var(--text-title)', fontWeight: 'var(--weight-black)', margin: 0 }}>تحدي اليوم</h2>
    <p style={{ color: 'var(--chalk-muted)', fontSize: 'var(--text-meta)' }}>7 أسئلة • نقاط مضاعفة ×1.5</p>
  </section>
  <button style={{ width: '100%', height: 'var(--button-height)', marginTop: 'var(--space-section)', background: 'var(--gold)', color: 'var(--pitch-dark)', border: 0, borderRadius: 'var(--radius-button)', fontFamily: 'inherit', fontSize: 'var(--text-button)', fontWeight: 'var(--weight-bold)' }}>
    لعب سريع ⚽
  </button>
</main>
```
Button icons go on the left of the label (after the text in right-to-left).
