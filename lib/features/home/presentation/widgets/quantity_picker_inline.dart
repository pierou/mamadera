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

  /// Nombre parsé **hors** de `[min, max]`, si l'hôte en veut la vue.
  ///
  /// `null` (défaut) : une saisie hors plage est ignorée, comportement
  /// historique. Fourni, l'hôte affiche son erreur existante et désactive
  /// sa sauvegarde — le chiffre est transmis tel quel, **jamais clamped** :
  /// corriger silencieusement un nombre de parent, c'est inventer une mesure.
  final void Function(double)? onValueOutOfRange;

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

  /// Libellé d'appoint affiché **à la place de la valeur** tant que le parent
  /// n'a rien saisi (feuille de mesure : « dernière : 36,8 °C »).
  ///
  /// Fourni, le champ texte démarre **vide** : la valeur de l'hôte n'est pas
  /// une saisie du parent, et l'afficher comme telle, c'est la présenter
  /// comme une mesure prise. L'hôte apprend que la saisie a eu lieu par le
  /// premier appel à [onValueChanged] (slider, stepper ou champ) — c'est lui
  /// qui décide d'activer sa sauvegarde.
  final String? hintLabel;

  @override
  State<QuantityPickerInline> createState() => _QuantityPickerInlineState();
}

class _QuantityPickerInlineState extends State<QuantityPickerInline> {
  late TextEditingController _textController;

  /// `false` tant que le parent n'a rien saisi en mode `hintLabel` : le champ
  /// reste vide et l'en-tête affiche l'appoint, pas la valeur de l'hôte.
  bool _hasUserInput = false;

  /// Répétition du stepper au long-appui : annulée en [dispose], sinon un feu
  /// post-démontage appellerait `setState` sur un State mort.
  Timer? _repeatTimer;

  /// Texte initial déjà calculé : `didChangeDependencies` repasse à chaque
  /// changement de dépendance, le texte n'est écrit qu'une seule fois.
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
    // Le texte initial dépend de la locale (séparateur décimal), un widget
    // hérité : illisible dans `initState`, on l'écrit au premier passage de
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
    // En mode appoint, une valeur qui bouge avant la première saisie est la
    // valeur de l'hôte qui se déplace, pas un écho d'une saisie : le champ
    // reste vide, sinon on pré-remplit ce que la feuille s'interdit de
    // pré-remplir.
    if (!_hasUserInput) return;
    // Ne pas réécrire ce que le parent est en train de taper : si le champ
    // représente déjà la valeur qu'on vient de recevoir, le texte est déjà bon
    // (« 37,5 » saisi, 37.5 reçu) et une réécriture placerait un point et
    // déplacerait le curseur en milieu de saisie.
    final entered = double.tryParse(_textController.text.replaceAll(',', '.'));
    if (entered == widget.value) return;
    _textController.text = _textFor(widget.value);
  }

  /// Texte du champ : troncature historique quand il n'y a pas de décimale,
  /// sinon la valeur locale-formée — « 37,4 » en français, pas « 37.4 » : un
  /// point tapé par le clavier français devient une seconde décimale au
  /// prochain cran, et la valeur affichée n'est plus celle qui sera stockée.
  String _textFor(double value) {
    if (widget.decimals == 0) return value.toInt().toString();
    final symbol = _decimalSymbol();
    return value.toStringAsFixed(widget.decimals).replaceAll('.', symbol);
  }

  /// Séparateur décimal de la locale courante (virgule en fr, point en en).
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

  /// Valeur de référence du stepper : ce qui est affiché dans le champ, pas la
  /// position du slider. Si le parent a tapé `37,4`, `+` doit donner `37,5`.
  double _valueOnScreen() =>
      double.tryParse(_textController.text.replaceAll(',', '.')) ??
      widget.value;

  /// Un cran dans la direction donnée : l'arithmétique se fait en `double`,
  /// arrondie à [QuantityPickerInline.decimals] pour que `0.1 + 0.1 + 0.1`
  /// s'affiche `0.3` et jamais `0.30000000000000004`, puis clamped aux bornes.
  void _nudge(int direction) {
    final step = widget.step;
    if (step == null) return;
    final current = _valueOnScreen();
    // Garde-fou pour la répétition au long-appui : si la borne est atteinte
    // en cours de série, le timer n'ajoute plus rien.
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

  /// Long-appui : un cran immédiat, puis un cran toutes les 120 ms.
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
    final atBound =
        direction > 0 ? current >= widget.max : current <= widget.min;
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
    // La virgule est le séparateur décimal du clavier français, celui de la
    // locale modèle de l'app : sans cette normalisation, « 37,5 » ne se parse
    // pas, `onValueChanged` n'est jamais appelé, et le parent croit avoir saisi
    // une température que l'app n'a jamais enregistrée. La normalisation est
    // locale-neutre : point ET virgule se saisissent dans chaque locale.
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed == null) return;
    if (parsed >= widget.min && parsed <= widget.max) {
      _hasUserInput = true;
      widget.onValueChanged(parsed);
    } else {
      // Hors plage : ne plus se taire. L'hôte reçoit la valeur saisie et
      // décide de l'affichage (son label d'erreur, sa sauvegarde désactivée).
      // L'erreur se lève et se lève seule : re-saisir dans la plage repasse
      // par `onValueChanged`.
      _hasUserInput = true;
      widget.onValueOutOfRange?.call(parsed);
    }
  }

  String _formatValue(double value) {
    // decimals == 0 : le chemin des millilitres, inchangé au caractère près.
    if (widget.decimals == 0) {
      return '${value.round()} ${widget.unit}';
    }
    // Locale-aware : une température s'affiche « 37,5 °C » en français, pas
    // « 37.5 ». C'est une donnée de santé, sa lisibilité compte.
    return '${_textFor(value)} ${widget.unit}';
  }

  /// Slider thémé — **un seul par picker**.
  ///
  /// C'est un dispositif de visée, pas un instrument de précision : sur une
  /// plage de 20 kg au pas de 10 g il y a un cran par dixième de pixel, et le
  /// pouce s'arrête où le doigt s'arrête. Le champ de saisie et les boutons
  /// +/- fixent la valeur exacte — c'est pourquoi il n'y a pas de second
  /// curseur « fin » (retiré le 2026-10-13, voir docs/BACKLOG.md B2).
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
    // `step == null` : exactement le rendu d'aujourd'hui, sans stepper.
    final showingHint = widget.hintLabel != null;
    final headerText = Text(
      _hasUserInput || !showingHint
          ? _formatValue(widget.value)
          : widget.hintLabel!,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            // L'appoint n'est pas une mesure : ton doux, pas la couleur
            // d'accent réservée aux nombres.
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
              : // `scaleDown` : identité visuelle quand la ligne tient, et
              // réduction au lieu d'un overflow quand la feuille est étroite.
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
          // `clamp` : une saisie hors plage (B5) garde le nombre affiché dans
          // le champ ; le pouce reste à la borne, il ne doit pas faire lever
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
