# ASC — resubmitting 1.2.1 after rejecting the version

Situation: version **1.2.1 (build 34)** was rejected by the developer in App Store Connect
in order to change the **description**, and ASC now will not attach build 34 again.

Everything below marked **verified** was checked in this repo on 2026-10-18. The two items
marked **read this in ASC** are the only things that decide which path to take, and nobody
outside your account can see them — there is no App Store Connect API key, fastlane or
Transporter credentials on this machine, so this cannot be inspected or acted on from here.

## Facts established here

| | |
|---|---|
| iOS build number source | `CURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)"` — `ios/Runner.xcodeproj/project.pbxproj:380`, `:566`, `:591`. `FLUTTER_BUILD_NUMBER` is the `+N` in `pubspec.yaml`. |
| pubspec build | `1.2.1+11` on `main` (verified: `git diff --stat v1.2.1 origin/main -- lib/ ios/ pubspec.yaml` is **empty**) |
| ⇒ therefore | ASC showing **34** while pubspec says **+11** means the **Xcode Cloud workflow generates its own build number** (its run counter), not pubspec's. Read it in ASC → your app → **Xcode Cloud** → the workflow → **Build number generation**. This single setting decides which path below works. |
| Export compliance is **not** the blocker | `Info.plist:69-70` sets `ITSAppUsesNonExemptEncryption = false` → the build is exempt, never gets `Missing Compliance`, and Apple's docs list compliance as a reason a build needs action *before submitting*. Ruled out. (`docs/app-store-setup.md` Step 8 claimed `true`; corrected today.) |
| A rebuild is safe here | `main` is identical to tag `v1.2.1` for `lib/`, `ios/` and `pubspec.yaml`. A fresh Xcode Cloud run from `main` produces **the same app**, only a different build string. That is exactly what a metadata-only change needs, and it is why no emulator re-gate is required for it — the code being reviewed already passed the v1.2.1 gate. |

## Step 1 — read the state (one screen, then you know the path)

App Store Connect → **Apps** → mamadera → **iOS iOS 1.2.1** version → scroll to the
**Build** section.

- **A build tile is shown** (icon + `34` + upload date) → Path A.
- **No build, and a `(+)` add button is shown** → Path A too (Apple: the `(+)` appears once
  you have uploaded builds but have not selected one).
- **`(+)` is absent, or the Add Build dialog opens with an empty/short list that omits 34**
  → Path B. Also check **TestFlight** in the sidebar: if 34 is not listed there either, the
  build is gone from what ASC will offer, and no UI trick brings it back.

## Path A — re-select build 34 (no upload, preferred)

Apple's rule, verbatim from *Choose a build to submit*:

> "You can only associate one build with each app version. However, you can change the build
> as often as you want **until you submit the version to App Review**."

1. If a build tile is present, hold the pointer over it and click the **delete (–)** button —
   the `(+)` only appears when nothing is selected. Removing a build from a version does not
   remove it from the account.
2. Click **(+) → Add Build**, pick **34**, **Done**.
3. Edit the description: **App Information** (or the version's **App Store Language**
   localizations), per language.
4. **Save** (top right), then **Submit for Review**.

One trap in the same Apple page: if an earlier version of the app is **Ready for
Distribution**, the Add Build list contains *only builds uploaded since that version
released*. 1.2.0 shipped 2026-10-08 and 34 came after it, so this should not bite — if 34
is missing from the list and TestFlight, that ordering is the thing to check first.

## Path B — the build is genuinely unusable → new build, same code

1. **Xcode Cloud** → the workflow → **Start Build** (or Rerun) on the current `main`
   (`9e61377`, identical to `v1.2.1`).
2. If build number generation is **automatic** → the new run lands as **35**. Wait for
   **Processing** to finish, attach it in the Build section, paste the description, submit.
3. If the new run comes back **as 34 again** (generation pinned to the Xcode default, i.e.
   pubspec's `+11`): ASC refuses duplicate build strings, so bump the build and let the
   workflow rebuild:

   ```bash
   # on main — one line, nothing else
   # pubspec.yaml: version: 1.2.1+11  →  1.2.1+12
   git commit -am "chore(ios): build +12 — ASC refuse un numéro de build dupliqué"
   git push origin main        # triggers Xcode Cloud; the run uploads build 12
   ```
   `+12` is monotonic against Play's `versionCode 11`, so Android is unaffected, and the
   binary is unchanged: only the build string moves.

## Then — make the repo tell the truth again

1. **The new description belongs in `store/source/en/apple-description.txt`** (and
   `play-description.txt` if Play changed too). Those files are the canonical copy; the
   console field is a rendering of them. If the console now holds wording the repo does not,
   the next `--translate` run will overwrite the console with the *old* text and the
   listing will silently revert. Paste the new French/English/Spanish text to me and the
   chain reruns itself: edit source → `python3 scripts/build_store_package.py --translate` →
   `make store-check`.
2. **Record the build identity** in `docs/release-notes/v1.2.1.md` (currently "build 11")
   and in this file: which build actually shipped, and why it moved.
3. `make store-check` before submitting — it catches an over-length description in the
   language you just edited, which is the failure mode of a description written in the ASC
   text box instead of in the source.

## Do not

- Do not delete build 34 from the account trying to make it selectable — deleting removes the
  record of the artifact App Review already looked at.
- Do not change the version string (`1.2.1` stays `1.2.1`) to dodge a duplicate build number;
  bump the **build**, not the version.
- Do not slip a code change into the rebuild. A metadata-only resubmission is fast precisely
  because the binary is the one that passed. Change code and the release gate applies again
  (AGENTS.md), migration and all.
