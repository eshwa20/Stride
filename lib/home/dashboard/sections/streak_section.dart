import 'package:flutter/material.dart';

class StreakSection extends StatelessWidget {
  const StreakSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // BIG STREAK HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF5252), size: 32),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "14 DAY STREAK",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  "You are on fire, Hunter!",
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // HEATMAP GRID
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: List.generate(28, (index) {
            // Fake data: mostly green
            final double opacity = (index % 3 == 0) ? 0.8 : (index % 5 == 0) ? 0.2 : 0.05;

            return Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withOpacity(opacity == 0.05 ? 0.1 : opacity),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: opacity > 0.5 ? const Color(0xFF00E676).withOpacity(0.5) : Colors.transparent,
                  width: 1,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}