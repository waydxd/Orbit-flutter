import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Displays the Orbit logo SVG with the small cyan ball
/// animating continuously along the tilted elliptical orbit.
class OrbitAnimation extends StatefulWidget {
  final double width;
  final double height;
  final Duration duration;

  const OrbitAnimation({
    required this.width,
    required this.height,
    super.key,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<OrbitAnimation> createState() => _OrbitAnimationState();
}

class _OrbitAnimationState extends State<OrbitAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            foregroundPainter: _OrbitBallPainter(
              progress: _controller.value,
            ),
            child: child,
          );
        },
        child: SvgPicture.asset(
          'assets/images/icon_no_ball.svg',
          width: widget.width,
          height: widget.height,
        ),
      ),
    );
  }
}

class _OrbitBallPainter extends CustomPainter {
  final double progress;

  // The SVG mask ellipse (rx=16.7792, ry=36.8171) defines the ring's
  // outer edge. The visible centerline of the orbit ring sits at ~95.1%
  // of those radii (derived from the original ball position in the SVG).
  static const double _cx = 49.9861;
  static const double _cy = 49.988;
  static const double _rx = 15.96;
  static const double _ry = 35.02;
  static const double _rotationRad = -120 * pi / 180;
  static const double _ballRadius = 4.0;
  static const double _svgSize = 100.0;

  _OrbitBallPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.shortestSide / _svgSize;
    final double t = 2 * pi * progress;

    final double cosT = cos(t);
    final double sinT = sin(t);
    final double cosR = cos(_rotationRad);
    final double sinR = sin(_rotationRad);

    final double svgX = _cx + _rx * cosT * cosR - _ry * sinT * sinR;
    final double svgY = _cy + _rx * cosT * sinR + _ry * sinT * cosR;

    final double x = svgX * scale;
    final double y = svgY * scale;
    final double r = _ballRadius * scale;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), r, paint);
  }

  @override
  bool shouldRepaint(covariant _OrbitBallPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
