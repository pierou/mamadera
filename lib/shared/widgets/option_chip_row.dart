import 'package:flutter/material.dart';

/// A horizontal selector for a small closed set of options that never clips a
/// label, in any locale.
///
/// Replaces the `Row` + `Expanded` + [FilterChip] rows it was extracted from.
/// Three equal columns plus a single text line silently truncated every label
/// longer than roughly eight characters — French "Lait Maternel" rendered as
/// "Lait…", English "Breast milk" likewise — because a chip's text budget is
/// `screen width / 3` minus ~64dp of chip chrome, while the strings arrive from
/// `.arb` files that layout cannot see. Measured at 320/360/393dp logical
/// pixels, in fr, en and es, every subtype label was truncated.
///
/// Here each chip takes its **intrinsic** width and the row wraps onto a second
/// line when the labels do not fit. [Wrap] caps every child at its own width,
/// so a label can only be squeezed if it is wider than the whole row — and a
/// [Text] soft-wraps before that ever becomes an overflow. Truncation is
/// therefore impossible by construction instead of tuned per locale: a longer
/// translation costs a line, never a meaning.
///
/// The leading 18×18 slot holds the option icon, or a check when the option is
/// selected. Reserving it in *both* states is deliberate: Material's own
/// `showCheckmark` adds the box only on the selected chip, which both takes
/// ~24dp away from the option the user sees first (the pre-selected one, always)
/// and changes the chip's width on every tap, which re-wraps the row under the
/// finger.
///
/// Label and icon keep one colour in both states, [ColorScheme.onSurface].
/// Material paints a selected filter chip with `onSecondaryContainer`, and this
/// app's scheme leaves that role unset — `ColorScheme` then substitutes
/// `onSecondary`, which is white — so the selected chip put a white label and a
/// white check on the `miam` 20% tint: contrast near 1:1, unreadable in light
/// mode. Since the selected chip no longer shows its icon either, that invisible
/// label would have been the only information left on the chosen option.
///
/// [selectedColor] therefore has to stay a light tint of the background, the way
/// `miam` at 20% is: the label is not re-coloured to match it.
class OptionChipRow<T> extends StatelessWidget {
  /// Builds the selector. [options] is rendered in order; the one equal to
  /// [selected] is drawn selected. [labelOf] must return the localized label
  /// and [iconOf] the option's icon — the visible state is icon/check, so the
  /// label carries the meaning and must never be abbreviated for space.
  const OptionChipRow({
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelOf,
    required this.iconOf,
    this.selectedColor,
    this.spacing = 8,
    this.runSpacing = 8,
    super.key,
  });

  /// The choices, in display order.
  final List<T> options;

  /// The currently chosen option; compared with `==`.
  final T selected;

  /// Called with the option the parent tapped.
  final ValueChanged<T> onSelected;

  /// Localized label of [options], resolved through the widget tree so it
  /// follows the active locale.
  final String Function(BuildContext context, T option) labelOf;

  /// Icon identifying [options] while they are unselected.
  final IconData Function(T option) iconOf;

  /// Fill of the selected chip; `null` keeps the theme default.
  final Color? selectedColor;

  /// Horizontal gap between chips on the same line.
  final double spacing;

  /// Vertical gap between wrapped lines.
  final double runSpacing;

  /// Width and height of the leading slot, identical in both selection states.
  static const double _iconSlotSize = 18;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Set on the widgets themselves: `FilterChip`'s component defaults rank
    // above any `ChipTheme`, so a theme-level override would be ignored.
    final foreground = theme.colorScheme.onSurface;
    final labelStyle = theme.textTheme.labelLarge?.copyWith(color: foreground);

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: [
        for (final T option in options)
          FilterChip(
            selected: option == selected,
            onSelected: (_) => onSelected(option),
            selectedColor: selectedColor,
            showCheckmark: false,
            avatar: SizedBox(
              width: _iconSlotSize,
              height: _iconSlotSize,
              child: Icon(
                option == selected ? Icons.check : iconOf(option),
                size: _iconSlotSize,
                color: foreground,
              ),
            ),
            label: Text(labelOf(context, option), style: labelStyle),
          ),
      ],
    );
  }
}
