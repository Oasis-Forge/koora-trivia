# Data Safety — ready answers for Play Console (English)

> The Data Safety form is mandatory in Play Console and filled in by hand there
> (it is not generated from code). These answers reflect the app's actual behavior.
> **Revisit them whenever you add a feature that collects data** (cloud save, sign-in,
> crash reporting, analytics).
>
> The AdMob rows follow Google's
> [Google Mobile Ads SDK data disclosure](https://developers.google.com/admob/android/privacy/play-data-disclosure)
> page, checked 13 September 2026. Re-check it whenever `google_mobile_ads` is upgraded.

## Current app behavior

- All progress is stored locally in `SharedPreferences` — no server, no account. Android backup
  may copy it into the user's own Google account backup; we never receive it.
- The app itself sends nothing anywhere. The internet is used by the AdMob SDK (ads) and Google's
  UMP consent form.
- No ad is requested, and the ads SDK isn't initialized, until Google's consent check allows it
  (`canRequestAds`).
- The AdMob SDK automatically collects and shares: the IP address (used to estimate approximate
  location), user product interactions, diagnostic information, and device identifiers
  (Android Advertising ID, app set ID).

---

## A. Data collection and security

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** (because of the AdMob SDK) |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (TLS) |
| Which methods of account creation does your app support? | **My app does not allow users to create an account** |
| Do you provide a way for users to request that their data is deleted? | **No** — we store nothing server-side; the Advertising ID is reset or deleted from device settings |

## B. Data types — what to disclose (all because of AdMob)

Answer **every row the same way**: Collected **Yes** · Shared **Yes** · Processed ephemerally
**No** · **Required** · Purposes, for both collection and sharing: **Advertising or marketing**,
**Analytics**, **Fraud prevention, security, and compliance**.

| Play category | Data type to check | What AdMob collects |
|---|---|---|
| Location | **Approximate location** | IP address, used to estimate general location |
| App activity | **App interactions** | App launches, taps, video views |
| App info and performance | **Diagnostics** | App launch time, hang rate, energy usage |
| Device or other IDs | **Device or other IDs** | Android Advertising ID, app set ID |

> **Do NOT select:** Precise location · Personal info · Financial info · Health and fitness ·
> Messages · Photos and videos · Audio · Files and docs · Calendar · Contacts · Web browsing ·
> any App activity type other than App interactions · **Crash logs**. None are collected.
> Crash logs becomes Yes only if a crash-reporting tool (e.g. Crashlytics) is added.

## C. Other answers

| Question | Answer |
|---|---|
| Is your app directed at children? | **No** — general audience, not targeted at under-13 |

## D. Step by step in the Play Console UI

1. **Data collection and security** → the four answers in table A.
2. **Data types** → check exactly the four types in table B, nothing else.
3. For **each** of the four types: Collected and Shared **Yes** · ephemeral **No** · **Required** ·
   the three purposes for collection and again for sharing.
4. **Preview** — the summary should list Location, App activity, App info and performance, and
   Device or other IDs — then **Submit**.

## E. Privacy policy URL (required field)

```
https://oasis-forge.github.io/koora-trivia/privacy/
```

(Since 18 September 2026. The previous address, `/koora-trivia-privacy/`, forwards here.)

---

## When a decision changes

- **Crash reporting or analytics (e.g. Firebase):** adds Crash logs and more App activity types.
  Update this file, [PRE_PUBLISH.md](PRE_PUBLISH.md) and the privacy policy together.
- **Cloud save or accounts:** adds user IDs and server-stored progress, and "request deletion"
  becomes Yes.
