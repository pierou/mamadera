# `docs/research/` — archive index

Research passes stored here are **evidence, not decisions**. They were paid for in shared-box GPU
time and in web-search quota; the point of archiving them is that nobody re-pays that cost, and that
the `NOT FOUND` markers survive as loudly as the citations.

## Files

| File | Contents | Author |
|---|---|---|
| [`2026-10-05-neonatal-burden.md`](2026-10-05-neonatal-burden.md) | 2024 country rankings (rate **and** absolute), method + the three API traps, **verified local state of the app** | main session, verified hands-on |
| [`2026-10-05-clinical-evidence.md`](2026-10-05-clinical-evidence.md) | causes & timing, WHO practice checklist, IMNCI danger signs, KMC, the three delays, digital-intervention trial results, field platforms, what an app cannot fix | `box-scout`, 8 rounds |
| [`2026-10-05-delivery-feasibility.md`](2026-10-05-delivery-feasibility.md) | devices, gender gap, affordability, APK/Android floor, distribution channels ranked, CHW cadre sizes, literacy & language, adoption precedents, regulatory, funding | `fast-scout`, 1 pass |
| [`../PLAN-francophone-neonatal.md`](../PLAN-francophone-neonatal.md) | the decision document derived from all three | main session |

## Rules for using this archive

1. **A bullet without a URL is not a fact.** Never promote one into an assumption.
2. **`NOT FOUND` is a result, not a blank.** It means *this session could not retrieve it* — not
   *it does not exist*. Reading a gap as a negative finding has already been the failure mode in
   global-health mHealth (see the NASSS barrier analysis, delivery file §6).
3. **Second-hand is labelled.** Every GSMA figure in the delivery file is second-hand because
   `gsma.com` returns 403 from this Mac. Do not launder it into "GSMA says".
4. **Dates are load-bearing.** Literacy figures span 2007–2022; CHW cadre sizes 2018–2021; the
   device survey is July 2020. Do not present them as current.
5. **Reproduce before trusting.** The burden file's Method table re-generates every number from OWID.
   Note the two traps: OWID's neonatal column is **percent ×10**, and the World Bank / WHO APIs
   return HTML error shells from this Mac.

## Open verification items (highest first)

These block decisions. They are cheap and they are not optional.

1. 🔴 **Google Android Developer Verification, 2027** — rests on an advocacy page (`keepandroidopen.org`)
   because Google's docs 302'd to OAuth. If real, it changes *every* non-Play distribution plan.
2. 🔴 **Vitamin D** — the app ships a **daily Vitamin D reminder**; WHO 2022 *Caring for the
   newborn* Rec 36 says vitamin D **in research only**. A live clinical discrepancy in a default
   reminder list, today.
3. 🟠 **IMNCI 0–2 month triage colours** — image-based PDF, never read. No colour-coded triage may
   ship until the chart has been read as an image.
4. 🟠 **Fever threshold conflict** — IMNCI says ≥ 38 °C, WHO PNC 2022 caregiver list says > 37.5 °C.
   Must be resolved with document + page before any temperature guidance.
5. 🟠 **The three WHO multi-country family-integrated KMC trials** — the −32% figure is used in the
   2025 guide but the primary trials were not found this session.
6. 🟡 **Per-country 1 GB price as % of GNI** — A4AI is dead, ITU tables unfetched.
7. 🟡 **Android ≤ 6 share** — unmeasured; StatCounter truncates and measures browser traffic.
8. 🟡 **CHW headcounts for Nigeria, DR Congo, Bangladesh, Pakistan** — all NOT FOUND.

## Session provenance

- 2026-10-05, session on `oMLX` local model. Data pulled by `curl` from OWID (World Bank API and WHO
  GHO Athena both failed). Clinical sweep delegated to `box-scout` (LAN box, CODER profile,
  8 rounds, ~39 min); delivery sweep to `fast-scout` (this Mac, same model as the session).
  Cross-machine fan-out; never two `box-*` agents in one call.
- Local app facts were **verified in the repo by the main session**, not inherited from the agents.
