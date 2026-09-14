# Release, environment and Play Console

> Moved from CLAUDE.md on 14 September 2026. Read it when building, shipping, testing on the emulator, or touching Play Console, store assets or the privacy site.

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
| Store listing | ✅ uploaded | Text from [STORE_LISTING.md](STORE_LISTING.md) · 512 icon · feature graphic · 5 screenshots (Arabic). English (en-US) translation still to add with v1.0.6 — see "English on Play Console" below |
| AI asset declaration | ✅ | Icon and feature graphic labeled; screenshots are real captures, so not labeled |
| Data safety | ✅ submitted | Updated by the owner on 13 September 2026 to the four types in [DATA_SAFETY_EN.md](DATA_SAFETY_EN.md): Approximate location · App interactions · Diagnostics · Device or other IDs — sent for Google's review |
| Financial · health features | ✅ | None |
| Advertising ID | ✅ Yes | Advertising · analytics · fraud prevention |
| Content rating · target audience | ✅ | Everyone · 13+. App content shows nothing needing attention (checked 13 September 2026) |
| Displayed developer name | ✅ | Set to Oasis Forge by the owner (14 September 2026) |
| Developer verification | ✅ | Play reports all apps registered (deadline 30 September 2026) |
| Privacy policy URL | ✅ | Changed to the oasis-forge.github.io URL by the owner on 13 September 2026. The page itself now carries the PR #5 text (effective 13 September 2026), deployed and checked live the same day |
| Internal testing | ✅ | The crashing versionCode 1 was replaced by the owner (14 September 2026) |
| Closed testing | ✅ running · ⚠️ testers | Track **Alpha**: v1.0.3 (versionCode 4), available since **9 September 2026**, 177 countries. Only **5 of 12** testers opted in (13 September). New personal accounts need **12 testers opted in for 14 consecutive days** before requesting production, so the clock hasn't started |
| Production | ⏳ | |

### English on Play Console (with v1.0.6)

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
| `assets/branding/app_icon_source.png` | Launcher icon source · `app_icon_foreground.png` for adaptive · `app_icon_cutout.png` transparent cutout |
| `assets/branding/feature_graphic_1024x500.png` | Feature graphic with title · `feature_art.png` raw art without text |
| `screenshots/store_9x16/` | **The uploaded screenshots (Arabic)** — 5 × 1080×1920, still the design before v1.0.6 |
| `screenshots/store_9x16_en/` | **English screenshots for the en-US listing** — 5 × 1080×1920 in the v1.0.6 design: home · categories · levels · question · answer feedback (emulator set to 1080×2000 with `adb shell wm size`, status bar cropped, size reset after) |
| `screenshots/store/` | ⚠️ 1440×2975 (ratio 2.07) — **rejected by Play**, don't use |
| [docs/STORE_LISTING.md](STORE_LISTING.md) | App name · short description · full description (Arabic payload) |
| [docs/DATA_SAFETY_EN.md](DATA_SAFETY_EN.md) | Data safety answers in Play Console's English terms, with the AdMob disclosure source |
| [docs/privacy_policy.html](privacy_policy.html) | Privacy policy source (English + Arabic) |
| `docs/app-ads.txt` | Ready, **not published** (needs a root domain) |
| [docs/PRE_PUBLISH.md](PRE_PUBLISH.md) | Publishing checklist and verification log |
| [docs/ECONOMY.md](ECONOMY.md) | Economy design — **still in Arabic** |

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
