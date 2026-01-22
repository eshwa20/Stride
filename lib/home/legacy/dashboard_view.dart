import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/xp_controller.dart';

import 'dashboard_header.dart';
import 'dashboard_task_tile.dart';

import '../../widgets/dashboard_action_grid.dart';
import '../../widgets/daily_goal_card.dart';
import '../dashboard/widgets/xp_trend_chip.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;

  final List<Map<String, dynamic>> _tasks = [
    {
      "title": "Mathematics",
      "time": "10:00 AM",
      "xp": 50,
      "isDone": false,
      "icon": Icons.functions
    },
    {
      "title": "UI Design",
      "time": "02:00 PM",
      "xp": 30,
      "isDone": false,
      "icon": Icons.design_services
    },
    {
      "title": "Read Book",
      "time": "09:00 PM",
      "xp": 10,
      "isDone": false,
      "icon": Icons.book
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.8, -0.5),
          radius: 1.3,
          colors: [Color(0xFF0F3D2E), Colors.black],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            // HEADER
            const DashboardHeader(),
            const SizedBox(height: 35),

            // XP SECTION
            _buildXPStat(context),
            const SizedBox(height: 35),

            // ACTION BUTTONS
            DashboardActionGrid(
              onNewHabit: () {
                // hook later
              },
            ),
            const SizedBox(height: 35),

            // DAILY GOAL CARD
            const DailyGoalCard(),
            const SizedBox(height: 35),

            // TASK TITLE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Quests",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                Icon(Icons.arrow_forward,
                    color: Colors.grey[600], size: 20),
              ],
            ),
            const SizedBox(height: 15),

            // TASK LIST
            ..._tasks.asMap().entries.map(
                  (entry) {
                final task = entry.value;
                final index = entry.key;

                return DashboardTaskTile(
                  task: task,
                  onToggle: () {
                    final xpController =
                    context.read<XpController>();

                    setState(() {
                      final isNowDone = !task['isDone'];
                      task['isDone'] = isNowDone;

                      final xp = task['xp'] as int;
                      if (isNowDone) {
                        xpController.addXp(xp);
                      } else {
                        xpController.removeXp(xp);
                      }
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // ================= XP STAT =================

  Widget _buildXPStat(BuildContext context) {
    final xp = context.watch<XpController>().totalXp;

    return Center(
      child: Column(
        children: [
          Text(
            "TOTAL XP EARNED",
            style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
                letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Text(
              "$xp",
              key: ValueKey(xp),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const XpTrendChip(),
        ],
      ),
    );
  }
}
