# PLAN — taking mamadera to the highest neonatal-mortality settings

Status: **proposal, awaiting owner's decision on §2.** Opened 2026-10-05.
Evidence base: [`research/2026-10-05-neonatal-burden.md`](research/2026-10-05-neonatal-burden.md) ·
[`research/2026-10-05-clinical-evidence.md`](research/2026-10-05-clinical-evidence.md) ·
[`research/2026-10-05-delivery-feasibility.md`](research/2026-10-05-delivery-feasibility.md)

---

## 0. The uncomfortable finding, stated first

**mamadera as it exists today cannot reduce neonatal mortality, and shipping it unchanged to
Nigeria, Pakistan or South Sudan would not help a single baby.** Not as rhetoric — as a reading of the
evidence:

1. **It never asks if the baby is sick.** `grep -rniE 'danger sign|triage|referral|seek care' lib/`
   returns one hit, a code comment about *bug* triage. Its four tracking types are
   `{miam, sante, caca, dodo}`. The three killers — prematurity, birth asphyxia, neonatal sepsis —
   are invisible to its data model.
2. **The dominant delay is one software cannot touch.** Pooled over 17 studies / ~3.3 M births,
   **delay level 3 (receiving adequate care) = 38.7%**, vs level 1 (deciding to seek) 28%
   [PubMed 24354747]. In northern Ghana ≤ 25% of babies received IV fluids, antibiotics or oxygen
   *even after care was sought* [33540492]. **No app delivers oxygen, surfactant, IV antibiotics or
   resuscitation.**
3. **Measured digital interventions have never moved mortality.** ImTeCHO: coverage up, **deaths
   unchanged** [31647821]. CLIP: **negative**, aOR 1.17 [32828187]. Jacaranda PROMPTS: +0.09 SD on
   newborn-care knowledge, **zero on danger-sign care-seeking (p=0.096)** [39899612]. Cochrane 2020:
   mortality effect **uncertain** [32813276]. ⇒ *mamadera must never be marketed as saving babies.*
4. **The language does not reach the mother.** Locales are fr/en/es. In the eight highest-rate
   countries adult female literacy is **~19–35%**, and the spoken languages are Hausa, Yoruba, Igbo,
   Pidgin, Urdu, Punjabi, Pashto, Somali, Amharic, Oromo, Lingala, Swahili, Bambara, Wolof, Mooré…
   **Spanish maps to zero target countries.**

So the honest question is not "how do we distribute this app there" but **"what is the smallest thing
this codebase can become that is worth something in those settings, and who has to be involved to
build it."** §3 answers that.

## 1. The one asset nobody has valued yet — computed, not asserted

Running the 2024 OWID/IGME numbers against language (method and reproducible command in the burden
file):

> **Countries where French is official or a principal lingua franca account for 368 485 neonatal
> deaths in 2024 — 16.2% of the global total of 2 271 170 — across 20 countries.**
>
> **Stress-tested, because "francophone" is a contestable category:** strip the four members whose
> French status is debatable or minor (Rwanda, Madagascar, Comoros, Djibouti) and the conservative
> 16-country core is still **336 982 deaths = 14.8% of the global total**. The claim does not depend
> on the marginal cases. *(Computed over `nd_2024.tsv`; recompute with the awk pattern in the burden file
> — note `awk` with `<(...)` process substitution silently returned 0 here on macOS while
> `FILENAME==` matching worked. That is a real trap, not a data problem.)*

| Country | deaths | NMR | | Country | deaths | NMR |
|---|---|---|---|---|---|---|
| DR Congo | 105 425 | 23.6 | | Côte d'Ivoire | 27 601 | 27.4 |
| Niger | 36 634 | **32.8** | | Cameroon | 24 029 | 24.8 |
| Mali | 27 067 | 28.0 | | Madagascar | 23 361 | 23.1 |
| Chad | 26 626 | **30.4** | | Senegal | 11 300 | 20.9 |
| Burkina Faso | 17 516 | 23.8 | | Burundi | 8 890 | 19.1 |
| Guinea | 14 644 | 29.8 | | CAR | 7 362 | **29.9** |
| Benin | 13 130 | 27.2 | | Rwanda | 6 938 | 17.4 |
| Togo | 6 606 | 22.6 | | Haiti | 5 845 | 22.6 |
| Congo | 3 182 | 16.5 | | Djibouti / Gabon / Comoros | 662 / 1 125 / 542 | |

Meanwhile **English** covers Nigeria + Pakistan + Kenya + Uganda + Ghana …, and **Spanish covers none
of them.** The project's existing `app_fr.arb` — the locale its maintainer wrote first, as a
French speaker — is sitting on **one sixth of the global burden**, and it has been treated as one of
three symmetric translation files. It is not. It is the strategic asset.

**Honest qualification, and it is load-bearing:** French is the language of the *health system*, of
clinical records, of the midwife and the CHW — not of the rural mother in Diffa, Tahoua or Kisangani.
So French buys the **frontline-worker layer**, and the mother still needs icons and recorded audio in
Wolof, Bambara, Mooré, Hausa, Lingala, Swahili, Fulfulde. `fast-scout` found **no open-source
speech synthesis for any of those languages** (§5) — meaning audio must be **human-recorded by local
partners**. That single fact determines the shape of §3: **the first user of this app in a
high-burden setting should be the health worker, not the mother.**

## 2. The decision you actually have to make (three options, real costs)

| | Option | What it costs | What it achieves | Verdict |
|---|---|---|---|---|
| **A** | **Distribute as-is** — polish the French/English store listing, push on Play/F-Droid | Low code, high marketing effort | Reaches literate, connected, already-served mothers in Dakar and Abidjan. **Zero contact with the 368 k.** | ❌ Not the stated goal |
| **B** | **Become a frontline perinatal record** — offline French-language maternal-newborn record + WHO danger-sign prompt + referral hand-off, for CHWs/midwives, with a partner supplying local-language audio and clinical sign-off | 2–4 months of code + an institutional partner you do not yet have | Puts the app inside delay level 1 (28%) where software *can* act, in 20 countries / 16.2% of the global burden, on hardware and permissions the project already has | ✅ **Recommended** |
| **C** | **Hand the code to someone who works there** — publish as a digital public good, offer the codebase to Medic/CHT, Jhpiego, a francophone MoH, or Last Mile Health | A week of documentation + a genuine outreach effort | Probably more real impact per hour of your life than B, with none of the control. Also the most honest option if B's partnership doesn't land | ✅ **Do this *alongside* B, not instead** |

**Recommendation: B, with C started the same week.** B without C is a lone developer guessing at
clinical content; C without B is a codebase nobody maintains. Doing both costs the same outreach
email, and C is the fallback if B's gate (§4) doesn't open.

**Explicitly rejected:** chasing **India** (386 k deaths but the rate is 16.7/1k, the mHealth space
is crowded with state-backed apps — ANMOL, Poshan Tracker, e-Sanjeevani, NIKSHAY already stacked on
the same ASHA handset) and chasing **rate-only** countries first (South Sudan 39.5, Somalia 34.2,
CAR 29.9, Guinea-Bissau 32.0, Djibouti 27.1 — tiny counts, active conflict, no CHW partner).
Offline-only is *right* for those places (§5); they are the second wave, not the first.

## 3. What to build — ordered by evidence, not by ambition

### Phase 0 — gate: two verifications and one decision *(days, no code)*
1. 🔴 **Google Android Developer Verification 2027.** The claim that non-Play distribution gets
   blocked from 2027 currently rests on `keepandroidopen.org` because Google's docs 302'd to OAuth.
   **Verify against Google's own documentation before any sideload or F-Droid plan** — if true,
   channel strategy changes completely and the `com.pvjio.mamadera` Google developer account becomes
   mandatory, not optional.
2. 🔴 **The Vitamin D discrepancy.** The app ships a **daily Vitamin D reminder**; WHO 2022 *Caring
   for the newborn* **Rec 36 says vitamin D in research only** (Rec 35 similarly restricts vitamin A
   to NMR > 50/1000 + maternal night blindness ≥ 10%). This is a live clinical claim in a default
   reminder list today. **Remove it from any high-burden build or get it signed off; do not ship it
   to a new country by accident.**
3. **Decide the user: health worker (§2 option B).** Everything below assumes yes.

### Phase 1 — make it deployable *(engineering, zero clinical risk, useful in every market)*
This is the part that is pure software, carries no clinical liability, and is worth doing whatever
option you choose.

| # | Work | Why (evidence) |
|---|---|---|
| 1.1 | **Shrink the APK.** Add `abiFilters` / per-ABI splits or move to AAB; target **< 15 MB**. Currently **60 MB with every ABI bundled** and no `splits` block anywhere | ~35% of Bangladeshi and ~26% of Pakistani connections are non-broadband; low-income 4G *coverage* is **56%** (ITU); where bandwidth eats disposable income, size is *"a severe disincentive"* (IEEE TMC, trim-tmc21) |
| 1.2 | **Consider `minSdk` 21** (Android 5) or justify 24 | floor is API 24 (Android 7, 2016). The share of devices below it is **unmeasured** — StatCounter truncates to top-6 versions and measures browser traffic. **Measure before deciding**, don't guess either way |
| 1.3 | **Real system notifications** (`flutter_local_notifications`) | today reminders are **in-app banners only**; if the mother doesn't open the app, nothing happens. In the first 7 days — **75% of neonatal deaths** — a silent reminder is not an intervention |
| 1.4 | **Battery, 2G and cold-start resilience**; verify on a 2 GB/8 GB profile device, not a simulator | real devices sold in these markets: **Tecno F1 8 GB/1 GB RAM**, Galaxy A10s 32 GB/2 GB |
| 1.5 | **Publish on F-Droid with the real id** — `com.pvjio.mamadera` currently **404**, and `.f-droid/` holds staged metadata that was never submitted | reach is weak (§3 of delivery file) but the cost is near zero — *after* item 1.1 and the verification in Phase 0 |

### Phase 2 — channel *(the real bottleneck, and it is not code)*
Consumer store distribution reaches the wrong people. Ranked by evidenced reach:
1. **Institutional fleet deployment** — the only evidenced route to scale: **Medic/CHT runs open
   source, offline-first, on 182 636 CHWs in 24 countries**; **Last Mile Health ↔ Ethiopia MoH put an
   offline Android app on ~38 000 HEWs**; **India ships an ASHA Mobile App to a million-worker cadre.**
2. **WhatsApp** — South Africa's *government-led* MomConnect runs on it; 86.3% of enrolled women had
   multiple barriers to care. WhatsApp is where the population demonstrably is.
3. **Play** — still the only national-scale *consumer* channel (Android 84–95% of mobile traffic);
   keep it, don't rely on it.
4. **F-Droid / sideload** — weakest; F-Droid's first India event was Oct 2026 and *"many had never
   heard of F-Droid"*, and it calls Google's 2027 verification *"existential"*.

⇒ **Concrete action:** write a 2-page "what this is / what it is not" pack and send it to **Medic**,
**Jhpiego**, **Last Mile Health**, and one francophone implementer (e.g. **PHSD Benin**, **CDS
Mali**, **ANSS Niger** — *names not verified this session, confirm before sending*). Ask a narrow
question: *would you pilot an offline French-language newborn record on your CHW devices?* — and let
them say no.

### Phase 3 — clinical content, GATED behind a partner *(do not do this alone)*
The moment this software advises, it is a clinical instrument. **The proof is in the precedent:**
messaging apps that stayed informational (Mobile Midwife, MomConnect messaging) were evaluated as
communication services; the moment MomConnect embedded **diagnostic decision support** it was tested
with a **physician safety panel, an enrolled cohort, and a ClinicalTrials.gov registration
NCT06790069** [npj Health Systems 2026]. Regulators on the list — **NAFDAC (Nigeria), CDSCO (India),
EFDA (Ethiopia)** — all have live medical-device frameworks; **DRAP and PPB Kenya could not be
verified**, and **no registration fee or timeline was found for software in any of them.**

Gate: no clinical content ships without (a) a named clinical partner, (b) the IMNCI chart read as an
**image** — the triage colours are **NOT extractable** from the PDF and must not be reconstructed
from memory, (c) the **≥ 38 °C vs > 37.5 °C** conflict between IMNCI 2019 and WHO PNC 2022 resolved
to a citation, (d) a written owner decision amending the privacy mandate where it collides (§5).

Then, in this order: **danger-sign recognition → "go now" referral card** (delay level 1 = 28%, the
largest slice software can touch), **thermal care / KMC tracking**, **exclusive breastfeeding support**,
**the 4 PNC contacts of WHO Rec 44 as a checklist the app can actually evidence**.

⚠️ **KMC caution:** WHO 2025 Rec 1–2 — immediate KMC for **all** preterm/LBW newborns, **8–24 h/day**
in facility **or at home**; reported **−32% neonatal mortality, −68% hypothermia**. But the **only
community-only KMC RCT (Sloan 2008, 4 165 births, Bangladesh) was NULL**. The −32% is
*supervised-practice* evidence. **mamadera's episode engine (start/duration/end, already built for
sleep) is the right shape to track skin-to-skin hours** — but it must be wired to a facilitator loop,
not shipped as a reminder to a mother, or it reproduces the null trial.

### Phase 4 — measure process, never mortality
Track **WHO Rec 44 PNC contact coverage**, **KMC hours/day**, **EBF**, **danger-sign recognition on
recall**, **referral completed**. Do **not** design any study, page, or pitch around mortality — §0.3
is why. A coverage number that is real beats an impact number that is unfalsifiable.

## 4. Kill criteria — decide these now, not after you've built it
- No institutional partner replies with a *pilot* by **90 days** → **execute option C properly**:
  publish the code as a digital public good with a real README for health implementers, and stop.
- Partner demands content you cannot get clinically signed off → stop at Phase 1. **Phase 1 alone is
  still a better app for every existing user**, which is the honest consolation prize.
- Verification of item 0.1 shows sideloading dies in 2027 → the whole non-Play channel is void;
  reassess before writing Phase 2 emails, not after.

## 5. The privacy mandate: a limitation in Europe, an advantage in the places on this list

`android/app/src/main/AndroidManifest.xml` has **zero `uses-permission`** — `INTERNET` appears only
in `debug/` and `profile/`. There is **no networking dependency and no sync code** (ROADMAP §0).
**The release build provably cannot phone home.** That is a property, verifiable by anyone with the
APK, and in the countries on this list it is not a constraint to apologise for:

- It works with **no connectivity**, and in a **shutdown/internet-blackout** context.
- It creates **no centralized database of pregnant women** — which in several of these states is a
  physical-safety property for the user, not a philosophy.
- It is the reason offline-first **Medic/CHT** and **Last Mile Health's OppiaAndroid** deployments
  were possible at all in the first place.

**The collision to decide, in the open:** **WHO Rec 55** endorses digital birth notification *only
when individual-level data reaches the health system/CRVS and that system can respond*. A siloed
offline app **fails both conditions by design** and therefore **must not present itself as a
notification channel** (clinical file §8.2). The compromise that respects both: **consent-based,
on-device, point-of-care hand-off** — the worker shows or exports a summary *at the visit*, to a
named human, and the app never transmits anything itself. Note the current JSON export is
**plaintext with notes decrypted** (`export_repository_impl.dart:150-176`) — **handing that file over
WhatsApp is not a safe default** and needs its own decision before Phase 2.

## 6. What happens to this document next
1. Owner reads §2 and picks A / B / C.
2. If B: Phase 0's three items, then §3 Phase 1 as one fat PR series (each item independently
   shippable and testable), then §3 Phase 2 emails.
3. Whatever is decided, the Vitamin D item (§0 in `research/README.md`, §Phase 0.2) is **not**
   deferred behind the decision — it is a clinical claim in today's default reminder list.

**Nothing in this plan may be quoted in a store listing, a pitch deck, or a grant application without
re-opening the source in `research/`.** The gap markers are part of the finding: KMC primary trials,
IMNCI colours, per-country data prices, Android ≤ 6 share, CHW headcounts for Nigeria/DR Congo/
Bangladesh/Pakistan, and every GSMA figure are **second-hand or NOT FOUND**. That is the difference
between a plan and a story.
