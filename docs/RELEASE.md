# Release, environment and Play Console

> Moved from CLAUDE.md on 14 September 2026. Read it when building, shipping, testing on the emulator, or touching Play Console, store assets or the privacy site.

### Publishing identity

| Item | Value |
|---|---|
| Store / developer name | **Oasis Forge** |
| Package name | `com.oasisforge.kooratrivia` — **final, can never change after the first publish** |
| App name on the store | «تحدي كرة القدم» (Arabic is the default listing language) |
| Public contact email | `oasisforge.support@gmail.com` since 18 September 2026 (was `thepromptkitchen@gmail.com`) — the app's feedback and report emails, the privacy policy and Play Console's store contact must all match |
| AdMob | app "Koora Trivia" · publisher `pub-8287765177319119` |
| Privacy policy | https://oasis-forge.github.io/koora-trivia/privacy/ — published from this repo since 18 September 2026. The previous address, https://oasis-forge.github.io/koora-trivia-privacy/, forwards to it (v1.0.8 and earlier open that one). Play Console points to the new address since 18 September 2026 (submitted with the v1.0.8 review) |
| Upload key | `%USERPROFILE%/keys/koora-upload.jks` (alias `upload`) — the password is in `android/key.properties`, outside Git. **Never copy it into any other file.** |
| Repository | https://github.com/Oasis-Forge/koora-trivia — **public**, owned by the **Oasis-Forge organization** (transferred from the `thepromptkitchen-alt` account on 13 September 2026) · branch `main` |

> **Git — what to know:** the repository is **public**, so every file added is visible to
> everyone. The commit identity is local to this repo
> (`The Prompt Kitchen <thepromptkitchen@gmail.com>`) so the owner's personal email doesn't
> appear. Pushes go through the `gh` account (`thepromptkitchen-alt`) with a local credential
> helper — **not** through the owner's personal GitHub account stored in Git Credential
> Manager. `gh` is installed at `C:\Program Files\GitHub CLI\` and may not be on PATH.
> Intentionally excluded in `.gitignore`: `.aab`/`.apk` bundles (`NOTES.md` is kept) ·
> `privacy-site/` (a local clone of the deleted privacy repo, safe to delete) · `key.properties` · `*.jks`.
>
> **Never write the owner's personal name, personal account names, or personal email into
> tracked files.** The owner does not want their name public.

### Play Console status

| Section | Status | Notes |
|---|---|---|
| Developer account registration | ✅ | Shows the legal name and address from the payments profile — see decision ② below |
| App created | ✅ | Game · Free · Arabic default |
| Store settings | ✅ | Category **Trivia** · contact email |
| Store listing | ✅ uploaded | Text from [STORE_LISTING.md](STORE_LISTING.md) · 512 icon · feature graphic · 5 screenshots in the v1.0.6 design. English (en-US) translation with its own 5 screenshots added by the owner with the v1.0.6 upload (14–15 September 2026, in Google's review) |
| AI asset declaration | ✅ | Icon and feature graphic labeled; screenshots are real captures, so not labeled |
| Data safety | ✅ submitted | Updated by the owner on 13 September 2026 to the four types in [DATA_SAFETY_EN.md](DATA_SAFETY_EN.md): Approximate location · App interactions · Diagnostics · Device or other IDs — sent for Google's review |
| Financial · health features | ✅ | None |
| Advertising ID | ✅ Yes | Advertising · analytics · fraud prevention |
| Content rating · target audience | ✅ | Everyone · 13+. App content shows nothing needing attention (checked 13 September 2026) |
| Displayed developer name | ✅ | Set to Oasis Forge by the owner (14 September 2026) |
| Developer verification | ✅ | Play reports all apps registered (deadline 30 September 2026) |
| Privacy policy URL | ✅ | Changed to the oasis-forge.github.io URL by the owner on 13 September 2026. The page itself now carries the PR #5 text (effective 13 September 2026), deployed and checked live the same day |
| Internal testing | ✅ | The crashing versionCode 1 was replaced by the owner (14 September 2026) |
| Closed testing | ✅ running · ⚠️ testers | Track **Alpha**: available since **9 September 2026** with v1.0.3 (versionCode 4), 177 countries; latest upload v1.0.8 (versionCode 9, 18 September 2026, in review). Only **5 of 12** testers opted in (13 September). New personal accounts need **12 testers opted in for 14 consecutive days** before requesting production, so the clock hasn't started |
| Production | ⏳ | |

### In-app products — what the owner creates in Play Console (v1.0.8)

The code ships with the ids below; the shop stays on «قريباً» until Play returns them, so the
order of these steps doesn't matter to the app. **Done by the owner on 18 September 2026** (steps 1–2); each
product has one purchase option `buy`, type Buy, **backwards compatible** — the app's billing library only sees
that one. New products take a few hours to reach devices.

**Testing a purchase:** licence tester signed in, app installed from the Play track, fully restarted. Buy
`coins_small` (+200 coins) and `remove_ads_bundle` (banner gone, +500 coins, the bundle row disappears, Remove ads
reads «مفعّلة»). Then clear the app's data: ads stay off and the 500 coins don't come back. To test `remove_ads` on
its own afterwards, refund the test order in Play Console → Order management and clear the app's data again — the
app never revokes a purchase by itself.

1. **Payments profile** — Setup → Payments profile. Under verification since 17 September 2026;
   nothing can be sold before it is active.
2. **Products** — Monetise → In-app products. Ids exactly: `coins_small` (consumable, 200 coins),
   `remove_ads` (non-consumable) and `remove_ads_bundle` (non-consumable, Remove ads + 500 coins). Owner's
   planned prices: $1.99 · $2.99 · $4.99. **An id can never be
   renamed** — old purchases stop restoring. Set the price per product; Google converts per country.
3. **Licence testers** — Setup → Licence testing: add the tester accounts that should buy without
   being charged. Test purchases need the app installed from a Play track, not a local APK.

### English on Play Console (with v1.0.6)

Done by the owner (14–15 September 2026): steps 1–5 and 8. Left: step 6 (pre-launch report), kept for later.

1. **Listing translation:** Store listings → main listing → Manage translations → add your own → English (United
   States). Paste the name, short and full description from [STORE_LISTING.md](STORE_LISTING.md) — not machine
   translation.
2. **English graphics for that translation:** at least 2 English phone screenshots (the 5 uploaded are Arabic), and
   the English feature graphic `assets/branding/feature_graphic_en_1024x500.png` (Play needs exactly 1024×500;
   `feature_art_1024x500.png` is the same art without text).
3. **Release notes:** paste both the `<ar>` and `<en-US>` blocks from the release's `NOTES.md`.
4. **"Some languages have errors":** after saving, fix or remove any language the Store listings page still flags.
5. **Upload:** v1.0.6 (versionCode 7) to internal, then closed testing. It contains everything in v1.0.5, so v1.0.5
   can be skipped if it was never uploaded.
6. **Pre-launch report:** check crashes and its screenshots, which run in several device languages.
7. **No change needed:** Data safety, content rating, target audience, ads declaration, category, and the privacy
   policy (already in English and Arabic).
8. **Arabic screenshots:** in the default (Arabic) listing, replace the 5 phone screenshots with the v1.0.6-design ones
   in `screenshots/store_9x16/`.

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

> ⚠️ Before v1.0.5 the tool copied whatever `.aab`/`.apk` existed, so a stale build got archived under the new
> version's name (v1.0.2). It now refuses a missing file, a file older than `pubspec.yaml`, an APK whose version
> differs (`aapt2`), and debug-signed or mismatched signing (`apksigner.jar` and `keytool` from Android Studio's
> Java). Still build both.

> ⚠️ `flutter build appbundle --release` exits 1 with "failed to strip debug symbols from native libraries" because the
> SDK's `cmdline-tools` component is missing (see `flutter doctor`). Gradle still builds the bundle: v1.0.7's native
> libraries matched v1.0.6's, which Play accepted. Installing `cmdline-tools` from Android Studio's SDK Manager removes
> the error.

**Forcing an update (from v1.0.6):** leave the in-app update priority at 0 for normal releases — players get the
gentle update. For a crash or data-loss fix, create the release with priority 4 or 5 through the Google Play Developer
API (`inAppUpdatePriority`); the Play Console website can't set it. Details in [HOW_IT_WORKS.md](HOW_IT_WORKS.md).

### Testing on the emulator

- Emulator: `Medium_Phone` (1080×2400, density 420, Play Store image) — replaced `Pixel_6_Pro` in September 2026.
  Launch it: `flutter emulators --launch Medium_Phone`.
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

### Store assets and docs

| File | What it is |
|---|---|
| `assets/branding/play_store_icon_512.png` | Store icon — **full green square to the edges** (Play rounds the corners itself; never upload a pre-rounded icon) |
| `assets/branding/products/` | **In-app product icons** — `coins_small.png`, `remove_ads.png`, `remove_ads_bundle.png`, 1024×1024 32-bit PNG, full green square, no text (Play's rule). Drawn with Pillow in the app's green and gold, 19 September 2026 |
| `assets/branding/app_icon_source.png` | Launcher icon source · `app_icon_foreground.png` for adaptive · `app_icon_cutout.png` transparent cutout |
| `assets/branding/feature_graphic_1024x500.png` | Feature graphic with title · `feature_art.png` raw art without text |
| `screenshots/store_9x16/` | **Arabic screenshots** — 5 × 1080×1920 in the v1.0.6 design, same screens and method as the English set (replaced the pre-redesign set on 14 September 2026) |
| `screenshots/store_9x16_en/` | **English screenshots for the en-US listing** — 5 × 1080×1920 in the v1.0.6 design: home · categories · levels · question · answer feedback (emulator set to 1080×2000 with `adb shell wm size`, status bar cropped, size reset after) |
| `screenshots/store/` | ⚠️ 1440×2975 (ratio 2.07) — **rejected by Play**, don't use |
| [docs/STORE_LISTING.md](STORE_LISTING.md) | App name · short description · full description (Arabic payload) |
| [docs/DATA_SAFETY_EN.md](DATA_SAFETY_EN.md) | Data safety answers in Play Console's English terms, with the AdMob disclosure source |
| [docs/privacy_policy.html](privacy_policy.html) | Privacy policy source (English + Arabic) |
| `docs/app-ads.txt` | Copy of the live https://oasis-forge.github.io/app-ads.txt — edit the live one in the `Oasis-Forge/oasis-forge.github.io` repo |
| [docs/PRE_PUBLISH.md](PRE_PUBLISH.md) | Publishing checklist and verification log |
| [docs/ECONOMY.md](ECONOMY.md) | Economy design — **still in Arabic** |

- The icon and feature graphic were **AI-generated** (Higgsfield) and then processed with PIL —
  hence labeled in Play's declaration. The Arabic title on the feature graphic was drawn with PIL
  plus `arabic_reshaper` and `python-bidi` (generators garble Arabic script).
- **The Oasis Forge root site** (https://oasis-forge.github.io: home page and the one `app-ads.txt` for every app) is
  the `Oasis-Forge/oasis-forge.github.io` repo, cloned next to this project in `App Project/oasis-forge.github.io`, with
  the same local `gh` credential helper. Don't rename it: the address depends on the repo name.
- **The privacy policy is published from this repo** (since 18 September 2026, owner's decision; the separate
  `koora-trivia-privacy` repo was deleted the same day). `docs/privacy_policy.html` is the only copy: merging a change to it
  on `main` runs `.github/workflows/privacy-pages.yml`, which publishes that page alone (not the rest of
  `docs/`) to GitHub Pages at https://oasis-forge.github.io/koora-trivia/privacy/. Pages on this repo uses
  "GitHub Actions" as its source.
- **The old address forwards.** `https://oasis-forge.github.io/koora-trivia-privacy/` is now a forwarding page
  in the root site repo (`koora-trivia-privacy/index.html` in `oasis-forge.github.io`) — v1.0.8 and earlier
  still open it from Settings. It only works while no repo named `koora-trivia-privacy` publishes Pages;
  **never create a repo with that name again.** ⚠️ **Renaming this repo changes the policy URL** — update `AppConfig.privacyPolicyUrl`,
  Play Console and the home page link together.
