import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'theme.dart';

/// Shared frame for the sign-in and sign-up screens.
///
/// Both sit on the same green hero the home and prayer screens use, with the
/// form rising over it on a light sheet, so signing in reads as part of the
/// app rather than a detached form.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.languageLabel,
    required this.onToggleLanguage,
    required this.child,
    this.showBackButton = false,
  });

  final String title;
  final String subtitle;
  final String languageLabel;
  final VoidCallback onToggleLanguage;
  final Widget child;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.headerGradientStart,
      body: Column(
        children: [
          _AuthHero(
            title: title,
            subtitle: subtitle,
            languageLabel: languageLabel,
            onToggleLanguage: onToggleLanguage,
            showBackButton: showBackButton,
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.bgSoftWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({
    required this.title,
    required this.subtitle,
    required this.languageLabel,
    required this.onToggleLanguage,
    required this.showBackButton,
  });

  final String title;
  final String subtitle;
  final String languageLabel;
  final VoidCallback onToggleLanguage;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.headerGradientStart, AppTheme.headerGradientEnd],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _AuthSkyPainter())),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 18, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        if (showBackButton)
                          _HeroCircleButton(
                            icon: CupertinoIcons.back,
                            label: MaterialLocalizations.of(
                              context,
                            ).backButtonTooltip,
                            onPressed: () => Navigator.maybePop(context),
                          ),
                        const Spacer(),
                        Semantics(
                          button: true,
                          label: 'Change language',
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            minimumSize: const Size(44, 36),
                            borderRadius: BorderRadius.circular(18),
                            color: AppTheme.textOnPrimary.withValues(
                              alpha: 0.16,
                            ),
                            onPressed: onToggleLanguage,
                            child: Text(
                              languageLabel,
                              style: const TextStyle(
                                color: AppTheme.textOnPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      // Solid, not translucent: the mark is green on
                      // transparency and disappears against the hero.
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Image.asset('assets/icon.png'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textOnPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.9,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textOnPrimary.withValues(alpha: 0.72),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCircleButton extends StatelessWidget {
  const _HeroCircleButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(40, 40),
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.textOnPrimary.withValues(alpha: 0.16),
        onPressed: onPressed,
        child: Icon(icon, color: AppTheme.textOnPrimary, size: 20),
      ),
    );
  }
}

/// Faint orbit rings echoing the home screen hero.
class _AuthSkyPainter extends CustomPainter {
  const _AuthSkyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.92, size.height * 0.28);
    final ringPaint = Paint()
      ..color = AppTheme.textOnPrimary.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, size.width * 0.36, ringPaint);
    canvas.drawCircle(center, size.width * 0.24, ringPaint);

    final dotPaint = Paint()
      ..color = AppTheme.accentGold.withValues(alpha: 0.42);
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 + math.pi / 6;
      canvas.drawCircle(
        center +
            Offset(
              math.cos(angle) * size.width * 0.3,
              math.sin(angle) * size.width * 0.3,
            ),
        i.isEven ? 2.2 : 1.4,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AuthSkyPainter oldDelegate) => false;
}
