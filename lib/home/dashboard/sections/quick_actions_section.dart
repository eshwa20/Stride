import 'package:flutter/material.dart';
import '../../../../theme/theme_manager.dart'; // <--- IMPORT THEME MANAGER
import '../../../../clock/clock_screen.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. LISTEN TO THEME
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, child) {
        final theme = ThemeManager();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ClockScreen(initialTabIndex: 0),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              // Dynamic Background: Dark Gradient in Dark Mode, Clean White in Light Mode
              gradient: theme.isDark
                  ? const LinearGradient(
                colors: [Color(0xFF2C3E50), Color(0xFF000000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : LinearGradient(
                colors: [Colors.white, Colors.grey.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.textColor.withOpacity(0.1)),
              boxShadow: theme.isDark
                  ? [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))]
                  : [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                // Icon Box
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.accentColor.withOpacity(0.2), // Dynamic Accent
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.timer_outlined, color: theme.accentColor, size: 24),
                ),
                const SizedBox(width: 14),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "START FOCUS",
                        style: TextStyle(
                          color: theme.textColor, // Dynamic Text
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        "0h 0m focused today",
                        style: TextStyle(color: theme.subText, fontSize: 13), // Dynamic Subtext
                      ),
                    ],
                  ),
                ),

                // Play Button
                Icon(Icons.play_circle_fill_rounded, color: theme.textColor, size: 36),
              ],
            ),
          ),
        );
      },
    );
  }
}