import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'timer_service.dart';

class TimerStatisticsScreen extends StatefulWidget {
  const TimerStatisticsScreen({super.key});

  @override
  State<TimerStatisticsScreen> createState() => _TimerStatisticsScreenState();
}

class _TimerStatisticsScreenState extends State<TimerStatisticsScreen> {
  TimerStatistics? _stats;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final stats = await TimerService.loadStatistics();
    setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    if (_stats == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Focus Statistics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Today',
                    '${_stats!.dailyFocusMinutes}m',
                    Icons.today,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'This Week',
                    '${_stats!.weeklyFocusMinutes}m',
                    Icons.calendar_view_week,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'This Month',
                    '${_stats!.monthlyFocusMinutes}m',
                    Icons.calendar_month,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total XP',
                    _stats!.totalXpEarned.toString(),
                    Icons.stars,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Streaks
            const Text(
              'Streaks',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStreakItem(
                    'Current',
                    _stats!.currentStreak,
                    Icons.local_fire_department,
                    Colors.red,
                  ),
                  _buildStreakItem(
                    'Best',
                    _stats!.longestStreak,
                    Icons.emoji_events,
                    Colors.yellow,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Session Stats
            const Text(
              'Sessions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Sessions Completed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _stats!.totalSessionsCompleted.toString(),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Average Session Length',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _calculateAverageSessionLength(),
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Achievements
            const Text(
              'Achievements',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildAchievements(),

            const SizedBox(height: 32),

            // Weekly Chart Placeholder
            const Text(
              'Weekly Progress',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'Weekly progress chart will be implemented here',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakItem(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _calculateAverageSessionLength() {
    if (_stats!.totalSessionsCompleted == 0) return '0m';

    // This is a simplified calculation - in a real app you'd track individual session lengths
    final totalMinutes = _stats!.dailyFocusMinutes +
                        _stats!.weeklyFocusMinutes +
                        _stats!.monthlyFocusMinutes;
    final averageMinutes = totalMinutes ~/ _stats!.totalSessionsCompleted;
    return '${averageMinutes}m';
  }

  Widget _buildAchievements() {
    final achievements = _getAchievements();

    return Column(
      children: achievements.map((achievement) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: achievement['unlocked']
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade800.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: achievement['unlocked']
                  ? Colors.yellow.withOpacity(0.3)
                  : Colors.grey.shade700,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                achievement['icon'],
                color: achievement['unlocked'] ? Colors.yellow : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement['title'],
                      style: TextStyle(
                        color: achievement['unlocked'] ? Colors.white : Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      achievement['description'],
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (achievement['unlocked'])
                const Icon(
                  Icons.check_circle,
                  color: Colors.yellow,
                  size: 20,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _getAchievements() {
    return [
      {
        'title': 'First Focus',
        'description': 'Complete your first focus session',
        'icon': Icons.play_circle,
        'unlocked': _stats!.totalSessionsCompleted >= 1,
      },
      {
        'title': 'Week Warrior',
        'description': 'Complete 7 sessions in a week',
        'icon': Icons.calendar_view_week,
        'unlocked': _stats!.totalSessionsCompleted >= 7,
      },
      {
        'title': 'Streak Master',
        'description': 'Maintain a 7-day streak',
        'icon': Icons.local_fire_department,
        'unlocked': _stats!.longestStreak >= 7,
      },
      {
        'title': 'Hour Hero',
        'description': 'Focus for 60 minutes in a single day',
        'icon': Icons.schedule,
        'unlocked': _stats!.dailyFocusMinutes >= 60,
      },
      {
        'title': 'XP Champion',
        'description': 'Earn 1000 XP',
        'icon': Icons.stars,
        'unlocked': _stats!.totalXpEarned >= 1000,
      },
      {
        'title': 'Consistency King',
        'description': 'Complete 30 sessions',
        'icon': Icons.emoji_events,
        'unlocked': _stats!.totalSessionsCompleted >= 30,
      },
    ];
  }
}