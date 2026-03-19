import 'package:flutter/material.dart';
import '../../core/themes/app_colors.dart';

class FloatingNavBar extends StatefulWidget {
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
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar> {
  bool _isCreateMenuOpen = false;

  void _toggleCreateMenu() {
    setState(() {
      _isCreateMenuOpen = !_isCreateMenuOpen;
    });
  }

  void _handleCreateItemTap() {
    widget.onCreateTaskTap();
    setState(() {
      _isCreateMenuOpen = false;
    });
  }

  void _handleSecondaryCreateTap() {
    widget.onCreateTaskLongPress();
    setState(() {
      _isCreateMenuOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final blurHeight = screenHeight * 0.52;
    const bottomBarOffset = 30.0;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SizedBox(
        height: blurHeight + 180,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Main Nav Bar Background with transparent circular notch
            Positioned(
              left: 40,
              right: 40,
              bottom: bottomBarOffset,
              child: PhysicalShape(
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
                          isActive: widget.currentIndex == 0,
                          onTap: widget.onHomeTap,
                          iconSize: 30,
                        ),
                        _NavButton(
                          icon: Icons.calendar_today_outlined,
                          isActive: widget.currentIndex == 1,
                          onTap: widget.onCalendarTap,
                          iconSize: 24,
                        ),

                        // Space for the center floating button
                        const SizedBox(width: 86),

                        _NavButton(
                          icon: Icons.assignment_outlined,
                          isActive: widget.currentIndex == 2,
                          onTap: widget.onTodoListTap,
                        ),
                        _NavButton(
                          icon: Icons.dashboard_outlined,
                          isActive: widget.currentIndex == 3,
                          onTap: widget.onDashboardTap,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Create Task Button (Center) - Half above, half overlapping the bar
            Positioned(
              bottom: bottomBarOffset + 15,
              child: GestureDetector(
                onTap: _toggleCreateMenu,
                onLongPress: () {
                  // Long press should open AI chat, not keep the menu open.
                  setState(() {
                    _isCreateMenuOpen = false;
                  });
                  widget.onCreateTaskLongPress();
                },
                child: AnimatedRotation(
                  turns: _isCreateMenuOpen ? 0.125 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
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
            ),

            // Expanded actions above the center button
            Positioned(
              bottom: bottomBarOffset + 104,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_isCreateMenuOpen,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  opacity: _isCreateMenuOpen ? 1 : 0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    // Slide from slightly "closer" to the center.
                    offset: Offset(0, _isCreateMenuOpen ? 0 : 0.25),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      scale: _isCreateMenuOpen ? 1 : 0.88,
                      child: Center(
                        child: SizedBox(
                          width: 170,
                          height: 56,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 0,
                                child: _CreateActionButton(
                                  icon: Icons.draw_outlined,
                                  onTap: _handleCreateItemTap,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: _CreateActionButton(
                                  icon: Icons.text_fields_rounded,
                                  onTap: _handleSecondaryCreateTap,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CreateActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 28,
          color: AppColors.black.withValues(alpha: 0.85),
        ),
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
