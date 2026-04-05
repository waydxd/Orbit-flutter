import 'package:flutter/material.dart';

/// Orbi avatar widget with glow effect
class OrbiAvatar extends StatelessWidget {
  final double size;
  final bool showGlow;

  const OrbiAvatar({
    super.key,
    this.size = 90,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow layers
          if (showGlow)
            for (int i = 1; i <= 3; i++)
              Container(
                width: size + (size * 0.22 * i),
                height: size + (size * 0.22 * i),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6366F1).withValues(alpha: 0.15 / i),
                      const Color(0xFF6366F1).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
          // Inner Orb
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE0E7FF),
                  Color(0xFFC7D2FE),
                  Color(0xFF818CF8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: size * 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small avatar for chat messages
class SmallOrbiAvatar extends StatelessWidget {
  final double size;

  const SmallOrbiAvatar({
    super.key,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE0E7FF),
            Color(0xFFC7D2FE),
            Color(0xFF818CF8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}
