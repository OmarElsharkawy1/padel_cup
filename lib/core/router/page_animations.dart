import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PageAnimations {
  static CustomTransitionPage fadeAnimationPage({
    required LocalKey pageKey,
    required Widget screen,
    String? name,
  }) {
    return CustomTransitionPage(
      key: pageKey,
      name: name,
      transitionDuration: const Duration(milliseconds: 150),
      child: screen,
      transitionsBuilder: (
        context,
        animation,
        secondaryAnimation,
        child,
      ) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
          child: child,
        );
      },
    );
  }
}
