import 'package:flutter/material.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:provider/provider.dart';

import '../theme/theme_manager.dart';
import '../home/home_dashboard_page.dart';
import '../clock/clock_screen.dart';
import '../calendar/calendar_screen.dart';
import '../profile/profile_screen.dart';
import '../home/analytics/analytics_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final PageController _pageController = PageController(initialPage: 0);
  final NotchBottomBarController _controller = NotchBottomBarController(index: 0);

  final List<Widget> _pages = [
    const HomeDashboardPage(),
    const ClockScreen(),
    const CalendarScreen(),
    const AnalyticsPage(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeManager>();

    return Scaffold(
      backgroundColor: theme.bgColor,
      // extendBody: true allows content to go behind the notch if needed,
      // but for a solid bar, the package handles the layout.
      extendBody: true,

      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),

      bottomNavigationBar: AnimatedNotchBottomBar(
        notchBottomBarController: _controller,
        color: theme.cardColor,
        notchColor: theme.accentColor,
        showLabel: false,

        // --- DOCKING THE BAR (No Floating) ---
        kBottomRadius: 0.0,  // Square corners at the bottom
        removeMargins: true, // Removes side and bottom spacing -> Full Width

        kIconSize: 24.0,

        // Shadow only in light mode for separation
        shadowElevation: theme.isDark ? 0 : 10,

        bottomBarItems: [
          BottomBarItem(
            inActiveItem: Icon(Icons.dashboard_outlined, color: theme.subText),
            activeItem: const Icon(Icons.dashboard_rounded, color: Colors.white),
            itemLabel: 'Home',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.timer_outlined, color: theme.subText),
            activeItem: const Icon(Icons.timer_rounded, color: Colors.white),
            itemLabel: 'Focus',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.calendar_month_outlined, color: theme.subText),
            activeItem: const Icon(Icons.calendar_today_rounded, color: Colors.white),
            itemLabel: 'Calendar',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.bar_chart_rounded, color: theme.subText),
            activeItem: const Icon(Icons.bar_chart_rounded, color: Colors.white),
            itemLabel: 'Stats',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.person_outline_rounded, color: theme.subText),
            activeItem: const Icon(Icons.person_rounded, color: Colors.white),
            itemLabel: 'Profile',
          ),
        ],
        onTap: (index) => _pageController.jumpToPage(index),
      ),
    );
  }
}