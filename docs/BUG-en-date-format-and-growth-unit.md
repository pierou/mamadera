# BUG — English dates drop their minutes; growth history contradicts its own unit

Found 2026-10-10 during the v1.2.0 screenshot campaign, **by looking at the
captured PNGs** — neither is caught by any unit test, and both are visible in
the store assets. Neither was fixed by the campaign: the campaign must photograph
what ships, and changing `lib/` after the `v1.2.0` tag would make the accepted
screenshots no longer describe the tagged binary. Fix in v1.2.1, then re-run the
campaign.

## 1. `formatDate` drops the minutes in English (app-wide)

`lib/core/l10n/date_localization.dart:22`

```dart
case 'en':
  return DateFormat('MM/dd/yyyy hh:aa', 'en_US').format(date);
```

`aa` is not a minute pattern. In ICU, minutes are `mm` and the AM/PM marker is
`a`; `aa` renders as the marker, so the minutes vanish entirely and the colon
that introduced them is left dangling.

Observed in the captured shots (real device output, not a test artifact):

| Screen | Rendered | Should be |
|---|---|---|
| Home → reminders | `Last done: 10/08/2026 07:PM` | `Last done: 10/08/2026 07:43 PM` |
| Growth history | `10/09/2026 01:AM` | `10/09/2026 01:43 AM` |
| Growth history | `09/25/2026 09:PM` | `09/25/2026 09:43 PM` |

`fr` (`dd/MM/yyyy HH:mm`) and `es` (`dd/MM/yyyy HH:mm`) are correct, which is
why this survived: every prior screenshot set and every test fixture written in
French never touched the English branch. The doc comment two lines above even
documents the intent — `MM/dd/yyyy hh:aa` is the bug, faithfully transcribed.

**Fix:** `DateFormat('MM/dd/yyyy hh:mm a', 'en_US')`. Then add a test pinning
all three locales against a fixed `DateTime`, so the pattern cannot rot again —
the same class of miss as the English-comma issue closed in `9844d50`.

**Blast radius:** every call site of `formatDate` in English — history list,
growth history, reminder "last done" subtitles. A parent tracking a fever at
`09:PM` cannot tell 21:04 from 21:59; for a health log that is the whole point
of the timestamp.

## 2. Growth history trailing unit contradicts the value

`lib/features/growth/presentation/screens/growth_screen.dart` —
`_historyTile(...)` → `trailing: Text(measurement.kind.displayUnit)`

`MeasureKind.displayUnit` returns the **stored** base unit
(`db_const.unitG` = `g`), but `MeasureKind.format()` promotes weight above
1 000 g to kilograms. The tile therefore shows both, and they disagree:

```
6.18 kg      ← title, formatted (kg)
      g      ← trailing, stored base unit
5.75 kg
      g
60.5 cm
      cm     ← duplicate, harmless but redundant
37.2 °C
      °C     ← duplicate, harmless but redundant
```

Only weight is actually wrong: the trailing `g` states a unit the value does not
use, which reads as "6.18 grams" to a skimming parent. `4.6 kg / g` at the
bottom of the growth list is the same defect.

**Fix (pick one, then re-shoot):** drop the trailing unit for weight and show
only what `format()` produced, or make the trailing text a *stored*-unit hint
explicitly labelled as such. Do not "fix" it by making `displayUnit` return
`kg` — `displayUnit` also labels the sheet's input field, where the stored unit
(`g`, step 10 g) is the correct prompt, so changing the getter would trade one
defect for another.

## Not bugs — checked and dismissed

- **Dimmed "Couche" / pale "Feeding" tile:** the accepted v1.1 uploads show the
  identical dimming (verified pixel-identical behaviour, 0 red). It is the
  existing dark-mode brown and light-mode yellow, already tracked as backlog
  item B4 — not a campaign regression.
- **DEBUG ribbon on the Android shots:** WAS a real defect, and it is fixed — see
  `screenshots/android/README.md`. `flutter drive` builds a debug APK; the README
  claimed 0 reddish pixels with no verification to back it. All 8 files now
  capture with `WidgetsApp.debugAllowBannerOverride = false` and
  `screenshots/android/verify_android.py` proves `red=0`.
