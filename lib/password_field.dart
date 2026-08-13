import 'package:flutter/material.dart';

import 'language_provider.dart';
import 'theme.dart';

/// How far a password gets through the rules below.
enum PasswordStrength { empty, weak, fair, strong }

/// The rules the meter scores against. Only [minLength] is enforced by the
/// form validator; the rest raise the score without blocking submission.
class PasswordRules {
  const PasswordRules._();

  static const int minLength = 6;
  static const int comfortableLength = 10;

  static bool hasLetter(String v) => RegExp(r'[A-Za-z]').hasMatch(v);
  static bool hasDigit(String v) => RegExp(r'\d').hasMatch(v);
  static bool hasSymbol(String v) => RegExp(r'[^A-Za-z0-9]').hasMatch(v);

  static PasswordStrength score(String value) {
    if (value.isEmpty) return PasswordStrength.empty;
    if (value.length < minLength) return PasswordStrength.weak;

    var points = 1;
    if (hasLetter(value) && hasDigit(value)) points++;
    if (hasSymbol(value) || value.length >= comfortableLength) points++;

    return switch (points) {
      >= 3 => PasswordStrength.strong,
      2 => PasswordStrength.fair,
      _ => PasswordStrength.weak,
    };
  }

  /// The shortest useful nudge: what is still missing, not a full checklist.
  static String? hint(String value, LanguageProvider lang) {
    if (value.isEmpty) return null;
    if (value.length < minLength) {
      return lang.getText(
        'Use at least $minLength characters.',
        'Gunakan sekurang-kurangnya $minLength aksara.',
      );
    }
    if (!(hasLetter(value) && hasDigit(value))) {
      return lang.getText(
        'Mix letters and numbers to make it stronger.',
        'Gabungkan huruf dan nombor untuk menguatkannya.',
      );
    }
    if (!hasSymbol(value) && value.length < comfortableLength) {
      return lang.getText(
        'Add a symbol or a few more characters.',
        'Tambah simbol atau beberapa aksara lagi.',
      );
    }
    return null;
  }
}

/// Password input with an animated reveal toggle and an optional strength
/// meter.
///
/// The eye is struck through by a line that draws itself rather than swapping
/// to a second icon, and the meter fills segment by segment as the password
/// gets stronger.
class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.lang,
    this.showStrength = false,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final LanguageProvider lang;

  /// Meter and hint belong on account creation, not on sign-in.
  final bool showStrength;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _strike = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  bool _obscure = true;
  String _value = '';

  @override
  void initState() {
    super.initState();
    _value = widget.controller.text;
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _strike.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (widget.controller.text == _value) return;
    setState(() => _value = widget.controller.text);
  }

  void _toggle() {
    setState(() => _obscure = !_obscure);
    if (_obscure) {
      _strike.reverse();
    } else {
      _strike.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final strength = PasswordRules.score(_value);
    final hint = PasswordRules.hint(_value, lang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          autofillHints: widget.autofillHints,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: (_) => widget.onSubmitted?.call(),
          validator: widget.validator,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: _toggle,
              tooltip: _obscure
                  ? lang.getText('Show password', 'Tunjukkan kata laluan')
                  : lang.getText('Hide password', 'Sembunyikan kata laluan'),
              icon: _StrikeThroughEye(progress: _strike),
            ),
          ),
        ),
        if (widget.showStrength) ...[
          // Collapsed until there is something to score, so an untouched form
          // is not fronted by three empty bars.
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _value.isEmpty
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _StrengthMeter(strength: strength, lang: lang),
                  ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: hint == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 8, left: 2),
                    child: Text(
                      hint,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.strength, required this.lang});

  final PasswordStrength strength;
  final LanguageProvider lang;

  static const _labels = {
    PasswordStrength.weak: ('Weak', 'Lemah'),
    PasswordStrength.fair: ('Fair', 'Sederhana'),
    PasswordStrength.strong: ('Strong', 'Kukuh'),
  };

  Color get _color => switch (strength) {
    PasswordStrength.empty => AppTheme.divider,
    PasswordStrength.weak => AppTheme.danger,
    PasswordStrength.fair => AppTheme.warning,
    PasswordStrength.strong => AppTheme.success,
  };

  int get _filled => switch (strength) {
    PasswordStrength.empty => 0,
    PasswordStrength.weak => 1,
    PasswordStrength.fair => 2,
    PasswordStrength.strong => 3,
  };

  @override
  Widget build(BuildContext context) {
    final label = _labels[strength];
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 220 + i * 70),
              curve: Curves.easeOutCubic,
              height: 4,
              decoration: BoxDecoration(
                color: i < _filled ? _color : AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < 2) const SizedBox(width: 6),
        ],
        if (label != null) ...[
          const SizedBox(width: 12),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              color: _color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            child: Text(lang.getText(label.$1, label.$2)),
          ),
        ],
      ],
    );
  }
}

/// The eye icon with a line that draws across it when the password is shown.
class _StrikeThroughEye extends StatelessWidget {
  const _StrikeThroughEye({required this.progress});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        return SizedBox(
          width: 24,
          height: 24,
          child: CustomPaint(
            painter: _StrikePainter(
              progress: progress.value,
              color: Color.lerp(
                AppTheme.textSecondary,
                AppTheme.primaryGreen,
                progress.value,
              )!,
            ),
            child: Center(
              child: Icon(
                Icons.visibility_outlined,
                size: 21,
                color: Color.lerp(
                  AppTheme.textSecondary,
                  AppTheme.primaryGreen,
                  progress.value,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StrikePainter extends CustomPainter {
  const _StrikePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final start = Offset(size.width * 0.16, size.height * 0.84);
    final end = Offset(size.width * 0.84, size.height * 0.16);
    final tip = Offset.lerp(start, end, Curves.easeOutCubic.transform(progress))!;

    // A light "cut" behind the stroke keeps it readable over the eye.
    canvas.drawLine(
      start.translate(1.6, 1.6),
      tip.translate(1.6, 1.6),
      Paint()
        ..color = AppTheme.surface
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      start,
      tip,
      Paint()
        ..color = color
        ..strokeWidth = 1.9
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _StrikePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
