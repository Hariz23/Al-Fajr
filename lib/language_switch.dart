import 'package:flutter/material.dart';

import 'theme.dart';

/// Two-state language control with a thumb that slides between EN and BM.
///
/// Both a tap on either side and a horizontal drag work; while dragging, the
/// thumb tracks the finger instead of waiting for release.
///
/// Set [onDark] on the green auth hero, where the track has to sit on the
/// gradient rather than on a light surface.
class LanguageSwitch extends StatefulWidget {
  const LanguageSwitch({
    super.key,
    required this.isEnglish,
    required this.onChanged,
    this.onDark = false,
  });

  final bool isEnglish;

  /// Receives the chosen language, not a flip — tapping the active side is a
  /// no-op rather than a toggle.
  final ValueChanged<bool> onChanged;
  final bool onDark;

  static const double _segment = 46;
  static const double _height = 36;
  static const double _inset = 3;

  @override
  State<LanguageSwitch> createState() => _LanguageSwitchState();
}

class _LanguageSwitchState extends State<LanguageSwitch> {
  /// 0 = English, 1 = Malay. Non-null only while a drag is in progress.
  double? _dragT;

  double get _restingT => widget.isEnglish ? 0 : 1;

  void _onDragUpdate(DragUpdateDetails details) {
    final current = _dragT ?? _restingT;
    setState(
      () => _dragT = (current + details.delta.dx / LanguageSwitch._segment)
          .clamp(0.0, 1.0),
    );
  }

  void _onDragEnd(DragEndDetails details) {
    final travelled = _dragT ?? _restingT;
    // A decisive flick wins over how far the thumb actually got.
    final velocity = details.velocity.pixelsPerSecond.dx;
    final bool wantsEnglish;
    if (velocity.abs() > 320) {
      wantsEnglish = velocity < 0;
    } else {
      wantsEnglish = travelled < 0.5;
    }
    setState(() => _dragT = null);
    widget.onChanged(wantsEnglish);
  }

  @override
  Widget build(BuildContext context) {
    final t = _dragT ?? _restingT;
    final dragging = _dragT != null;

    final track = widget.onDark
        ? AppTheme.textOnPrimary.withValues(alpha: 0.18)
        : AppTheme.surfaceMuted;
    final thumb = widget.onDark ? AppTheme.textOnPrimary : AppTheme.surface;
    final idle = widget.onDark
        ? AppTheme.textOnPrimary.withValues(alpha: 0.75)
        : AppTheme.textSecondary;

    return Semantics(
      label: 'Language',
      value: widget.isEnglish ? 'English' : 'Bahasa Melayu',
      child: GestureDetector(
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: Container(
          width: LanguageSwitch._segment * 2 + LanguageSwitch._inset * 2,
          height: LanguageSwitch._height,
          padding: const EdgeInsets.all(LanguageSwitch._inset),
          decoration: BoxDecoration(
            color: track,
            borderRadius: BorderRadius.circular(LanguageSwitch._height / 2),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: Duration(milliseconds: dragging ? 0 : 260),
                curve: Curves.easeOutCubic,
                alignment: Alignment(t * 2 - 1, 0),
                child: Container(
                  width: LanguageSwitch._segment,
                  height:
                      LanguageSwitch._height - LanguageSwitch._inset * 2,
                  decoration: BoxDecoration(
                    color: thumb,
                    borderRadius: BorderRadius.circular(
                      LanguageSwitch._height / 2,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  _Label(
                    text: 'EN',
                    // Colour follows the thumb, so a half-finished drag reads
                    // as half-committed rather than snapping at the end.
                    selection: 1 - t,
                    idleColor: idle,
                    onTap: () => widget.onChanged(true),
                  ),
                  _Label(
                    text: 'BM',
                    selection: t,
                    idleColor: idle,
                    onTap: () => widget.onChanged(false),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.text,
    required this.selection,
    required this.idleColor,
    required this.onTap,
  });

  final String text;
  final double selection;
  final Color idleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: LanguageSwitch._segment,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Color.lerp(idleColor, AppTheme.primaryGreen, selection),
              fontSize: 13,
              fontWeight: FontWeight.lerp(
                FontWeight.w600,
                FontWeight.w800,
                selection,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
