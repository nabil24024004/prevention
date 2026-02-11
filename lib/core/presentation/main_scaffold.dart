import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prevention/core/theme/app_colors.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  void _onTabChange(int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/islamic-corner');
        break;
      case 2:
        context.go('/statistics'); // Shifted left
        break;
      case 3:
        context.go('/profile'); // Shifted left
        break;
    }
  }

  // Calculate index based on current location to keep UI in sync with URL
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/islamic-corner')) return 1;
    if (location.startsWith('/statistics')) return 2;
    if (location.startsWith('/profile')) return 3;
    // If check-in is active, we might want to unselect all tabs or select Home?
    // Returning -1 deselects all.
    if (location.startsWith('/check-in')) return -1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      extendBody: true,
      body: widget.child,
      backgroundColor: Colors.black,

      // Central Check-In FAB
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 0), // Keep it at bottom
        child: Container(
          height: 72,
          width: 72,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black, // Background for the notch effect
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.secondary, Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () => context.push('/check-in'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              shape: const CircleBorder(),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                  Text(
                    'CHECK-IN',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        height: 70,
        padding: EdgeInsets.zero,
        notchMargin: 8,
        color: const Color(0xFF1E1E1E),
        shape: const CircularNotchedRectangle(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Side
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, 'Home', selectedIndex),
                    _buildNavItem(
                      1,
                      Icons.mosque_rounded,
                      'Islamic',
                      selectedIndex,
                    ),
                  ],
                ),
              ),

              // Middle Spacer for FAB
              const SizedBox(width: 72),

              // Right Side
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      2,
                      Icons.bar_chart_rounded,
                      'Stats',
                      selectedIndex,
                    ),
                    _buildNavItem(
                      3,
                      Icons.person_rounded,
                      'Profile',
                      selectedIndex,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    int selectedIndex,
  ) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => _onTabChange(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey[600],
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.grey[600],
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
