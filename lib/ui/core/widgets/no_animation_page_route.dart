import 'package:flutter/material.dart';

/// A [MaterialPageRoute] with no transition animation.
class NoAnimationPageRoute<T> extends MaterialPageRoute<T> {
  NoAnimationPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) : super(builder: builder, settings: settings);

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;
}
