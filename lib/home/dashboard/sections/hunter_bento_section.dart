import 'package:flutter/material.dart';
import '../../../../theme/theme_manager.dart';

class HunterBentoSection extends StatelessWidget {
  final int steps;
  // --- NEW: Real Data Inputs ---
  final int completedTasks;
  final int totalTasks;

  const HunterBentoSection({
    super.key,
    this.steps = 0,
    this.completedTasks = 0, // Default to 0
    this.totalTasks = 0,     // Default to 0
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, child) {
        final theme = ThemeManager();

        // Calculate progress for tasks (avoid division by zero)
        double taskProgress = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;
        String taskString = "$completedTasks/$totalTasks";

        return Column(
          children: [
            // ROW 1: Two Wide Cards
            Row(
              children: [
                // 1. STRENGTH (Steps)
                Expanded(
                  child: _buildCompactCard(
                    context,
                    theme,
                    title: "STRENGTH",
                    value: _formatSteps(steps),
                    unit: "Steps",
                    icon: Icons.directions_walk_rounded,
                    color: const Color(0xFFFF5252), // Red
                    progress: (steps / 10000).clamp(0.0, 1.0),
                  ),
                ),
                const SizedBox(width: 10),

                // 2. INTELLECT (Real Task Progress)
                Expanded(
                  child: _buildCompactCard(
                    context,
                    theme,
                    title: "INTELLECT",
                    value: taskString, // <--- REAL DATA
                    unit: "Missions",
                    icon: Icons.check_circle_outline_rounded, // Changed icon to match context
                    color: const Color(0xFF6C63FF), // Purple
                    progress: taskProgress, // <--- REAL PROGRESS
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ROW 2: Three Mini Cards
            Row(
              children: [
                Expanded(
                  child: _buildMiniCard(
                    context,
                    theme,
                    value: "1.2L",
                    unit: "Water",
                    icon: Icons.water_drop_rounded,
                    color: const Color(0xFF00D2D3),
                  ),
                ),
                const SizedBox(width: 10),

                // Tasks Mini Card (Mirroring Intellect)
                Expanded(
                  child: _buildMiniCard(
                    context,
                    theme,
                    value: taskString, // <--- REAL DATA
                    unit: "Tasks",
                    icon: Icons.list_alt_rounded,
                    color: const Color(0xFFFFD700),
                  ),
                ),

                const SizedBox(width: 10),
                Expanded(
                  child: _buildMiniCard(
                    context,
                    theme,
                    value: "7h",
                    unit: "Sleep",
                    icon: Icons.bedtime_rounded,
                    color: const Color(0xFFE056FD),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatSteps(int steps) {
    if (steps > 1000) {
      return "${(steps / 1000).toStringAsFixed(1)}k";
    }
    return steps.toString();
  }

  // WIDE CARD
  Widget _buildCompactCard(BuildContext context, ThemeManager theme, {
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.textColor.withOpacity(0.05)),
        boxShadow: theme.isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.subText,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                    color: theme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                ),
              ),
              Text(
                unit,
                style: TextStyle(
                    color: theme.subText,
                    fontSize: 10
                ),
              ),
            ],
          ),
          SizedBox(
            width: 34,
            height: 34,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: theme.subText.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Container(
                  width: 4, height: 4,
                  decoration: BoxDecoration(color: color.withOpacity(0.5), shape: BoxShape.circle),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MINI CARD
  Widget _buildMiniCard(BuildContext context, ThemeManager theme, {
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.textColor.withOpacity(0.05)),
        boxShadow: theme.isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                    color: theme.textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold
                ),
              ),
              Text(
                unit,
                style: TextStyle(
                    color: theme.subText,
                    fontSize: 10
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}