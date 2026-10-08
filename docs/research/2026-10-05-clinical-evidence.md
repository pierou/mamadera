# Clinical & intervention evidence — newborn survival

Gathered 2026-10-05 by `box-scout` (read-only pass, 8 rounds) over WHO IRIS, PubMed, Lancet,
Cochrane. Reproduced here as **evidence, not decision** — every claim carries its source; the
`NOT FOUND` markers are part of the result and must not be quietly dropped later.

> **Reading rule for this file:** a bullet with a URL is a sourced fact. A bullet marked
> **NOT FOUND** means the primary text could not be retrieved *in that session* — it does **not**
> mean the thing doesn't exist. Never promote a NOT FOUND into an assumption, and never let a
> later reader infer a number that isn't printed here.

## 1. Causes & timing of neonatal death

- 2.3 M neonatal deaths (0–27 d) in 2022; **~1 M in the first 24 h**; **75% in the first week**;
  neonatal = **47% of under-5 deaths**; NMR −44% since 2000 (18.6 → 10.4/1000); SSA NMR 27/1000,
  central & South Asia 21/1000; **64 countries will miss SDG < 12/1000 by 2030** —
  <https://www.who.int/news-room/fact-sheets/detail/newborn-mortality>
- Leading causes: **complications of preterm birth, intrapartum-related events (birth asphyxia),
  neonatal sepsis/pneumonia**; congenital anomalies fourth. **~20 M low-birth-weight babies/year;
  > 80% of neonatal deaths occur in LBW infants, > half of those preterm** — Lawn J, *Neonatology*
  2023;120(4):491 (read from local extract `/tmp/lawn2023.txt`; **DOI not verified**).
- **Exact per-cause % split: NOT FOUND in extractable text** — present only in figures/tables of WHO
  PDFs. Closest citable: preterm complications = **35% of under-5 deaths (2012)**, neonatal period =
  **44% of under-5 deaths**, pneumonia **13%** — *Every Newborn* 2014
  <https://iris.who.int/handle/10665/127938>
- Coverage gaps, same source: only **38% of births in a skilled-attendant setting**; 90%
  facility-birth-with-HQC and 90% PNC were the 2020 targets — ibid.

## 2. WHO-recommended clinical practices (the checklist an app would have to carry)

From the full text of WHO 2022 *Caring for the newborn: a guideline*
<https://iris.who.int/handle/10665/352658> (exec summary <https://iris.who.int/handle/10665/353586>):

| Rec | Practice |
|---|---|
| **44** | **≥ 4 postnatal contacts — within 24 h, 48–72 h, 7–14 d, 6 weeks**; 24-h facility stay for healthy vaginal deliveries (context-specific) |
| **42–43** | Exclusive breastfeeding to 6 months; counselling at **every** contact; Ten Steps; rooming-in ≥ 24 h; no food/fluid other than breast milk unless medically indicated |
| **33** | Healthy newborn placed **supine** to sleep (SUDI prevention) |
| **29–30** | TcB measured before discharge |
| **31** | First bath **delayed ≥ 24 h** |
| **32b** | **4% chlorhexidine umbilical cord care — context-specific only** (where harmful traditional substances are applied to the cord) |
| **35** | Vitamin A **NOT routine**; single 50 000 IU within 3 days only where NMR > 50/1000 **AND** maternal night blindness ≥ 10% |
| **36** | Vitamin D **in research only** |
| **34** | Newborn immunisations per national/WHO schedule |
| **37–38** | Whole-body massage may be considered; responsive caregiving 0–3 y (ECD) |
| **55** | **Digital birth notifications — context-specific, and only when individual-level data reaches the health system/CRVS *and* that system can respond** |

- Hypothermia affects **32–85%** of hospital-delivered newborns in included studies; MLCC
  (midwife-led clinics), task-sharing to lay CHWs, and **home visits within the first week**
  recommended — ibid.
- ⚠️ **Rec 36 directly contradicts a shipped mamadera feature**: the app reminds parents of
  **Vitamin D daily** (`reminderVitaminD`). WHO says vitamin D for newborns is research-only.
  Rec 35 explains why: context thresholds, not a blanket supplement. **This is a live clinical
  discrepancy in the current build, in the app's own default reminder list.**

## 3. Newborn danger signs (0–2 months) — the canonical list

Source: WHO **IMNCI** chart booklet, *Management of the sick young infant aged up to 2 months*
(2019, ISBN 9789241516365) <https://iris.who.int/handle/10665/8c31ee56-4bbd-4640-a25b-2cd1ce98ac59>
(item id verified via IRIS API; text extracted from the PDF).

**Possible serious bacterial infection / very severe disease (0–7 d) → REFERRAL:**
- not feeding well
- convulsions
- severe chest indrawing
- fever ≥ 38 °C
- low temperature < 35.5 °C
- no spontaneous movement
- fast breathing ≥ 60/min

**7–59 d:**
- **Pneumonia or very severe disease** — fast breathing ≥ 60/min
- **Local bacterial infection** — red/swollen umbilicus with pus; skin pustules/abscesses

**Separate action boxes:** jaundice, diarrhoea, suspected HIV exposure, feeding problems, low birth
weight, thrush.

WHO 2022 PNC guideline repeats the **caregiver-facing** danger-sign list: not feeding well;
convulsions; fast breathing > 60/min; severe chest indrawing; no spontaneous movement; fever
> 37.5 °C; temp < 35.5 °C; **jaundice in the first 24 h or yellow palms/soles at any age** —
<https://iris.who.int/handle/10665/352658>.

> ⚠️ Note the **fever threshold inconsistency between the two WHO documents** (≥ 38 °C in IMNCI,
> > 37.5 °C in the 2022 PNC caregiver list). An app must pick one and cite it; this is exactly the
> kind of detail that becomes a clinical liability if invented.

- **Triage COLOURS (red/orange/yellow) for 0–2 months: NOT FOUND** — the IMNCI chart PDF is
  image-based and the colour headers were not extractable. Kenya IMNCI 2017 covers 2 months–5 years,
  **not** 0–2 months. South Africa IMCI 2022 uses "orange" only in the growth-chart stunting context.
  **→ Do not ship a colour-coded triage algorithm without the original chart in hand.**

## 4. Kangaroo Mother Care — the strongest intervention, and its limits

- WHO **2025 KMC Clinical Practice Guide** <https://iris.who.int/handle/10665/382962>:
  - **Rec 1: initiate KMC immediately after birth for ALL preterm or LBW newborns.**
  - **Rec 2: KMC as routine care 8–24 h/day** (as many hours as possible), **in facility OR at
    home**; continue preterm/LBW infants to term age or until they "wriggle out".
  - SSKC by the mother preferred, but **an additional caregiver may participate**; **first-hour
    skin-to-skin recommended for ALL healthy newborns regardless of gestation**.
  - **Reported effects: −32% neonatal mortality, −25% mortality by 6 months, −68% hypothermia.**
- **The negative control that must be read alongside those numbers:** Sloan 2008, 42 unions,
  **4 165 births, rural Bangladesh — NO difference in neonatal or infant mortality**; 40% of babies
  never weighed at birth. <https://pubmed.ncbi.nlm.nih.gov/18450847/>
  (feasibility: Ahmed 2011 <https://pubmed.ncbi.nlm.nih.gov/21311502/>, Quasem 2003
  <https://pubmed.ncbi.nlm.nih.gov/14647161/>)
- **Interpretation, mine, flagged as interpretation:** the −32% comes from *delivery of KMC as a
  supervised practice*; the null comes from *recommending KMC without the delivery system*. An app
  alone is closer to the second condition. Any KMC feature must therefore be built as **tracking
  tied to a facilitator/health-worker loop**, not as a reminder to a mother. (The three large WHO
  multi-country trials were **NOT FOUND** as primary sources in this pass — not cited above.)

## 5. The three delays — which delay actually kills newborns

- Pooled meta-analysis, **17 studies, 1995–2011, ~3.3 M births**: **delay level 3 (receiving
  adequate care) = 38.7%** (95% CI 21.7–57.3), **level 1 (deciding to seek) = 28%** (16–43),
  **level 2 (reaching facility) = 18.3%** (2.6–43.8) — Musaigye et al., *Paediatr Perinat
  Epidemiol* 2014 <https://pubmed.ncbi.nlm.nih.gov/24354747/>
- **Eastern Uganda**, 64 neonatal deaths: **47% died on the day of birth, 78% in the first week,
  54% outside a medical facility**; delays 50% caregiver recognition/decision, 30% facility quality,
  20% transport; **median 3 days before care was sought** <https://pubmed.ncbi.nlm.nih.gov/20636527/>
- **Rural northern Ghana**, 247 deaths, 4 districts 2015–17: 77% facility births, **48.9% died
  before discharge**; of those discharged or home-born, 71.8% had care sought and 82% arranged
  transport within 1 h — **the dominant failure was insufficient intervention once care WAS sought
  (≤ 25% received IV fluids, antibiotics, or oxygen)** <https://pubmed.ncbi.nlm.nih.gov/33540492/>
- **Rural Haryana, India**, 50 deaths: 44% died within 24 h; causes preterm 32%, asphyxia 28%,
  sepsis 14%; caregiver decision delay 44%, transport 34% <https://pubmed.ncbi.nlm.nih.gov/23174990/>
- **Rwanda**, 40 facilities, 2012, 1 324 neonates: ~75% had ≥ 1 delay; most common = inadequate
  care (29.1%); asphyxia 36.7%, LRTI 22.5%, prematurity 22.4% <https://pubmed.ncbi.nlm.nih.gov/28214925/>
- **East Africa** (Malawi/Mozambique/Tanzania): after adjusting for facility readiness, coverage of
  small-and-sick-newborn care dropped 30/14/24 points → **supply-side (level 3) dominates**
  <https://pubmed.ncbi.nlm.nih.gov/38334468/>
- **Kenya, Mfangano Island (MOMENTUM)**: 56 cases, mean total delay 39.3 ± 32.3 h; a **Health
  Navigator** intervention cut delay level 2 (0.5 vs 1.2 h, p=0.002) and level 3 (17.9 vs 32.9 h,
  p=0.030) <https://pubmed.ncbi.nlm.nih.gov/34403299/> (protocol
  <https://pubmed.ncbi.nlm.nih.gov/32182159/>)

## 6. Digital interventions with MEASURED newborn outcomes — mostly underwhelming

| Study | Design | Result |
|---|---|---|
| **CLIP** (Mozambique/Pakistan/India 2014–17, cRCT, 44 clusters, 69 330 women) | community engagement + mHealth-supported CHW early detection/treatment/referral of pregnancy hypertension | **NEGATIVE** — composite maternal/perinatal death or severe morbidity **aOR 1.17 (0.90–1.51), p=0.24**. *Lancet* 2020;396:553–563 <https://pubmed.ncbi.nlm.nih.gov/32828187/> |
| **ImTeCHO** (Gujarat tribal, 22 PHCs, 2016–17, open cRCT, 6 493 mothers) | mobile+web job aid for ASHAs | ≥2 home visits in first week **32.4% vs 22.9%** (+10.2, 6.4–14.0, p<0.001); EBF **+13.4 pts**; composite MNCH coverage 43.0% vs 38.5% (p=0.03) — **but infant and neonatal deaths were SIMILAR in both arms**. *PLoS Med* 2019;16:e1002939 <https://pubmed.ncbi.nlm.nih.gov/31647821/> |
| **Jacaranda PROMPTS** (Kenya, 40 facilities/8 counties, 6 139 women; > 750 000 enrolled nationally) | SMS info + appointment reminders + two-way clinical helpdesk | knowledge **+0.08 SD** (p=0.002), birth preparedness **+0.08** (p=0.018), routine care-seeking **+0.07** (p=0.003), newborn care **+0.09** (p<0.001), postpartum care content **+0.06** (p=0.043) — **NO significant effect on the danger-sign care-seeking index (−0.01 to 0.08, p=0.096)**. *PLoS Med* 2025;22:e1004527 <https://pubmed.ncbi.nlm.nih.gov/39899612/> |
| **Cochrane review 2020** (27 RCTs, 17 463 participants) | targeted client communication via mobile | may increase EBF in low-EBF settings (**RR 1.30, 1.06–1.59**, low certainty) and ANC attendance (OR 1.54, 0.80–2.96); **effects on maternal and neonatal mortality/morbidity UNCERTAIN**. *Cochrane Database Syst Rev* 2020;8(8):CD013679 <https://pubmed.ncbi.nlm.nih.gov/32813276/> |
| Small trials | weekly phone counselling + daily SMS, Nagpur India <https://doi.org/10.1186/s12887-018-1308-3> · mMitra voice messages, India <https://doi.org/10.1186/s12889-020-08965-2> · mHealth cRCT reducing prelacteal feeding, rural Ethiopia <https://doi.org/10.3390/nu18111795> · SMARTER safe-sleep SMS videos, low-income US, *JAMA* 2026 <https://doi.org/10.1001/jama.2026.9119> | breastfeeding/behaviour outcomes only |
| **Smartphone jaundice screening** | cross-sectional validation, 3 populations (Mexico, Nepal + Norway cohort) <https://doi.org/10.1136/bmjpo-2023-002242> · skin-colour vs serum bilirubin, Norway <https://doi.org/10.1111/apa.15287> · systematic review/meta-analysis of bilirubin apps <https://doi.org/10.1007/s00431-023-05073-2> | **diagnostic accuracy only — NO mortality-outcome trial found** |

- **m-mama / mMama chatbot RCT with newborn outcomes: NOT FOUND on PubMed.**

## 7. Apps & platforms actually in the field

- **Jacaranda Health (Kenya)** — PROMPTS platform, > 750 k women enrolled · <https://jacaranda.app>
  (JS-rendered, content unverified) — evidence above
- **Last Mile Health** — maternal-newborn chatbot/call service, Uganda and others ·
  <https://lastmilehealth.org/>
- **SEWA Rural / ImTeCHO (India)** — mobile+web ASHA job aid, Jhagadia Bharuch, scaled under
  Gujarat state · evidence above
- **OpenMRS** — open-source EMR, widely deployed in LMIC facilities · <https://openmrs.org/>
- **ODK** — mobile data collection for MNCH surveys/registers · <https://getodk.org/>
- **CommCare** — CHW field-app platform, many MNCH programmes ·
  ⚠️ `commcare.humaneix.com` **DNS failure** from this machine — **URL NOT VERIFIED**
- **dGraph/mTrac** — SMS birth-registration platform; `dnet.org` HTTP 200 but no extractable content
- **LifeSnap / BAudio / ARCMAC: NOT FOUND** (no accessible primary source)
- **Medic / Community Health Toolkit** — see delivery file §4: **182 636 CHWs, 24 countries,
  end-2025** <https://medic.org/>

## 8. What a consumer offline app CANNOT fix (each item is sourced)

1. **Facility-level care (delay 3) is the dominant killer** — 38.7% pooled; in Ghana ≤ 25% got
   antibiotics/IV fluids/oxygen even after care was sought. **An app cannot deliver oxygen,
   surfactant, IV antibiotics, or resuscitation.** (§5)
2. **WHO's only digital recommendation is health-system-level.** Rec 55 requires individual-level
   data to reach the CRVS **and** a system able to respond. **A siloed offline consumer app
   satisfies neither condition and must never present itself as a notification channel.** (§2)
3. **Measured effect sizes stop at behaviour, and never reach mortality.** PROMPTS: +0.09 SD on a
   newborn-care index, **zero** on danger-sign care-seeking. ImTeCHO: coverage up, **deaths
   unchanged**. CLIP: **negative**. Cochrane: **uncertain**. → *mamadera cannot claim, imply, or be
   marketed as mortality-reducing.* (§6)
4. **The IMNCI triage colours are not text-accessible** — do not reconstruct them from memory. (§3)
5. **KMC's −32% is supervised-practice evidence; the one community-only RCT was null.** (§4)
6. **PMTCT / HIV exposure management: unextractable PDFs, and out of scope** — a consumer app must
   not make PMTCT prophylaxis decisions.
7. **Per-cause mortality % live only in figures** — any marketing or in-app citation of a
   per-cause split needs the source figure pulled first. (§1)

---

## Verification still owed before any clinical feature ships

- [ ] Pull the **IMNCI 0–2 month chart as an image** and read the actual triage colours off it.
- [ ] Resolve the **≥ 38 °C vs > 37.5 °C** fever-threshold conflict between IMNCI 2019 and WHO
      PNC 2022, with the document and page.
- [ ] Find (or rule out) the **three WHO multi-country family-integrated KMC trials** as primary
      sources before quoting −32% in any UI or store listing.
- [ ] Verify **Lawn 2023 DOI**, **WHO-ERROR**, **ICFC 2023**, and the PMTCT handles — all
      currently NOT FOUND, therefore uncited.
- [ ] Re-check **CommCare** URL and `jacaranda.app` content from a network that resolves them.

*Related:* [`2026-10-05-delivery-feasibility.md`](2026-10-05-delivery-feasibility.md) ·
[`2026-10-05-neonatal-burden.md`](2026-10-05-neonatal-burden.md)
