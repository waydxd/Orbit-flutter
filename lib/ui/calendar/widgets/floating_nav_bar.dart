import 'package:flutter/material.dart';
import '../../core/themes/app_colors.dart';

class FloatingNavBar extends StatelessWidget {
  final VoidCallback onHomeTap;
  final VoidCallback onCalendarTap;
  final VoidCallback onCreateTaskTap;
  final VoidCallback onCreateTaskLongPress;
  final VoidCallback onTodoListTap;
  final VoidCallback onDashboardTap;
  final int currentIndex;

  const FloatingNavBar({
    required this.onHomeTap,
    required this.onCalendarTap,
    required this.onCreateTaskTap,
    required this.onCreateTaskLongPress,
    required this.onTodoListTap,
    required this.onDashboardTap,
    super.key,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 40,
      right: 40,
      bottom: 30,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Main Nav Bar Background with transparent circular notch
          PhysicalShape(
            clipper: const _NavBarNotchClipper(
              cornerRadius: 30,
              notchRadius: 46,
            ),
            color: Colors.white,
            shadowColor: Colors.black.withValues(alpha: 0.18),
            elevation: 10,
            child: SizedBox(
              height: 60,
              child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavButton(
                    icon: Icons.home_outlined,
                    isActive: currentIndex == 0,
                    onTap: onHomeTap,
                    iconSize: 30,
                  ),
                  _NavButton(
                    icon: Icons.calendar_today_outlined,
                    isActive: currentIndex == 1,
                    onTap: onCalendarTap,
                    iconSize: 24,
                  ),

                  // Space for the center floating button
                  const SizedBox(width: 86),

                  _NavButton(
                    icon: Icons.assignment_outlined,
                    isActive: currentIndex == 2,
                    onTap: onTodoListTap,
                  ),
                  _NavButton(
                    icon: Icons.dashboard_outlined,
                    isActive: currentIndex == 3,
                    onTap: onDashboardTap,
                  ),
                ],
                ),
              ),
            ),
          ),

          // Create Task Button (Center) - Half above, half overlapping the bar
          Positioned(
            top: -40,
            child: GestureDetector(
              onTap: onCreateTaskTap,
              onLongPress: onCreateTaskLongPress,
              child: Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Image.asset(
                  'lib/assets/images/addTaskButton.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarNotchClipper extends CustomClipper<Path> {
  final double cornerRadius;
  final double notchRadius;

  const _NavBarNotchClipper({
    required this.cornerRadius,
    required this.notchRadius,
  });

  @override
  Path getClip(Size size) {
    final barPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(cornerRadius),
        ),
      );

    final notchPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2, 0),
          radius: notchRadius,
        ),
      );

    // Cut a transparent circle from the top-center of the bar.
    return Path.combine(PathOperation.difference, barPath, notchPath);
  }

  @override
  bool shouldReclip(covariant _NavBarNotchClipper oldClipper) {
    return oldClipper.cornerRadius != cornerRadius ||
        oldClipper.notchRadius != notchRadius;
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final double iconSize;

  const _NavButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.iconSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? AppColors.grey100 : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.black : AppColors.grey400,
          size: iconSize,
        ),
      ),
    );
  }
}
