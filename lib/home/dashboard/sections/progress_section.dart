import 'package:flutter/material.dart';
import '../../../../theme/theme_manager.dart';

class ProgressSection extends StatelessWidget {
  const ProgressSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, child) {
        final theme = ThemeManager();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            // Dynamic Shadow based on theme
            boxShadow: theme.isDark
                ? []
                : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            // Subtle border that matches the accent color
            border: Border.all(color: theme.accentColor.withOpacity(0.1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- LEFT SIDE (Data & Charts) ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Icon(Icons.insights_rounded, color: theme.accentColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                            "SYSTEM ANALYSIS",
                            style: TextStyle(
                                color: theme.textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1
                            )
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Main Insight
                    Text(
                        "Performance Peaking",
                        style: TextStyle(
                            color: theme.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w900
                        )
                    ),
                    const SizedBox(height: 4),
                    Text(
                        "You are on track to reach Level 13 by Friday.",
                        style: TextStyle(
                            color: theme.subText,
                            fontSize: 12,
                            height: 1.4
                        )
                    ),

                    const SizedBox(height: 20),

                    // Mini Bar Chart Decoration
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildMiniBar(theme, 20),
                        const SizedBox(width: 6),
                        _buildMiniBar(theme, 35),
                        const SizedBox(width: 6),
                        _buildMiniBar(theme, 28),
                        const SizedBox(width: 6),
                        _buildMiniBar(theme, 50, isActive: true), // Tallest bar highlighted
                      ],
                    ),
                  ],
                ),
              ),

              // --- RIGHT SIDE (ASTRA MASCOT) ---
              // This is the empty space you wanted filled!
              SizedBox(
                width: 110,
                height: 110,
                child: Image.asset(
                  'assets/images/astra_head.png', // Ensure this file is in your assets
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper Widget for the Mini Chart Bars
  Widget _buildMiniBar(ThemeManager theme, double height, {bool isActive = false}) {
    return Container(
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: isActive ? theme.accentColor : theme.subText.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}