# Delivery feasibility — can this app physically reach them?

Gathered 2026-10-05 by `fast-scout` (read-only pass). Same reading rule as
[`2026-10-05-clinical-evidence.md`](2026-10-05-clinical-evidence.md): **sourced facts carry URLs;
NOT FOUND stays written down.** Several GSMA numbers are second-hand because `gsma.com` is
bot-walled from this Mac — that is flagged inline and must not be laundered into "GSMA says".

## 1. Devices & connectivity

**GSMA *Mobile Gender Gap Report 2026* (9th ed.) — ⚠️ second-hand via Connecting Africa, GSMA's own
site returned 403 "This User Agent is banned"; the 2026 PDF was never opened:**
- LMIC: women **12% less likely** to use mobile internet (improved from 14% in 2024);
  **74% of men vs 65% of women** — <https://www.connectingafrica.com/digital-divide/sub-saharan-africa-s-mobile-gender-gap-narrows-further>
- **810 M women in LMICs not using mobile internet** vs 595 M men; **> two-thirds** of them live in
  SSA + South Asia — ibid.
- **SSA mobile-internet gender gap 30% (2024) → 26% (2025)**; **230 M women still unconnected in
  SSA**; 38% in 2018 — ibid.
- SSA smartphone-ownership gender gap **24% → 22%**; overall mobile-ownership gap **12% → 10%** — ibid.
- **LMIC: 84% of women own a mobile phone vs 90% of men; 64% of women own a smartphone vs 73%** — ibid.
- **Widest smartphone gender gaps = the lowest-penetration countries: Bangladesh 40%, Ethiopia 34%,
  India 33%, Pakistan 30%, Uganda 26%**; Nigeria 26% — ibid.
- Closing the gap = US$230 bn revenue opportunity 2023–2030, $1.3 trn GDP — ibid.

**GSMA 2025 (8th ed.), from FinDev Gateway's own abstract page (fetched):** 14% gap; **885 M
unconnected women**, ~60% in South Asia + SSA; **mobile = 84% of broadband connections in LMICs**;
in **14 of 15** surveyed countries female internet users were more likely than men to be
**mobile-only** (up to 14 pp) — <https://www.findevgateway.org/paper/2025/05/mobile-gender-gap-report-2025>

**ITU *Facts and Figures 2025* (primary, fetched directly):**
- Internet use: **74% of the world online; low-income countries 23%; Africa 36%; LDCs 34%** —
  <https://www.itu.int/itu-d/reports/statistics/2025-10-15/ff25-internet-use/>
- Phone ownership: **82% of people 10+ own a mobile phone; low-income economies 53%**; **Africa 66%
  own a phone but only 36% are online — a 30 pp usage gap**; globally **78% of females vs 87% of
  males** (parity 0.90) — <https://www.itu.int/itu-d/reports/statistics/2025-10-15/ff25-mobile-phone-ownership/>
- Gender divide: **77% of men vs 71% of women online; ~280 M more men than women online**; Africa
  parity 0.70 → 0.78 (2019→2025); **no progress in Asia-Pacific (0.92 → 0.91)** —
  <https://www.itu.int/itu-d/reports/statistics/2025-10-15/ff25-the-gender-digital-divide/>
- **Affordability: median data-only mobile-broadband basket = 1.4% of GNI/capita globally;
  subscribers in lower-middle-income economies spend ~7×, and in low-income economies ~22×, that
  income share**; the Broadband Commission's ≤ 2%-of-GNI target is met by **130 of 205** economies;
  **only ~4 in 10 LMICs meet it for either basket** —
  <https://www.itu.int/itu-d/reports/statistics/2025-10-15/ff25-affordability-of-ict-services/>
- Coverage: **5G reaches 55% of the world but 4% of low-income countries; 4G reaches 93% globally
  but only 56% in low-income countries**; almost half of everyone without mobile broadband is in
  Africa — <https://www.itu.int/itu-d/reports/statistics/2025-10-15/ff25-mobile-network-coverage/>
- Subscriptions: 9.2 bn cellular (112/100 people); **low-income 70/100; Africa 92/100; mobile
  broadband 56/100 in Africa vs 99/100 globally; ≤ 2 of every 100 African subs are 5G** —
  <https://www.itu.int/itu-d/reports/statistics/2025-10-15/ff25-subscriptions/>

**Per country (GSMA Intelligence via DataReportal, Jan 2025 — secondary, fetched):**
| Country | Connections (% pop) | Broadband share of connections | ⇒ non-broadband (2G) | Internet users |
|---|---|---|---|---|
| Nigeria | 150 M (64.0%) | 94.4% | ~5.6% | 107 M (45.4%) |
| Pakistan | 190 M (75.2%) | 74.0% | **~26%** | 116 M (45.7%) |
| Bangladesh | 185 M (106%) | 64.9% | **~35%** | — |
| Ethiopia | 85.4 M (63.8%) | 98.2% | ~1.8% | **28.6 M (21.3%)** |
| Kenya | 68.8 M (121%) | 94.7% | ~5.3% | — |
| India | 1.12 bn (76.6%) | 92.3% | ~7.7% | — |

`https://datareportal.com/reports/digital-2025-nigeria` (and `/pakistan`, `/bangladesh`, `/ethiopia`,
`/kenya`, `/india`). Nigeria median mobile download **22.44 Mbps, down 28.6% YoY**.
**DR Congo: NOT FOUND** — no `digital-2025-democratic-republic-of-the-congo` slug.

- **Offline-first implication (this is arithmetic, not opinion):** Bangladesh ~35% and Pakistan ~26%
  of connections are not broadband, and ITU puts low-income 4G *coverage* at 56% → **a 60 MB first
  download is not guaranteed to complete, and every forced update is a bill.**
- ⚠️ **Alliance for Affordable Internet is DEAD as a source**: `a4ai.org` now serves a Debian
  placeholder; every report path 404s. **No per-country 1 GB-as-%-of-GNI table was obtained.**
  Do not cite A4AI numbers from memory.

## 2. Android / APK constraints

- **App floor:** `minSdk = flutter.minSdkVersion` → **API 24 (Android 7.0, April 2016)** —
  `android/app/build.gradle.kts:28` + `~/flutter/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt:26`
  (`val minSdkVersion: Int = 24`), **Flutter 3.44.8 stable**. *(Verified locally, not delegated.)*
- StatCounter mobile Android-version share, Sept 2026 — **browser traffic, NOT installed base, and the
  table truncates to the top 6 versions**:
  - Nigeria 15.0/20.98 · 14.0/15.91 · 16.0/13.72 · 13.0/12.66 · 12.0/11.63 · **11.0/9.57** = 84.47%
    shown, **15.53% unattributed tail** — <https://gs.statcounter.com/android-version-market-share/mobile/nigeria>
  - Pakistan 84.80% shown (floor 11.0 @ 11.47); Bangladesh 89.50%; Kenya 88.47%; Ethiopia 86.69%;
    India 92.78% — sibling URLs.
  - ⚠️ **The Android ≤ 6 share (the slice minSdk 24 excludes) is therefore UNMEASURED here.**
    NOT FOUND: a citable Android ≤ 6 share for SSA / South Asia.
- **Real devices sold (academic primary, but 2020 vintage):** Xie et al., *Trimming Mobile
  Applications for Bandwidth-Challenged Networks in Developing Regions*, IEEE TMC — Table 5, top-10
  phones on Kilimall (Kenya) / Jumia (Nigeria), surveyed **July 2020**: **Tecno F1 (8 GB storage,
  2G/3G only, 1 GB RAM)**, refurbished iPhone 4S/4 (**512 MB RAM**), Samsung Galaxy A10s 32 GB/2 GB,
  Umidigi A3S 16 GB/2 GB, Gionee S11 Lite **6 GB** —
  <https://people.cs.uchicago.edu/~ravenben/publications/pdf/trim-tmc21.pdf>
  The paper: developing-region users rely on 2G/EDGE giving **"bandwidth of only hundreds of kbps"**,
  and where *"a significant portion of disposable income goes towards mobile bandwidth costs"*,
  full-size updates are **"a severe disincentive towards application usage"**.
- Size ceilings cited *inside* that paper: Play limited apps to **100 MB** (Android 2.3+) + two
  expansion files up to 4 GB; iOS 4 GB; **2017 mean sizes iOS 38 MB / Android 15 MB** — ibid.
  ⚠️ **Current Play/AAB limits NOT VERIFIED** (`developer.android.com` redirected to OAuth).
- ⚠️ **NOT FOUND: any citable size → install-conversion coefficient.** The "6 MB ≈ 1% of installs"
  rule surfaced only as a Reddit thread and a 5043-byte Medium stub — **unattributed, do not repeat.**
- Local build fact: **no `abiFilters`, `splits`, or `deferred-components`** anywhere in `android/` →
  **the 60 MB APK carries every ABI.** Fat APK on a 2G/3G connection in Bangladesh is the single
  most concrete deployment blocker found in this survey.

## 3. Distribution channels, ranked by evidence of reach

1. **Google Play — still the only channel at national scale.** Android share of mobile *web* traffic:
   **Nigeria 84.21%, Pakistan 89.77%, Bangladesh 93.47%, Ethiopia 94.82%, India 93.89%,
   Kenya 95.16%, Somalia 89.17%**; iOS 4.5–15.7%; **KaiOS 0.01–0.04% — feature-phone OS is
   negligible even where 2G connections are large** —
   <https://gs.statcounter.com/os-market-share/mobile/nigeria> (and siblings).
   ⚠️ **NOT FOUND: any source confirming Play Store is *blocked* in Nigeria/Pakistan/Ethiopia/DR
   Congo/Bangladesh. Do not assert "Play unavailable".** Google's availability page covers *paid
   content and the Google TV app*, **not** Play app availability — and Nigeria, Pakistan, Ethiopia,
   DR Congo, Kenya do **not** appear on the Google TV list while India, Niger, Mali, Burkina Faso,
   Togo, Tanzania, Uganda, Zambia, Zimbabwe, Sri Lanka, Nepal do
   <https://support.google.com/googleplay/answer/2843119>. Read with that caveat.
2. **WhatsApp / messaging — proven government-grade reach for exactly this audience.** South Africa's
   **MomConnect** is a *government-led WhatsApp* maternal platform; in a 2023 enrolment of 968
   pregnant women/mothers, **86.3% faced multiple barriers to care**
   <https://www.nature.com/articles/s44360-026-00125-x>. **mHero** (IntraHealth) runs health-worker
   messaging at national scale <https://www.mhero.org/>
3. **Institutional/NGO fleet deployment onto issued devices** (CHW tablets/phones, offline-first,
   preloaded):
   - **Last Mile Health ↔ Ethiopia MoH**: open-source Android, **"running entirely offline"**, to
     **~38 000 HEWs** <https://lastmilehealth.org/2019-08-13/digital-educational-content-for-chws/>
   - **India**: **"ASHA Mobile App"**, **"MPW/CHO Tablet App"**, **"PHC MO Web Portal"** shipped to
     a million-worker cadre <https://nhsrcindia.org/sites/default/files/2021-12/Induction%20Training%20Module%20for%20CHO%20at%20AB-HWC%28English%29.pdf>
   - **Medic / Community Health Toolkit**: **open source, offline, 182 636 CHWs across 24 countries,
     end-2025** <https://medic.org/>
4. **OEM pre-install on Transsion devices — the obvious lever, but UNEVIDENCED.** StatCounter vendor
   share (Sept 2026): **Nigeria Tecno 20.47% + Infinix 16.89% + itel 4.80% = 42.16% Transsion**;
   Kenya Tecno 16.25 + Infinix 8.30; Ethiopia Samsung 56.43 + Tecno 13.47; Pakistan Samsung 17.35 /
   Infinix 15.04; Bangladesh Xiaomi 25.02 / Samsung 22.35; India Vivo 21.25 / Oppo 15.06 / Xiaomi
   14.76 — <https://gs.statcounter.com/vendor-market-share/mobile/nigeria>. Historic context: *"Tecno
   Mobile has established a franchise retail network to provide low-cost smartphones since 2010, and
   has been successful in Ghana, Cameroon, Nigeria"* — trim-tmc21.pdf (URL above).
   ⚠️ **No documented Transsion/Tecno pre-install programme was found ⇒ this channel is inferred.**
5. **F-Droid / direct APK sideload — weakest reach, and structurally at risk.**
   - F-Droid's **first-ever IndiaFOSS presence was 2 Oct 2026**, and *"most [attendees] were
     students, and many had never heard of F-Droid"* <https://f-droid.org/en/2026-10-02/fdroid-first-indiafoss-2026.html>
   - `org.mamadera` **and** the real `com.pvjio.mamadera` both **404** → **not published.**
   - 🔴 **Critical:** at that same event the discussion centred on **Google's Android Developer
     Verification, certified devices, and what these changes mean for distributing outside Google
     Play** — ibid. The F-Droid-led campaign states Google announced **August 2025** that **from
     2027 every Android app developer must register with Google (fee, terms, government-issued ID,
     evidence of the private signing key, list of all present and future application identifiers) or
     their apps are silently blocked on Android devices worldwide — explicitly including apps shared
     between friends and distributed through F-Droid**, which F-Droid calls *"existential"* —
     <https://keepandroidopen.org/> ⚠️ **advocacy page; Google's canonical docs 302'd to OAuth and
     could NOT be loaded. VERIFY AGAINST GOOGLE BEFORE ANY SIDELOAD-FIRST STRATEGY.**
6. **Refurbished devices bundled with software: Medic runs "Donate your old phones"** for the CHWs
   who run its software — <https://medic.org/>
7. **NOT FOUND:** quantified sideload volumes, WhatsApp APK spread, NGO offline distribution, or Play
   penetration per target country.

## 4. Institutional channels — CHW cadre sizes

| Country | Cadre | Size | Source & vintage |
|---|---|---|---|
| **India** | **ASHA** — one per village, literate women (10th std preferred), mandated first port of call, counsel on birth preparedness/breastfeeding/immunisation, escort to facilities | **"one million"** | <https://nhm.gov.in/index1.php?lang=1&level=1&sublinkid=150&lid=226> · peer-reviewed confirmation "the cadre of one million ASHAs", Ved, *Human Resources for Health* 2019 <https://pmc.ncbi.nlm.nih.gov/articles/PMC6323796/> |
| India | apps **explicitly prescribed** to the cadre — "ASHA Mobile App", "MPW/CHO Tablet App" | — | NHsrc induction module (URL §3) · app stacking reported (ANMOL, Poshan Tracker, e-Sanjeevani, NIKSHAY) — non-authoritative <https://anantamias.com/grassroots-health-workers/> · ANMOL as an Android app for ANMs <https://pmc.ncbi.nlm.nih.gov/articles/PMC9263958/> (snippet only) |
| **Ethiopia** | **Health Extension Workers** — two per 600 households, **47% of the country's health workforce, 70% of their time on house-to-house visits** | **> 38 000, all women** | IDRC Jan 2018 <https://idrc-crdi.ca/en/research-in-action/enhancing-health-worker-performance-ethiopia-mhealth> · Last Mile Health MoH agreement, offline OppiaAndroid app, ~38 000 HEWs <https://lastmilehealth.org/2019-08-13/digital-educational-content-for-chws/> ⚠️ *"66k" in my own brief NOT confirmed* |
| **global** | **Medic / Community Health Toolkit** — open source, offline-first, self-described **"digital public goods"** | **182 636 CHWs, 24 countries, 263 M moments of care, 12.1 M households, ~90 M people reached, end-2025** | <https://medic.org/> |
| Nigeria | CHEW / JCHEW / CHO cadres defined & licensed | **total headcount NOT FOUND** | <https://chprbn.gov.ng/standingorders/> · <https://www.swap.gov.ng/assets/JAR-CKqCNJs9.pdf> · <https://fmohconnect.gov.ng/wp-content/uploads/2025/05/The-State-of-Health-of-the-Nation-Report-2024.pdf> |
| DR Congo | **relais communautaires / RECO** linked into the system; WHO iCCM via CHWs | **NOT FOUND** | CHDP *Feuille de route RDC* 2021 <https://www.communityhealthdeliverypartnership.org/media/1026/file/RDCongo_Roadmap_FR_Final_20211229-B.pdf.pdf> · <https://www.who.int/fr/news-room/feature-stories/detail/who-child-health-programme-dries-tears-in-the-democratic-republic-of-the-congo> |
| Bangladesh | Family Welfare Assistant / Volunteer; **a 2022 government order cut fixed community-clinic days for FWAs to two per week** | **NOT FOUND** | <https://www.aliveandthrive.org/sites/default/files/counselling%20to%20improve%20nutrition%20in%20south%20asia.pdf> · Bangladesh MICS 2025 (denominators) |
| **Pakistan** | **LHW — NOT VERIFIED.** The often-cited ~250 000 could **not** be sourced; only figure found is an old UNFPA *"an army of 100 000 community health workers"* (2013-14) | ⚠️ | <https://pacific.unfpa.org/sites/default/files/resource-pdf/FP2020_Progress_Report_2013-2014_Digital_View_lores.pdf> · Punjab PGPR 2023-24 names the programme without a national total <https://wdd.punjab.gov.pk/system/files/PGPR-2023%20%26%202024-Web_compressed.pdf> · `lhwp.punjab.gov.pk`, `lhwp.goinformatics.gov.pk` did not resolve |

**Adoption plumbing a outsider must satisfy:** DHIS2 <https://dhis2.org/> · OpenHIE
<https://openhie.org/> · CHW Central <https://chwcentral.org/> (its `/country-profiles/` rendered no
usable country links).

## 5. Literacy & language — the hardest wall in the survey

⚠️ **All literacy figures below come from ONE Wikipedia table aggregating UNESCO UIS + DHS, in two
blocks of different vintage. Secondary. Pull UIS directly before publishing any of it.**
<https://en.wikipedia.org/wiki/List_of_countries_by_literacy_rate>

**Adult female literacy** (older DHS / newer UIS): **Afghanistan 31.7% (2011) / 29.5% (2021)** ·
**Niger 30.6% (2012) / 25.69% (2022)** · **Chad 22.3% (2016) / 18.64% (2019)** · **South Sudan
26.8% (2008) / 28.9% (2018)** · **Mali 33.1% (2015) / 25.7% (2018)** · **Burkina Faso 34.6% (2014)
/ 31.0% (2018)** · Somalia 39.0% (no sex split) · Sierra Leone 32.4/39.8 · Guinea 32.0/27.7 ·
Ethiopia 39.0 (2007) / 44.4% (2017) · Nigeria 51.1/52.7 · Pakistan 59.1 (2017) / **46.5% (2019)** ·
DR Congo 77.0/66.5 · Bangladesh 39.4 (2019) / **72.82% (2022)** · India 75.4/65.8 · Mozambique
56.0/50.3 · Liberia 42.9/34.1 · Sudan 53.5/56.1 · Togo 63.7/55.1 · Gambia 42.0/41.6 · Benin
32.9/31.1 · Cameroon 71.3/71.6 · Tanzania 77.9/73.1 · Uganda 70.2/70.8 · Kenya 78.7/78.2 ·
Malawi 62.1/55.2 · Zimbabwe 88.7/84.6 · Madagascar 71.6/75.1.
**Côte d'Ivoire NOT FOUND** in that table; female-only values NOT FOUND for CAR, Guinea-Bissau,
Eswatini, Lesotho, Djibouti, Equatorial Guinea.

> **⇒ In the eight highest-NMR countries (Niger, Chad, South Sudan, Afghanistan, Mali, Burkina Faso,
> Somalia, CAR) adult female literacy is ~19–35%. A text-first UI is unusable to the majority of the
> intended users *even in a language they read*.**

**Languages actually spoken vs the app's fr/en/es:**
- **Nigeria** — 520+ languages; English official but **"not widely spoken in rural areas"**;
  **Nigerian Pidgin** widely used; **Hausa "the single most widely spoken language… 60 million of the
  population"**; Yoruba/Igbo/Fula/Ibibio/Kanuri/Tiv regional — <https://en.wikipedia.org/wiki/Languages_of_Nigeria>
- **Pakistan** — Urdu national + lingua franca, English official; **> 1 M speakers each: Punjabi,
  Pashto, Sindhi, Saraiki, Urdu, Balochi, Hindko, Brahui, Kohistani (2023 census)**; ~60 languages
  under 1 M — <https://en.wikipedia.org/wiki/Languages_of_Pakistan>
- **Bangladesh** — **Bengali ~99% (2022 census)**; 36 indigenous languages
- **DR Congo** — French official, **4 national languages: Kikongo-Kituba, Lingala, Swahili,
  Tshiluba**; 215 living languages; 2024: 50.69% speak French, 74% use it as lingua franca, ~12% native
- **Somali** — **Northern Standard Somali ~60%, Maay ~20%, Benadiri ~18%**
- **Afghanistan** — **Dari > 75%, Pashto 48%, Uzbek 11% (2020 est)**
- **India** — Indo-Aryan 78.05%, Dravidian 19.64%; Hindi is **not** constitutionally "the national
  language"; Eighth Schedule list — all `https://en.wikipedia.org/wiki/Languages_of_<country>`

> **⇒ Spanish maps to ZERO target countries. French maps to DR Congo, CAR, Cameroon, Benin, Togo,
> Niger, Chad, Mali, Burkina Faso, Guinea, Eq. Guinea. English maps to Nigeria, Kenya, Uganda, Ghana,
> Zambia, Zimbabwe, Liberia, Sierra Leone, Gambia, Malawi, Namibia. Hausa, Yoruba, Igbo, Nigerian
> Pidgin, Swahili, Amharic, Oromo, Somali, Urdu, Punjabi, Pashto, Sindhi, Saraiki, Bengali, Hindi,
> Lingala, Tshiluba, Kikongo, Maay are all unsupported today.**

**Low-literacy / icon UI precedents (found):** icon-based maternal mHealth app in South Africa,
qualitative study <https://pmc.ncbi.nlm.nih.gov/articles/PMC12447011/> · Android maternal app
designed for **illiterate and semi-literate women** (HAL/Inria 2020)
<https://inria.hal.science/hal-02878639v1/document> · pilot RCT, rural Ugandan women with limited
education <https://www.researchgate.net/publication/364245618_...> (secondary host).
**Design requirements from formative research** (*J Global Health* MNCH scoping review, PMC6925966):
*"messages must be **localized & pre-tested; best to craft in local language, not translate**"*;
*"options for users with low technology literacy; **use female doctor voice; record messages in local
dialects**"* (MAMA Bangladesh); IVR participants *"open to IVR but had no prior experience"*, with
*"social, infrastructure and technology-literacy barriers"* —
<https://pmc.ncbi.nlm.nih.gov/articles/PMC6925966/>
- ⚠️ **Open-source speech/synthesis for Hausa/Swahili/Amharic/Oromo/Somali/Urdu/Bengali: NOT
  FOUND.** No icon standard for low-literacy health UI found. "MOTE" returned nothing as a speech
  project — **the programme actually named in the literature is MOTECH (Mobile Midwife, Ghana).**

## 6. Precedents — what failed, what worked

*Most of §6 is reported through one peer-reviewed scoping review (J Global Health MNCH map,
PMC6925966); its table entries were read, not the original programme reports.*

**Failed / mixed:**
- **Chipatala cha pa Foni (Malawi)** — weekly tips/reminders + protocol-based advice & referral
  hotline + **community-shared phones** hosted by volunteers: **reached only 19% of eligible
  mothers**; ITT showed **"negative effects on child care practices; no effect on knowledge or
  maternal care"**; 61% used the community phone — PMC6925966
- **mNutrition (Malawi, GSMA-run SMS)** — systems-theory analysis (Huggins & Valverde 2018):
  **"limited integration between sub-systems promoted more rapid implementation but likely compromised
  effectiveness and sustainability of messaging"** — ibid.
- **Tanzania MNCH SMS + "Healthy Pregnancy Healthy Baby" (GSMA 2014-17)** — lessons: content must be
  localised and **pre-tested, crafted in the local language rather than translated**; implementation
  challenges **"low female phone ownership & literacy; poor connectivity; responding to questions from
  subscribers"** — ibid.
- **IVR services** — participants open to it but **"had no prior experience"**; social, infrastructure
  and technology-literacy barriers; toll-free number + training recommended — ibid.
- **MomConnect (South Africa), Coleman & Xiong 2017 retrospective case-control** — **≥ 4 ANC visits
  68.4% (subscribers) vs 70.4% (controls), i.e. NO improvement**; full immunisation at 1 y 97% vs
  93.9%; 80.5% satisfied; **"sample size not achieved"**; MatCH evaluation 2011-2014, KwaZulu-Natal — ibid.
- **Aponjon (Cambodia)** — some ANC/neonatal practices significantly associated with use, **"no effect
  on infant feeding indicators"** — ibid.
- **Structural why:** 2026 systematic review of SSA mHealth through the **NASSS** framework found
  **409 barriers across 91 papers (2012–2025): technology 27%, wider system 18%, adopter 11%,
  organisation 9%, condition 8%; value proposition and embedding-over-time only 1% EACH; 24% of
  barriers fall outside NASSS entirely — "socioeconomic and infrastructural issues, distinct to
  LMICs"**; conclusion: fix *"rudimentary aspects"* and infrastructure **before** the interesting
  problems — *BMJ Health Care Informatics* 2026, PMID 42020094, doi 10.1136/bmjhci-2025-101485 —
  <https://europepmc.org/article/MED/42020094>
- **JEEViKA Mobile Vaani (Bihar)** — sustainability flagged as dependent on integration — PMC6925966

**Worked:**
- **Mobile Midwife (Ghana, MOTECH)** — qualitative (19 IDIs + 4 FGDs): users describe a **gradual
  process of gaining trust**, needing to reconcile content with traditional practices; **engagement
  increased awareness of the need for skilled care and birth preparedness** — PMC6925966
- 🔴 **MomConnect WhatsApp + embedded Diagnostic Decision Support (South Africa)** — prospective
  mixed-methods, 968 women, May–June 2023, **86.3% facing multiple barriers**: a physician panel rated
  the DSS advice safe in **98.4% (181/184)** of cases; **44.6% changed care-seeking intentions**;
  uncertainty 17.3% → 6.0%; **care sought 43.0% vs 17.0% initially**; safe behaviours **+18.1%
  (p=0.001)**. Registered **NCT06790069**, funded by the Rockefeller Foundation — *npj Health Systems*
  2026 — <https://www.nature.com/articles/s44360-026-00125-x>
  **→ This is the exact boundary case for mamadera: the moment the software produced *diagnostic
  decision support*, it was evaluated as a clinical instrument — physician panel, enrolled cohort,
  ClinicalTrials.gov registration.**
- **Last Mile Health ↔ Ethiopia MoH** — signed agreement, open-source, **fully offline**, ~38 000
  HEWs; *"each country will want to adapt their own curriculum"* —
  <https://lastmilehealth.org/2019-08-13/digital-educational-content-for-chws/>
- **Medic / CHT** — open source, offline-first, 182 636 CHWs in 24 countries, frames itself as
  **"building digital public goods"**, runs phone refurbishment — <https://medic.org/>
- **Integration with a midwife/facility is what makes messaging sustainable** — midwives "call all
  clients 3 weeks before due date"; **"integration with Ministry of Health facilitates participation and
  sustainability"** — PMC6925966

## 7. Regulatory

- **India — CDSCO**, *Medical Devices Rules 2017* (listed on the regulator's own site alongside the
  Drugs & Cosmetics Act 1940) — <https://cdsco.gov.in/>. **SaMD categorisation guidance: NOT FOUND.**
- **Nigeria — NAFDAC** lists **"Vaccines, Biologicals & Medical Devices"** among regulated families,
  publishes NAFDAC Guidelines/Regulations, maintains an Inspection Classification Database, and runs a
  channel to **"Report Adverse Events Associated with the use of Medical Devices & IVDs"** —
  <https://nafdac.gov.ng/>. **SaMD/app-specific rule: NOT FOUND.**
- **Ethiopia — EFDA** has a standing **Medical Device** sector (registration & market authorisation,
  manufacturer inspection, device safety/e-Reporting), Guidelines, Directives, Proclamations, and an
  electronic **eRIS** — <https://efda.gov.et/>.
- **Kenya — PPB: NOT VERIFIED** (`pharmacyboardkenya.org`, `digitalhealth.gov.ke` did not resolve).
  **Pakistan — DRAP: NOT VERIFIED** (`drap.gov.pk` did not resolve).
- **WHO framing:** *Global strategy on digital health 2020-2025*
  <https://www.who.int/publications/i/item/9789240020924>. *Classification of Digital Health
  Interventions v1.0*: `iris.who.int/handle/10665/260213` → HTTP 200 but a JS "DSpace" shell,
  **title unconfirmed.**
- **What "low risk" hinges on — evidence, not inference:** everything that stayed in the
  information/reminder lane (Mobile Midwife, MomConnect messaging) was run and evaluated as a
  **health-communication service**; the moment software produced **diagnostic decision support** it was
  tested with a **physician safety panel, an enrolled cohort and a ClinicalTrials.gov registration
  (NCT06790069)** — <https://www.nature.com/articles/s44360-026-00125-x>.
  mamadera today contains **no triage and no clinical content** (verified: `grep` in the burden file),
  i.e. **it currently sits on the safe side of that line, and adding danger-sign triage moves it
  across.**
- **Registration timelines / fees for NAFDAC, CDSCO, DRAP, PPB, EFDA: NOT FOUND.** No published fee,
  class or turnaround for software was found in any of the five jurisdictions.

## 8. Funding routes — and the honest state of them

- **Grand Challenges (Gates-funded hub)** — live; **4 163 awarded grants across 124 countries**; new
  opportunities posted Aug 2026 — <https://www.grandchallenges.org/>. ⚠️ **At fetch time the only open
  opportunity was Keystone Symposia Global Health Travel Awards** (conference access for LMIC
  scientists; GHTA deadlines 25 Aug 2026 – 9 Jan 2027) ⇒ **no open RFP a newborn-tracking app could
  apply to today** — <https://www.grandchallenges.org/grant-opportunities>
- **Grand Challenges Canada** — page states verbatim: **"There are currently no open funding
  opportunities… we only accept applications for open funding opportunities and cannot accept
  unsolicited project proposals."** Standing initiatives: **Being** (youth mental health; Colombia,
  Ecuador, Ghana, India, Indonesia, Morocco, **Pakistan**, Romania, Senegal, Sierra Leone, Tanzania,
  Vietnam — closed 31 Mar 2026) and **Nexa / Nexa Lighthouse / Nexa Billion** (climate × health,
  Africa + LAC + Asia-Pacific; PoC closed 22 Jul 2026, Transition-to-Scale extended to 12 Aug 2026) —
  <https://www.grandchallenges.ca/funding-opportunities/>
- **Gates Foundation topical owner** — Maternal, Newborn, Child Nutrition and Health (under
  gender-equality) — surfaced, **not opened**
  <https://www.gatesfoundation.org/our-work/programs/gender-equality/maternal-newborn-child-nutrition-and-health>
- **AI for Good (ITU)** — <https://aiforgood.itu.int/> live; `/initiatives/` and `/ai-for-good-2026/`
  both 404 ⇒ **specific open call NOT FOUND.**
- **EDCTP** <https://www.edctp.org/> (clinical-trials partnership, not a software grant) ·
  **PATH** <https://www.path.org/> · **Omidyar** <https://www.omidyar.com/> · **DHIS2** ·
  **OpenHIE** · **CHW Central** · **Last Mile Health** · **mHero**
- **NIHR Global Health Research (UK)** — "We fund research in LMICs eligible for UK ODA. From 2026,
  we will…" (terms changing; **not opened**) — <https://www.nihr.ac.uk/research-unding/global-health>
- **SPARK Grant Program for community-led health initiatives** (SRMNCAH) — aggregator listing,
  **eligibility unverified** — <https://www2.fundsforngos.org/innovation/spark-grant-program-for-community-led-health-initiatives/>
- **Watch weekly:** <https://africanngos.org/2026-04-08/african-ngo-funding-opportunities-april-may-2026/> ·
  <https://impactfunding.substack.com/p/global-health-and-wash-august-2026> (states "maternal and/or
  newborn care… next global call expected 2026") · <https://www2.fundsforngos.org/>
- ⚠️ **NOT FOUND / DEAD:** **UNITAID** (Cloudflare 403) · Wellcome grant guidelines (404 at guessed
  path) · Mozilla (403) · Internet Society grants (404) · **USAID Development Innovation Ventures —
  `div.org` is now a PARKED DOMAIN about the HTML `<div>` element; the DIV programme's live URL was
  NOT FOUND** · GSMA Innovation Fund (403) · `newbornhealth.org`, `hefrd2.org`, `cdphahe.org`,
  `healthlasting.org` **do not resolve from this network — do not cite as live** ·
  "meunto/Global Access" **NOT FOUND, name as briefed appears garbled.**

## Gaps (do not let these quietly become assumptions)

- GSMA's own site never loaded ⇒ **every §1 GSMA number is second-hand**; the 2026 PDF unopened.
- **Per-country 1 GB price as % of GNI: not obtained.** A4AI's site is dead; ITU's per-country price
  tables were promised for Nov 2025 and were not fetched.
- StatCounter truncates to top-6 Android versions ⇒ **the Android ≤ 6 share that minSdk 24 excludes
  is unmeasured**, and StatCounter measures browser traffic, not installed base.
- **No citable size → install conversion.** `developer.android.com` (size limits, App Bundles,
  **Developer Verification**) would not load ⇒ **the 2027 sideloading restriction rests on an advocacy
  page.** Highest-priority verification item in this file.
- CHW headcounts for **Nigeria, DR Congo, Bangladesh, Pakistan all NOT FOUND**; India (1 M ASHA) and
  Ethiopia (38 k HEW) are 2018–2021 vintage.
- Literacy figures are 2007–2022, from one Wikipedia table; ~12 of the highest-burden countries lack a
  female-only value there. **No numeric/health-literacy measurement found** (distinct from literacy).
- **Open-source speech synthesis for Hausa/Swahili/Amharic/Oromo/Somali/Urdu/Bengali: NOT FOUND.**
- `sx` engines were repeatedly *Suspended: too many requests / CAPTCHA* through this session; several
  sweeps (sideload volumes, Kenya PPB, Play availability, funding calls) returned nothing. Several
  funder/regulator domains do not resolve from this Mac at all.
