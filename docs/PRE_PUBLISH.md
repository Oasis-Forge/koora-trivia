# Pre-publish checklist — Koora Trivia (تحدي كرة القدم)

Last full check: **13 September 2026** · Latest build: **v1.0.3+4**

> Per-section Play Console status and the next steps live in **"Current status"** at the
> top of [CLAUDE.md](../CLAUDE.md). This file keeps the details: what was verified, what
> was entered in each form, the release procedure, and what's left before production.

---

## 1. Verification status

### Automated

| Check | Result |
|---|---|
| `flutter analyze` | ✅ clean |
| `flutter test` | ✅ **137 / 137** across 15 files |
| `flutter build appbundle --release` | ✅ ≈57 MB (the *strip debug symbols* warning is non-fatal) |
| `flutter build apk --release` | ✅ ≈60 MB |
| Release signing | ✅ `CN=Oasis Forge`, not the debug key |
| ABIs | ✅ `arm64-v8a` · `armeabi-v7a` · `x86_64` |

### On the emulator, release build (8 September 2026)

| Flow | Result |
|---|---|
| Launch | ✅ (after turning R8 off) |
| Onboarding · home · categories · level grid | ✅ |
| Question · timer · time-up · correct-answer highlight · explanation | ✅ |
| Pass a level at 7/10 | ✅ one star · "level passed" · "next level unlocked" · Next Level button |
| Fail a level | ✅ empty-stars banner · Replay Level button |
| Level grid after passing | ✅ 1/10 complete · level 2 unlocked, the rest locked |
| Answer review · share | ✅ share sheet opens |
| Heart deduction · no-hearts dialog · regen countdown | ✅ |
| Rewarded ad (test ad) | ✅ loads, plays, and **grants the heart** (0 → 1) |
| Daily challenge | ✅ grants a heart and the streak · no replay button · card disabled with countdown |
| Settings · daily tasks · shop | ✅ render |
| State survives a restart | ✅ hearts and rounds played |

### On the emulator (13 September 2026)

| Flow | Build | Result |
|---|---|---|
| EEA consent form | debug, `--dart-define=UMP_DEBUG_EEA=true`, app data cleared | ✅ Google's consent form appears at launch, after the AdMob European regulations message was published |
| Settings → «الخصوصية» | same | ✅ «خيارات خصوصية الإعلانات» and «سياسة الخصوصية» rows show |
| Reminder scheduling | release (PR #6) | ✅ enabling the toggle schedules 7 one-shot alarms, one per day at 20:00, through `ScheduledNotificationReceiver` |
| Reminder after a reboot | release | ✅ all 7 alarms re-registered without opening the app |
| Reminder fires | release, clock moved past 20:00 the next day | ✅ «تحدي اليوم بانتظارك ⚽» · «العب الآن — 7 أسئلة فقط!» · white football status-bar icon · channel `daily_challenge` |
| Reminder, final PR #6 build | release, reboot, then clock moved two days ahead | ✅ 7 alarms before and after reboot · days 1 and 2 fired (ids 1001, 1002) · the other 5 stay scheduled · no crash |
| Tomorrow one-shot + daily-repeating reminder (design tried, dropped) | release | ❌ the plugin armed the repeating one for the next 20:00, ignoring its date, so both fired the same day |
| Level grid, emulated 360×640 | release (PR #7) | ✅ all ten levels above «ابدأ المستوى» |
| Quiz screen, emulated 360×640 | release | ✅ question and all four options above the hints bar |
| Skip hint, emulated 360×640 | release | ✅ «تخطّيت هذا السؤال» in gold with the correct answer · the panel scrolls fully above «التالي» · the result review row shows a skip icon |
| Quiz screen and level grid at the Pixel 6 Pro's own size | release | ✅ options directly above the hints bar, no gap · level grid looks as before |
| Release launch with PRs #5 and #6 | release | ✅ no crash · an ad is requested at launch |

To re-run the EEA check: clear the app's data, then `flutter run --dart-define=UMP_DEBUG_EEA=true`
(ignored in release builds). To make a reminder fire without waiting: `adb shell settings put global
auto_time 0`, then `adb shell cmd alarm set-time <epoch ms>` more than an hour past the reminder time
(inexact alarms have a one-hour window), and set `auto_time` back to 1 afterwards. To emulate a 360×640 phone: `adb shell wm size 1080x1920`
and `adb shell wm density 480`; undo with `adb shell wm size reset` and `adb shell wm density reset`.

### Not verified yet

- **A real phone** — everything above was on the emulator.
- Tapping «خيارات خصوصية الإعلانات» opens the form, and the rewarded button enables by itself once
  the ad loads, in the EEA simulation.
- The reminder's streak text on a day with a streak, and skipping today after finishing the daily
  (covered by `plan_reminders_test` and `reminder_test`, not yet seen on a device).
- Progress export/import on a device (the logic is covered by `backup_test`).
- Buying from the shop with real coins · the shop's rewarded ad (+70).
- Real production ads — **never tap them yourself**.
- Tablet layouts.

---

## 2. Release procedure

1. Bump `version` in `pubspec.yaml` (`1.0.3+4` ⇒ next is `1.0.4+5`).
2. `flutter analyze` and `flutter test`.
3. `flutter build appbundle --release` **then** `flutter build apk --release` — always both.
4. `adb uninstall com.oasisforge.kooratrivia` → install the APK → exercise the affected flow.
5. `dart run tool/archive_release.dart "reason"` → creates `releases/v<version>_<date>/`.
6. Upload `app-release.aab` from the archive folder to the target track in Play Console.

**Release notes template** (the payload is Arabic because players see it; it deliberately
mentions no fixed counts):

```
<ar>
الإصدار الأول من «تحدي كرة القدم» 🎉
• ثلاثة أنماط: المستويات، اللعب السريع، وتحدي اليوم.
• تصنيفات متنوّعة ومستويات تتصاعد صعوبتها.
• سلسلة أيام، نجوم، ومهامّ يومية.
نتمنّى لك اللعب الممتع — رأيك يهمّنا!
</ar>
```

### Version history

| Version | Contents |
|---|---|
| `1.0.0+1` | Generic onboarding copy · 3-column level grid · rewarded-ad fix. First internal-testing upload — **crashes on launch** (R8) |
| `1.0.1+2` | R8 turned off, nothing else |
| `1.0.2+3` | Covariance bug fix (stars · level unlocks · Next Level button) |
| `1.0.3+4` | + replay button hidden after the daily challenge ← **latest** |

> ⚠️ In `releases/v1.0.1_build2_*` the `.apk` is **versionCode 1** (built two minutes before
> the version bump) while the `.aab` is correct. Verified with `aapt2 dump badging`; the
> v1.0.2 and v1.0.3 folders match. See the archive-tool trap in CLAUDE.md.

---

## 3. What was entered in Play Console

### App creation and store settings
- Name «تحدي كرة القدم» · default language Arabic · Game · Free.
- Package `com.oasisforge.kooratrivia`.
- Category **Trivia** · contact email `thepromptkitchen@gmail.com` · phone left blank ·
  external marketing left on (default).

### Store listing
- Text: [STORE_LISTING.md](STORE_LISTING.md).
- App icon: `assets/branding/play_store_icon_512.png` — full square, no pre-rounded corners.
- Feature graphic: `assets/branding/feature_graphic_1024x500.png`.
- Phone screenshots: `screenshots/store_9x16/` (5 × 1080×1920). **Not** `screenshots/store/`
  — its 2.07 aspect ratio exceeds Play's limit.
- ⚠️ A "Some languages have errors" warning appeared with only one language and was never
  resolved — open the listing's **Review** step to read the actual error.

### AI asset declaration
"Label assets as created or edited using AI" → label the **app icon** and the **feature
graphic** only. The screenshots are real captures of the app, so they are not labeled.

### Data safety
Full answers in [DATA_SAFETY_EN.md](DATA_SAFETY_EN.md). Summary:
- Collects or shares data: **Yes** (because of AdMob) · encrypted in transit: **Yes**.
- Account creation: **My app does not allow users to create an account**.
- Four data types, each collected and shared · not ephemeral · required · purposes: advertising ·
  analytics · fraud prevention, security, and compliance: **Approximate location** (IP address) ·
  **App interactions** · **Diagnostics** · **Device or other IDs**.
- Do **not** select Crash logs — no crash-reporting tool is used.
- ⚠️ Until 13 September 2026 the live form declared only Device or other IDs. **The owner must
  update the form in Play Console** — editing this file doesn't change it.

### Advertising ID
**Yes** — purposes: Advertising or marketing · Analytics · Fraud prevention, security, and
compliance. The `AD_ID` permission is merged in automatically from the ads SDK.

### Merged permissions — verified on v1.0.3 with `aapt2`
The source manifest declares only `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED`. The rest
are merged in from packages (AdMob · WorkManager · notifications): `INTERNET` ·
`ACCESS_NETWORK_STATE` · `AD_ID` · `ACCESS_ADSERVICES_AD_ID` · `ACCESS_ADSERVICES_ATTRIBUTION` ·
`ACCESS_ADSERVICES_TOPICS` · `WAKE_LOCK` · `FOREGROUND_SERVICE` · `VIBRATE`. targetSdk = 36.

**Foreground service permissions form:** the five merged services (AdMob's `AdService` · three
from WorkManager including `SystemForegroundService` · Room's service) **none declares a
`foregroundServiceType`**, and there are no type-specific `FOREGROUND_SERVICE_*` permissions —
so Play shouldn't ask for it. If it does: the source is WorkManager, pulled in by AdMob, and the
app itself never starts a foreground service.

### Financial and health features
"My app doesn't provide any financial features" · "My app does not have any health features".
In-game coins are not a financial feature.

### Content rating — ✅ done
Play Console → App content shows nothing needing attention (checked 13 September 2026).
Category **Game**; "No" to every violence, sexual content, drugs, gambling, and profanity
question. Sharing through the system share sheet is not in-app user-to-user interaction.
Expected result: Everyone / PEGI 3.

### Target audience — ✅ done
**13 and over**, and "No" to appealing to children — matches the privacy policy. Choosing ages
under 13 puts the app under the Families policy and requires child-directed ad settings.

---

## 4. Closed testing — the gate to production

> **Status (13 September 2026):** track **Alpha** is live with v1.0.3 (versionCode 4) since
> 9 September, in 177 countries — steps 1–2 below are done. Only **5 of 12** testers have opted in,
> so the 14-day clock hasn't started; the job now is getting 7+ more testers through step 4.

New **personal** developer accounts can't request production until a closed test has run with
**at least 12 testers opted in for 14 consecutive days**. Internal testing **does not count**.

1. Test and release → Testing → **Closed testing** → create the track.
2. Upload the latest `.aab` and add the testers' email list (Google accounts).
3. Copy the opt-in link and send it.
4. Each tester: signs the phone into **the same account** that was added → opens the link →
   "Become a tester" → installs from Play. The app can take minutes to hours to appear after
   rollout.

**Ready-to-send invite** (Arabic, for the testers):

```
جرّب لعبتي الجديدة «تحدي كرة القدم» ⚽

1) افتح رابط الانضمام من هاتف أندرويد: [الصق رابط الـ opt-in هنا]
2) اضغط "Become a tester" ثم حمّل التطبيق من متجر Play.
3) العب واخبرني برأيك 🙏

مهم: ابقَ منضمّاً لمدة أسبوعين على الأقل — غوغل تشترط ذلك قبل النشر العام.
```

---

## 5. Before requesting production

### Owner decisions
- **Heart deduction** — one failed attempt drains all five hearts (observed). Proposal: one
  heart per failed attempt instead of per wrong answer.
- **Name and address shown publicly** — a personal account shows the legal name and address
  from the payments profile on the store page. The alternative is an organization account
  (D-U-N-S). At minimum set "Developer name" to Oasis Forge and use a non-home address if
  possible. **Check Google's current requirement** before deciding — the rules change.

### Reviews
- **Audit bugs visible in Arabic today:** the daily challenge repeats every other day, wrong count
  grammar («N يوم متتالية», «N نجمة»), raw exception text in a SnackBar, and a stale version string.
  Details in [I18N_PLAN.md §0](I18N_PLAN.md) and CLAUDE.md "Remaining §0".
- **Question accuracy:** 1000 questions written from knowledge up to May 2026, never reviewed
  by a human. Historical questions are safe; any recent record deserves a check. Start with
  levels 9–10.
- **Level 10 difficulty:** highly specialized questions (the Guttmann curse, Steaua's 1986
  penalties) may frustrate.
- **Tuning on a phone:** 20-second question timer · 30-minute regen · 3 free hints a day.
- **Quiz screen on tall devices:** possible gap between the last option and the hints bar.

---

## 6. Not built — deliberately or deferred

| Item | Status |
|---|---|
| In-app purchases | Not built; "Remove ads" shows "Soon". ⚠️ Consumables must be acknowledged within 3 days |
| Interstitial ads | Built, deliberately off at launch |
| `app-ads.txt` | Ready in `docs/`, not published (needs a root domain) |
| Tablet screenshots | None |
| Splash screen | Still uses the old `ic_ball` drawing |
| iOS | Out of scope |
| Multiple languages | Deliberately deferred — plan and audit in [I18N_PLAN.md](I18N_PLAN.md) |
| Cloud save · leaderboards · Play Games | Deferred (see next section) |

---

## 7. Local-only storage — a decided trade-off

**Decision:** no cloud save, no sign-in, no server. All progress lives in `SharedPreferences`.

**Gains:** the simplest possible Data safety disclosure · no infrastructure cost · no sign-in screen.

**Losses:** uninstalling, switching phones, or clearing data = losing everything · no
leaderboards · no Play Games achievements · no sync between devices.

**Safety nets:** manual export/import with a Base64 code from Settings (built) · Android auto
backup enabled via `backup_rules.xml` and `data_extraction_rules.xml` to include `sharedpref` —
but it's unreliable (roughly once a day, restores only on a fresh install).

### Moving to Firebase later — what not to break

1. **The abstract contracts are the storage gateway.** `StatsRepository`, `ProgressRepository`,
   `EconomyRepository`, and `SettingsRepository` are abstract interfaces; migrating means a new
   implementation of each **without touching any Provider or screen**. Never call
   `SharedPreferences` from the presentation layer.
2. **Storage keys are versioned** (`user_stats_v1` … `economy_v1`) — keep the convention.
3. **Adopting local progress is mandatory when accounts arrive** — the first sign-in uploads the
   existing progress rather than replacing it with an empty account.
4. **Times are device-local today.** `lastRegenAtIso` and day keys depend on the device clock;
   a server will need UTC.

> ⚠️ All values are computed on-device and untrusted. **Migrated data can't be trusted
> retroactively** — anyone who changed their clock arrives with fake progress. If leaderboards
> come, start counting from zero.

### The clock exploit
Streaks and hearts rely on the device clock: moving the date forward grants hearts and breaks
streak logic. The current guard only rejects backward jumps. The real fix needs a server —
acceptable for the first release.
