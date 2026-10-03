import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    super.key,
  });

  final String unit;
  final double min;
  final double max;
  final int divisions;
  final double value;
  final void Function(double) onValueChanged;

  /// Couleur d'accent (titre, slider) — le vert miam n'est qu'un défaut.
  final Color accentColor;

  /// Décimales affichées et acceptées. `0` garde le comportement historique des
  /// millilitres de biberon, au caractère près.
  ///
  /// Une température se dit `37,5` : afficher `38` dans une app de santé n'est
  /// pas un arrondi, c'est une réponse fausse.
  final int decimals;

  @override
  State<QuantityPickerInline> createState() => _QuantityPickerInlineState();
}

class _QuantityPickerInlineState extends State<QuantityPickerInline> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _textFor(widget.value));
  }

  @override
  void didUpdateWidget(covariant QuantityPickerInline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    // Ne pas réécrire ce que le parent est en train de taper : si le champ
    // représente déjà la valeur qu'on vient de recevoir, le texte est déjà bon
    // (« 37,5 » saisi, 37.5 reçu) et une réécriture placerait un point et
    // déplacerait le curseur en milieu de saisie.
    final entered = double.tryParse(_textController.text.replaceAll(',', '.'));
    if (entered == widget.value) return;
    _textController.text = _textFor(widget.value);
  }

  /// Texte du champ : troncature historique quand il n'y a pas de décimale,
  /// sinon la valeur telle qu'elle a été saisie.
  String _textFor(double value) =>
      widget.decimals == 0 ? value.toInt().toString() : value.toStringAsFixed(widget.decimals);

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onSliderChanged(double value) {
    widget.onValueChanged(value);
  }

  void _onTextChanged(String text) {
    // La virgule est le séparateur décimal du clavier français, celui de la
    // locale modèle de l'app : sans cette normalisation, « 37,5 » ne se parse
    // pas, `onValueChanged` n'est jamais appelé, et le parent croit avoir saisi
    // une température que l'app n'a jamais enregistrée.
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed != null && parsed >= widget.min && parsed <= widget.max) {
      widget.onValueChanged(parsed);
    }
  }

  String _formatValue(double value) {
    // decimals == 0 : le chemin des millilitres, inchangé au caractère près.
    if (widget.decimals == 0) {
      return '${value.round()} ${widget.unit}';
    }
    // Locale-aware : une température s'affiche « 37,5 °C » en français, pas
    // « 37.5 ». C'est une donnée de santé, sa lisibilité compte.
    final decimalSymbol = NumberFormat(
      '#,##0',
      Localizations.localeOf(context).toLanguageTag(),
    ).symbols.DECIMAL_SEP;
    return '${value.toStringAsFixed(widget.decimals).replaceAll('.', decimalSymbol)} ${widget.unit}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            _formatValue(widget.value),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: widget.accentColor,
                ),
          ),
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: widget.accentColor,
            inactiveTrackColor: Theme.of(context).colorScheme.outline,
            thumbColor: widget.accentColor,
            overlayColor: widget.accentColor.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: widget.value.clamp(widget.min, widget.max),
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            label: _formatValue(widget.value),
            onChanged: _onSliderChanged,
          ),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixText: widget.unit,
          ),
          onChanged: _onTextChanged,
        ),
      ],
    );
  }
}
