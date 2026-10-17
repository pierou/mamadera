import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';

/// Inline quantity picker widget for use inside other dialogs/forms.
///
/// Unlike the modal `QuantityPickerDialog`, this does NOT wrap itself in a
/// modal - it's designed to be embedded directly in a Column or similar layout.
class QuantityPickerInline extends StatefulWidget {
  const QuantityPickerInline({
    required this.unit,
    required this.min,
    required this.max,
    required this.divisions,
    required this.value,
    required this.onValueChanged,
    this.accentColor = AppTheme.miam,
    this.decimals = 0,
    this.step,
    this.onValueOutOfRange,
    this.hintLabel,
    super.key,
  });

  final String unit;
  final double min;
  final double max;
  final int divisions;
  final double value;
  final void Function(double) onValueChanged;

  /// Number parsed **outside** the range `[min, max]` if the host requests it.
  ///
  /// `null` (default): An out-of-range input is ignored; this is the default behavior.
  /// historical. The host displays its current error and disables it.
  /// its backup — the figure is transmitted exactly as it is, **never rounded or modified**:
  /// Silently correcting the number of parents is inventing a metric.
  final void Function(double)? onValueOutOfRange;

  /// No plus/minus buttons, with values in [min]/[max] units.
  ///
  /// `null` (default): no stepper, the rendering is identical to the existing version.
  /// This is what protects call sites that do not have a natural gradient.
  /// The buttons appear on either side of the value, and are attached to...
  /// terminals, disabled (never hidden) when already in use.
  final double? step;

  /// Accent color (title, slider) - the "yum green" is just a minor flaw.
  final Color accentColor;

  /// Decimal places displayed and accepted. `0` retains the historical behavior of...
  /// Milliliters of formula, down to the last drop.
  ///
  /// A temperature is recorded as `37.5`: displaying `38` in a health app is...
  /// It's not an approximation; it's a wrong answer.
  final int decimals;

  /// The supplementary label is displayed **instead of the value** as long as the parent element is present.
  /// It didn't register anything (measurement sheet: the last measured value, e.g. "36,8 °C").
  ///
  /// The text field is provided, but it starts **empty**: the host value is not.
  /// Displaying a parent's input and labeling it as such is how you present it.
  /// as a measure that has been taken. The host learns that the seizure occurred through...
  /// The first call to [onValueChanged] (for a slider, stepper, or field) – that's the one.
  /// who decides to activate their backup.
  final String? hintLabel;

  @override
  State<QuantityPickerInline> createState() => _QuantityPickerInlineState();
}

class _QuantityPickerInlineState extends State<QuantityPickerInline> {
  late TextEditingController _textController;

  /// `false` until the parent has captured anything in `hintLabel` mode: the field.
  /// The field remains empty, and the header displays the increment, not the host value.
  bool _hasUserInput = false;

  /// Repeatedly pressing and holding the "stepper" button: cancelled in [dispose], otherwise a fire will occur.
  /// Calling `setState` on a component after it has been unmounted would result in an error.
  Timer? _repeatTimer;

  /// Original text already calculated: `didChangeDependencies` is called repeatedly.
  /// dependency change: the text is written only once.
  bool _textInitialized = false;

  @override
  void initState() {
    super.initState();
    _hasUserInput = widget.hintLabel == null;
    _textController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The initial text depends on the locale (decimal separator), and it's displayed as a widget.
    // inherited: cannot be read in `initState`, so it is written during the first execution.
    // `didChangeDependencies`.
    if (!_textInitialized) {
      _textInitialized = true;
      _textController.text =
          widget.hintLabel == null ? _textFor(widget.value) : '';
    }
  }

  @override
  void didUpdateWidget(covariant QuantityPickerInline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    // In "supplemental" mode, a value that changes before the initial entry is the...
    // The value of the host that is moving, not an echo of an input: the field.
    // If it's left blank, then it will automatically fill in the information that the form doesn't allow you to change.
    // Pre-fill.
    if (!_hasUserInput) return;
    // Do not rewrite what the parent is currently typing: if the field...
    // It already represents the value we just received, and the text is already good.
    // ("37.5" entered, 37.5 received), and rewriting it would place a period and...
    // It would move the cursor to the middle of the input field.
    final entered = double.tryParse(_textController.text.replaceAll(',', '.'));
    if (entered == widget.value) return;
    _textController.text = _textFor(widget.value);
  }

  /// Text field: Historical truncation when there is no decimal point.
  /// Otherwise, the locally formed value is "37,4" in French, not "37.4": a.
  /// The key pressed on the French keyboard becomes a second decimal point.
  /// The next step will advance to the next setting, and the value displayed will no longer be the one that will be stored.
  String _textFor(double value) {
    if (widget.decimals == 0) return value.toInt().toString();
    final symbol = _decimalSymbol();
    return value.toStringAsFixed(widget.decimals).replaceAll('.', symbol);
  }

  /// Decimal separator for the current locale (comma in French, period in English).
  String _decimalSymbol() =>
      NumberFormat('#,##0', Localizations.localeOf(context).toLanguageTag())
          .symbols
          .DECIMAL_SEP;

  @override
  void dispose() {
    _stopRepeat();
    _textController.dispose();
    super.dispose();
  }

  /// Reference value of the stepper: the value displayed in the field, not the actual value.
  /// position of the slider. If the parent element has the value `37.4`, then `+` should result in `37.5`.
  double _valueOnScreen() =>
      double.tryParse(_textController.text.replaceAll(',', '.')) ??
      widget.value;

  /// A step forward in the intended direction: calculations are performed using `double` precision.
  /// rounded to [QuantityPickerInline.decimals] decimal places, so that `0.1 + 0.1 + 0.1`
  /// It displays as `0.3` and never as `0.30000000000000004`, and then it's clamped to the boundaries.
  void _nudge(int direction) {
    final step = widget.step;
    if (step == null) return;
    final current = _valueOnScreen();
    // Safety mechanism for long-range shooting: if the target is reached.
    // While the series is running, the timer no longer adds any time.
    final atBound =
        direction > 0 ? current >= widget.max : current <= widget.min;
    if (atBound) return;
    final raw = current + direction * step;
    final factor =
        widget.decimals == 0 ? 1.0 : math.pow(10, widget.decimals).toDouble();
    final next = (raw * factor).round() / factor;
    final clamped = next.clamp(widget.min, widget.max);
    _textController.text = _textFor(clamped);
    _hasUserInput = true;
    widget.onValueChanged(clamped);
  }

  /// Long press: an immediate click, followed by a click every 120 milliseconds.
  void _startRepeat(int direction) {
    _stopRepeat();
    _nudge(direction);
    _repeatTimer = Timer.periodic(
        const Duration(milliseconds: 120), (_) => _nudge(direction));
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  /// Button with one level: localized tooltip and semantic label, disabled.
  /// (never masked - a control that disappears breaks the layout).
  /// once you are already at the corresponding terminal.
  ///
  /// [InkResponse], et ni [IconButton] ni lui n'exposent `onLongPressStart` :
  /// The repetition therefore starts on the `onLongPress` event (the recognized gesture), and...
  /// It stops at `onLongPressUp`. A custom [GestureDetector] would have provided the...
  /// The same result is achieved by removing the ripple effect, the hover effect, and the action trigger.
  /// "Activate" the screen reader — the simulated tap comes with the widget.
  Widget _buildStepButton(int direction) {
    final label = direction > 0 ? context.l.increment : context.l.decrement;
    final current = _valueOnScreen();
    final atBound =
        direction > 0 ? current >= widget.max : current <= widget.min;
    return Tooltip(
      message: label,
      child: InkResponse(
        borderRadius: BorderRadius.circular(24),
        onTap: atBound ? null : () => _nudge(direction),
        // On the device, the repeat function remains enabled, but the `_nudge` command will be ignored.
        onLongPress: atBound ? null : () => _startRepeat(direction),
        onLongPressUp: _stopRepeat,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            direction > 0
                ? Icons.add_circle_outline
                : Icons.remove_circle_outline,
            color:
                atBound ? Theme.of(context).disabledColor : widget.accentColor,
          ),
        ),
      ),
    );
  }

  void _onSliderChanged(double value) {
    _hasUserInput = true;
    widget.onValueChanged(value);
  }

  void _onTextChanged(String text) {
    // The comma is the decimal separator used on the French keyboard, unlike...
    // App locale model: Without this standardization, "37.5" cannot be parsed.
    // No, `onValueChanged` is never called, and the parent component believes it has successfully captured the value.
    // a temperature that the app has never recorded before. Normalization is...
    // Locale-neutral: The period and comma are used consistently across all locales.
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed == null) return;
    if (parsed >= widget.min && parsed <= widget.max) {
      _hasUserInput = true;
      widget.onValueChanged(parsed);
    } else {
      // Out of range: Do not remain silent. The host receives the entered value and...
      // decides how it will be displayed (its error message, whether its autosave feature is enabled).
      // The error message appears and resolves itself: re-enter the data within the specified range.
      // par `onValueChanged`.
      _hasUserInput = true;
      widget.onValueOutOfRange?.call(parsed);
    }
  }

  String _formatValue(double value) {
    // If `decimals` is equal to 0, the path for milliliters remains unchanged, character for character.
    if (widget.decimals == 0) {
      return '${value.round()} ${widget.unit}';
    }
    // Locale-aware: a temperature is displayed as "37.5 °C" in French, not...
    // "37.5". This is a health statistic, and its clarity is important.
    return '${_textFor(value)} ${widget.unit}';
  }

  /// Themed slider — **only one per selection**.
  ///
  /// It's a sighting device, not a precision instrument: on a...
  /// The range is 20 kg, with increments of 10 grams. There is a resolution of one tenth of a pixel, and...
  /// The thumb stops where the finger stops. The input field and the buttons.
  /// +/- determine the exact value – which is why there is no second [round/stage/attempt].
  /// "End" slider (removed on 2026-10-13, see docs/BACKLOG.md B2).
  Widget _buildSlider({
    required double min,
    required double max,
    required int divisions,
    required double value,
    required double clampedValue,
  }) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: widget.accentColor,
        inactiveTrackColor: Theme.of(context).colorScheme.outline,
        thumbColor: widget.accentColor,
        overlayColor: widget.accentColor.withValues(alpha: 0.2),
        trackHeight: 4,
      ),
      child: Slider(
        value: clampedValue,
        min: min,
        max: max,
        divisions: math.max(1, divisions),
        label: _formatValue(value),
        onChanged: _onSliderChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // `step == null`: This represents the exact output for today, without using the stepper.
    final showingHint = widget.hintLabel != null;
    final headerText = Text(
      _hasUserInput || !showingHint
          ? _formatValue(widget.value)
          : widget.hintLabel!,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            // The supplement isn't a measure; it's about the tone, not the color.
            // This accent mark is specifically used for numbers.
            color: _hasUserInput || !showingHint
                ? widget.accentColor
                : Theme.of(context).colorScheme.primary,
          ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: widget.step == null
              ? headerText
              :               // `scaleDown`: visual identity that maintains its integrity even when scaled down, and...
              // shrink instead of overflow when the sheet is narrow.
              FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStepButton(-1),
                      headerText,
                      _buildStepButton(1),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          value: widget.value,
          // `clamp`: An out-of-range value (B5) will keep the displayed number within the specified range.
          // The field; the thumb remains at the starting point and must not be raised.
          // l'assertion du Slider.
          clampedValue: widget.value.clamp(widget.min, widget.max),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          keyboardType: TextInputType.numberWithOptions(
            decimal: widget.decimals > 0,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: widget.unit,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixText: widget.unit,
          ),
          onChanged: _onTextChanged,
        ),
      ],
    );
  }
}
