# Data Safety — ready answers for Play Console (English)

> The Data Safety form is mandatory in Play Console and filled in by hand there
> (it is not generated from code). These answers reflect the app's actual behavior.
> **Revisit them whenever you enable a new feature that collects data** (e.g. cloud
> save or sign-in). Arabic copy: [DATA_SAFETY.md](DATA_SAFETY.md).

## Current app behavior

- All progress is stored locally in `SharedPreferences` — no server, no account.
- The app connects to the internet **only** to load AdMob ads.
- AdMob collects the Advertising ID and device/interaction data to serve ads.

---

## A. Data collection and sharing

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** (because of AdMob) |

> If ads were disabled at launch, the answer would be **No** and the disclosure
> empty. Since ads are built and enabled, the answer is Yes.

## B. Data types — what to disclose (due to AdMob)

| Data type | Collected? | Shared? | Purpose | Required/Optional |
|---|---|---|---|---|
| **Device or other IDs** | Yes | Yes | Advertising or marketing · Analytics | Required |
| **App activity / performance** (diagnostics/crash) | Optional* | — | Analytics | — |

\* Only mark "Crash logs / Diagnostics" if you actually use crash reporting. The app
currently does not, so leave it unchecked.

> **Do NOT select:** Location, Personal info, Contacts, Messages, Photos/videos,
> Files, Health, Financial info — none of these are collected.

## C. Security practices

| Question | Answer |
|---|---|
| Is data encrypted in transit? | **Yes** (AdMob traffic is over HTTPS) |
| Can users request that their data be deleted? | The Advertising ID is controlled from device settings; we store no user data ourselves. |
| Is your app directed at children? | **No** — general audience, not targeted at under-13. |

## D. How the form maps to the Data Safety UI (step by step)

1. **Data collection and security**
   - "Does your app collect or share any of the required user data types?" → **Yes**
   - "Is all of the user data collected by your app encrypted in transit?" → **Yes**
   - "Do you provide a way for users to request that their data is deleted?" → you may
     select **No** (no user data is stored server-side; ad ID is device-controlled).
2. **Data types** → expand **Device or other IDs** → check **Device or other IDs**.
   Leave every other category unchecked.
3. For **Device or other IDs**, set:
   - Collected: **Yes** · Shared: **Yes**
   - Processed ephemerally: **No**
   - Required or optional: **Required** (data collection is required to use the app's ads)
   - Purposes: **Advertising or marketing**, **Analytics**
4. **Preview and submit.**

## E. Privacy policy URL (required field)

```
https://thepromptkitchen-alt.github.io/koora-trivia-privacy/
```

---

## Important note when the decision changes

- **If you launch without ads** (temporarily disabling AdMob): the disclosure becomes
  "No data collected" — the strongest marketing point and the simplest possible form.
  But since ads are part of the revenue model, keeping them is the likely choice.
- **When you later add cloud save / accounts:** the disclosure changes substantially
  (user ID, email, progress stored on a server). Update this file and the form together.
