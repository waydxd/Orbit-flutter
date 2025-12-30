import 'package:flutter/material.dart';
import '../../core/themes/app_colors.dart';

class FloatingNavBar extends StatelessWidget {
  final VoidCallback onCalendarTap;
  final VoidCallback onCreateTaskTap;
  final VoidCallback onTodoListTap;
  final int currentIndex;

  const FloatingNavBar({
    super.key,
    required this.onCalendarTap,
    required this.onCreateTaskTap,
    required this.onTodoListTap,
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
          // Main Nav Bar Background
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Calendar Button (Left)
                Expanded(
                  child: Center(
                    child: _NavButton(
                      icon: Icons.calendar_today_outlined,
                      isActive: currentIndex == 0,
                      onTap: onCalendarTap,
                    ),
                  ),
                ),
                
                // Spacer for the center button
                const SizedBox(width: 80),
                
                // Todo List Button (Right)
                Expanded(
                  child: Center(
                    child: _NavButton(
                      icon: Icons.assignment_outlined,
                      isActive: currentIndex == 1,
                      onTap: onTodoListTap,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Create Task Button (Center) - Floating above
          Positioned(
            top: -35,
            child: GestureDetector(
              onTap: onCreateTaskTap,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Image.asset(
                  'lib/assets/images/addTaskButton.png',
                  width: 100,
                  height: 100,
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

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isActive ? AppColors.grey100 : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.black : AppColors.grey400,
          size: 28,
        ),
      ),
    );
  }
}
