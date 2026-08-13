import 'package:flutter/material.dart';

/// Cross-fade with a slight depth shift, used for every push in the app.
///
/// The outgoing screen fades out while easing back, the incoming one fades in
/// while settling forward, so navigation reads as one surface replacing
/// another rather than sliding in from the edge.
///
/// This replaces [CupertinoPageTransitionsBuilder], which also supplies the
/// interactive swipe-back gesture — that gesture is gone, so every pushed
/// screen must keep a visible back control.
class FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeThroughPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final exit = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInCubic,
      reverseCurve: Curves.easeOutCubic,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0).animate(exit),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 1.03).animate(exit),
        child: FadeTransition(
          opacity: enter,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(enter),
            child: child,
          ),
        ),
      ),
    );
  }
}
