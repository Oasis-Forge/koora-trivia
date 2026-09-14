# Design sync notes — Koora Trivia

- **Tokens-only by design.** The app is Flutter; the design-sync converter only ships real React components and
  forbids rebuilding widgets as web lookalikes. The package `design-system/` has an empty entry
  (`index.js`, `index.d.ts`) so the converter takes its tokens-only path.
- **Sources:** `design-system/styles/tokens.css` (the `cssEntry`) is hand-copied from
  `lib/core/theme/app_colors.dart`, `lib/core/theme/app_theme.dart` and sizes used in `lib/presentation`.
  Guidelines are `design-system/overview.md` and `design-system/components.md`, copied via `guidelinesGlob` to
  `guidelines/` (the converter keeps the package-relative path, so they sit at the package root).
- **Screenshots need a post-build step:** the converter copies only `.md/.mdx` guidelines, so after every build run
  `node .design-sync/add-screens.mjs`. It copies `design-system/screens/*.png` to `guidelines/screens/` and refreshes
  `auxSha` in `_ds_sync.json`. Skipping it uploads no screenshots and the re-sync diff drops them from the project.
- **Build log noise:** `[DTS_REACT]` and `[ZERO_MATCH]` are expected — there are no components, so no React types are needed.
- **Render check:** a tokens-only bundle has no preview cards, so validate runs with `--no-render-check` (owner's OK,
  14 September 2026).
- **Build:** `node .ds-sync/package-build.mjs --config .design-sync/config.json --node-modules .ds-sync/node_modules --entry ./design-system/index.js --out ./ds-bundle`,
  then `node .ds-sync/package-validate.mjs ./ds-bundle`.
- **Font:** the app uses the Android system font; `tokens.css` loads Noto Sans Arabic from Google Fonts as the web
  match (remote `@import`).
- **Screenshots:** `design-system/screens/*.png` (540 × 1200) were captured on the `Medium_Phone` emulator on
  14 September 2026 with the blue theme, from the v1.0.6 development build.

## Re-sync risks
- `tokens.css` and `components.md` go stale whenever `app_colors.dart`, `app_theme.dart` or a widget's sizes change —
  re-copy the values before re-syncing.
- Screenshots age with every UI change; recapture after the redesign lands.
- Noto Sans Arabic is a substitute for the device font and loads from the network.
