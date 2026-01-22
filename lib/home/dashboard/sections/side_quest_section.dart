import 'package:flutter/material.dart';
import '../../../../theme/theme_manager.dart'; // <--- IMPORT THEME MANAGER

class SideQuestSection extends StatelessWidget {
  final VoidCallback onTap;

  const SideQuestSection({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 1. LISTEN TO THEME
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, child) {
        final theme = ThemeManager();

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              // Dynamic Background: Blends into whatever mode you are in
              color: theme.textColor.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.textColor.withOpacity(0.1), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded, color: theme.subText, size: 20),
                const SizedBox(width: 8),
                Text(
                  "ACCEPT NEW MISSION",
                  style: TextStyle(
                    color: theme.subText, // Dynamic Grey text
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}