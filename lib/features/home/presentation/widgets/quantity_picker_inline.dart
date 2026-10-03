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
    super.key,
  });

  final String unit;
  final double min;
  final double max;
  final int divisions;
  final double value;
  final void Function(double) onValueChanged;

  /// Pas des boutons +/-, en unités de [min]/[max].
  ///
  /// `null` (défaut) : pas de stepper, le rendu est identique à l'existant —
  /// c'est ce qui protège les sites d'appel qui n'ont pas de pas naturel.
  /// Les boutons apparaissent de part et d'autre de la valeur, clamped aux
  /// bornes, désactivés (jamais masqués) quand on est déjà dessus.
  final double? step;

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

  /// Répétition du stepper au long-appui : annulée en [dispose], sinon un feu
  /// post-démontage appellerait `setState` sur un State mort.
  Timer? _repeatTimer;

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
    _stopRepeat();
    _textController.dispose();
    super.dispose();
  }

  /// Valeur de référence du stepper : ce qui est affiché dans le champ, pas la
  /// position du slider. Si le parent a tapé `37,4`, `+` doit donner `37,5`.
  double _valueOnScreen() =>
      double.tryParse(_textController.text.replaceAll(',', '.')) ?? widget.value;

  /// Un cran dans la direction donnée : l'arithmétique se fait en `double`,
  /// arrondie à [QuantityPickerInline.decimals] pour que `0.1 + 0.1 + 0.1`
  /// s'affiche `0.3` et jamais `0.30000000000000004`, puis clamped aux bornes.
  void _nudge(int direction) {
    final step = widget.step;
    if (step == null) return;
    final current = _valueOnScreen();
    // Garde-fou pour la répétition au long-appui : si la borne est atteinte
    // en cours de série, le timer n'ajoute plus rien.
    final atBound = direction > 0 ? current >= widget.max : current <= widget.min;
    if (atBound) return;
    final raw = current + direction * step;
    final factor = widget.decimals == 0 ? 1.0 : math.pow(10, widget.decimals).toDouble();
    final next = (raw * factor).round() / factor;
    final clamped = next.clamp(widget.min, widget.max);
    _textController.text = _textFor(clamped);
    widget.onValueChanged(clamped);
  }

  /// Long-appui : un cran immédiat, puis un cran toutes les 120 ms.
  void _startRepeat(int direction) {
    _stopRepeat();
    _nudge(direction);
    _repeatTimer =
        Timer.periodic(const Duration(milliseconds: 120), (_) => _nudge(direction));
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  /// Bouton d'un cran : tooltip et label sémantique localisés, désactivé
  /// (jamais masqué — un contrôle qui disparaît fait sauter la mise en page)
  /// quand on est déjà sur la borne correspondante.
  ///
  /// [InkResponse], et ni [IconButton] ni lui n'exposent `onLongPressStart` :
  /// la répétition démarre donc sur `onLongPress` (le geste reconnu) et
  /// s'arrête sur `onLongPressUp`. Un [GestureDetector] maison aurait donné le
  /// même résultat en jetant le ripple, le curseur de survol et l'action
  /// « activer » du lecteur d'écran — le tap simulé vient avec le widget.
  Widget _buildStepButton(int direction) {
    final label = direction > 0 ? context.l.increment : context.l.decrement;
    final current = _valueOnScreen();
    final atBound = direction > 0 ? current >= widget.max : current <= widget.min;
    return Tooltip(
      message: label,
      child: InkResponse(
        borderRadius: BorderRadius.circular(24),
        onTap: atBound ? null : () => _nudge(direction),
        // Sur la borne, la répétition reste armable mais `_nudge` s'y no-op.
        onLongPress: atBound ? null : () => _startRepeat(direction),
        onLongPressUp: _stopRepeat,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            direction > 0 ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: atBound ? Theme.of(context).disabledColor : widget.accentColor,
          ),
        ),
      ),
    );
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
    // `step == null` : exactement le rendu d'aujourd'hui, sans stepper.
    final valueText = Text(
      _formatValue(widget.value),
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: widget.accentColor,
          ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: widget.step == null
              ? valueText
              : // `scaleDown` : identité visuelle quand la ligne tient, et
                // réduction au lieu d'un overflow quand la feuille est étroite.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStepButton(-1),
                      valueText,
                      _buildStepButton(1),
                    ],
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
