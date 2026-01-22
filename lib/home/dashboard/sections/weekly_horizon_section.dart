import 'package:flutter/material.dart';

class WeeklyHorizonSection extends StatelessWidget {
  const WeeklyHorizonSection({super.key});

  @override
  Widget build(BuildContext context) {
    // 0 = Missed, 1 = Done, 2 = Today
    final List<int> status = [1, 1, 0, 1, 1, 2, 0];
    final List<String> days = ["M", "T", "W", "T", "F", "S", "S"];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "THIS WEEK",
          style: TextStyle(
            color: isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            return _buildMinimalDay(
                context,
                days[index],
                status[index],
                isDark
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMinimalDay(BuildContext context, String day, int state, bool isDark) {
    // Color Logic
    Color bg;
    Color text;

    if (state == 2) { // Today
      bg = const Color(0xFF6C63FF);
      text = Colors.white;
    } else if (state == 1) { // Done
      bg = isDark ? const Color(0xFF2C2C35) : const Color(0xFFE0E0E0);
      text = const Color(0xFF00E676); // Green check color
    } else { // Empty
      bg = Colors.transparent;
      text = isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3);
    }

    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: state == 0
                ? Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1))
                : null,
          ),
          child: Center(
            child: state == 1
                ? const Icon(Icons.check_rounded, size: 18, color: Color(0xFF00E676))
                : state == 2
                ? const Text("14", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))
                : null,
          ),
        ),
      ],
    );
  }
}