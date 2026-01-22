import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Needed for User Name

// --- IMPORTS ---
import '../../theme/theme_manager.dart';
import '../../controllers/xp_controller.dart';
import '../../controllers/task_controller.dart';
import '../../services/step_tracker_service.dart';
import 'modals/add_task_sheet.dart';
import '../chat/chat_page.dart'; // <--- CHAT IMPORT

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _currentSteps = 0;
  final StepTrackerService _stepService = StepTrackerService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _initSteps();
  }

  void _initSteps() {
    _stepService.initService();
    if (mounted) setState(() => _currentSteps = _stepService.getSavedSteps());
    _stepService.stepStream.listen((steps) {
      if (mounted) setState(() => _currentSteps = steps);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _openNewMissionSheet(BuildContext context, TaskController controller) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTaskSheet(),
    );

    if (result != null && result['title'] != null) {
      controller.addTask(
          result['title'],
          category: result['category'] ?? "General"
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskController = context.watch<TaskController>();
    final xpController = context.watch<XpController>();

    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, child) {
        final theme = ThemeManager();

        return Scaffold(
          backgroundColor: theme.bgColor,

          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openNewMissionSheet(context, taskController),
            backgroundColor: theme.accentColor,
            elevation: 10,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("NEW DIRECTIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),

          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // --- HEADER WITH CHAT BUTTON ---
                  _HeaderSection(pulseAnimation: _pulseAnimation),

                  const SizedBox(height: 28),
                  const _ProgressSection(),
                  const SizedBox(height: 24),
                  _HunterBentoSection(
                    steps: _currentSteps,
                    completedTasks: taskController.tasks.where((t) => t.isCompleted).length,
                    totalTasks: taskController.tasks.length,
                  ),
                  const SizedBox(height: 24),
                  const _QuickActionsSection(),
                  const SizedBox(height: 32),

                  // DAILY QUESTS LIST
                  _DailyQuestSection(
                    tasks: taskController.tasks,
                    onQuestToggle: (id) {
                      taskController.toggleTask(id);
                      final task = taskController.tasks.firstWhere((t) => t.id == id);
                      if (task.isCompleted) xpController.addXp(50);
                    },
                    onQuestDelete: (id) => taskController.deleteTask(id),
                  ),

                  const SizedBox(height: 16),
                  _SideQuestSection(onTap: () => _openNewMissionSheet(context, taskController)),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
//  INTERNAL COMPONENT CLASSES
// ============================================================================

// --- UPDATED HEADER TO MATCH YOUR SCREENSHOT ---
class _HeaderSection extends StatelessWidget {
  final Animation<double> pulseAnimation;
  const _HeaderSection({required this.pulseAnimation});

  ImageProvider _getAvatarProvider(String path) {
    if (path.startsWith('assets/')) return AssetImage(path);
    if (path.isNotEmpty) {
      File file = File(path);
      if (file.existsSync()) return FileImage(file);
    }
    return const AssetImage('assets/profile/astra_happy.png');
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager();
    final xpController = context.watch<XpController>();
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName?.toUpperCase() ?? "COMMANDER";

    const Color emberColor = Color(0xFFFF9900);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // LEFT SIDE: AVATAR + NAME
            Row(
              children: [
                ValueListenableBuilder(
                    valueListenable: Hive.box('settingsBox').listenable(keys: ['userAvatar']),
                    builder: (context, Box box, _) {
                      String avatarPath = box.get('userAvatar', defaultValue: 'assets/profile/astra_happy.png');
                      return ScaleTransition(
                        scale: pulseAnimation,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(width: 54, height: 54, child: CircularProgressIndicator(value: 0.7, strokeWidth: 2, backgroundColor: theme.subText.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(theme.accentColor))),
                            Container(width: 46, height: 46, decoration: BoxDecoration(shape: BoxShape.circle, color: theme.cardColor, image: DecorationImage(image: _getAvatarProvider(avatarPath), fit: BoxFit.cover))),
                          ],
                        ),
                      );
                    }
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("RISE, HUNTER", style: TextStyle(color: theme.subText, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text(userName, style: TextStyle(color: theme.textColor, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ],
            ),

            // RIGHT SIDE: EMBERS + CHAT BUTTON + NOTIFICATION
            Row(
              children: [
                // 1. EMBERS PILL
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: emberColor.withOpacity(0.3))),
                  child: Row(children: [const Icon(Icons.local_fire_department_rounded, color: emberColor, size: 14), const SizedBox(width: 4), Text("${xpController.embers}", style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 12))]),
                ),

                const SizedBox(width: 8),

                // 2. NEW: ASTRA CHAT BUTTON
                GestureDetector(
                  onTap: () {
                    // Open the Chat Page
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatPage()));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: theme.cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.accentColor.withOpacity(0.5)),
                        boxShadow: [BoxShadow(color: theme.accentColor.withOpacity(0.1), blurRadius: 8)]
                    ),
                    child: Icon(Icons.chat_bubble_rounded, color: theme.accentColor, size: 18),
                  ),
                ),

                const SizedBox(width: 8),

                // 3. NOTIFICATION BELL (Matches your screenshot)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: theme.cardColor, shape: BoxShape.circle),
                  child: Stack(
                    children: [
                      Icon(Icons.notifications_none_rounded, color: theme.textColor, size: 20),
                      Positioned(right: 0, top: 0, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)))
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ... (KEEP THE REST OF THE CLASSES EXACTLY THE SAME) ...
// _ProgressSection, _HunterBentoSection, _QuickActionsSection, _DailyQuestSection, _QuestTile, _SideQuestSection
// Just copy them from the previous version or keep them if you only update the Header class.

class _ProgressSection extends StatelessWidget {
  const _ProgressSection();
  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager();
    final xpController = context.watch<XpController>();
    final int nextLevelXp = 1000 - (xpController.currentXp % 1000);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.accentColor.withOpacity(0.1)), boxShadow: theme.isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row( // Using Row to match your "Performance Peaking" screenshot style
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Icon(Icons.insights_rounded, color: theme.accentColor, size: 16), const SizedBox(width: 8), Text("SYSTEM ANALYSIS", style: TextStyle(color: theme.textColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))]),
                const SizedBox(height: 10),
                Text("Performance Peaking", style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text("You are on track to reach Level ${xpController.level + 1} by Friday.", style: TextStyle(color: theme.subText, fontSize: 12)),
                const SizedBox(height: 15),
                // Simple bar chart visual
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _bar(theme, 20, false), const SizedBox(width: 4),
                    _bar(theme, 30, false), const SizedBox(width: 4),
                    _bar(theme, 25, false), const SizedBox(width: 4),
                    _bar(theme, 45, true),
                  ],
                )
              ],
            ),
          ),
          // Character Image from screenshot
          SizedBox(
            width: 80, height: 80,
            child: Image.asset('assets/profile/astra_focused.png', fit: BoxFit.contain, errorBuilder: (c,e,s) => Icon(Icons.person, size: 40, color: theme.subText)),
          ),
        ],
      ),
    );
  }

  Widget _bar(ThemeManager theme, double height, bool active) {
    return Container(
      width: 8, height: height,
      decoration: BoxDecoration(
          color: active ? theme.accentColor : theme.subText.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4)
      ),
    );
  }
}

class _HunterBentoSection extends StatelessWidget {
  final int steps;
  final int completedTasks;
  final int totalTasks;
  const _HunterBentoSection({required this.steps, required this.completedTasks, required this.totalTasks});

  String _formatSteps(int steps) => steps > 1000 ? "${(steps / 1000).toStringAsFixed(1)}k" : steps.toString();

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager();
    return Row(
      children: [
        Expanded(child: _buildCard(theme, "STRENGTH", _formatSteps(steps), "Steps", Icons.directions_walk_rounded, const Color(0xFFFF5252), (steps / 10000).clamp(0.0, 1.0))),
        const SizedBox(width: 10),
        Expanded(child: _buildCard(theme, "INTELLECT", "$completedTasks/$totalTasks", "Missions", Icons.check_circle_outline_rounded, const Color(0xFF6C63FF), totalTasks > 0 ? (completedTasks / totalTasks) : 0.0)),
      ],
    );
  }

  Widget _buildCard(ThemeManager theme, String title, String value, String unit, IconData icon, Color color, double progress) {
    return Container(
      height: 90, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.textColor.withOpacity(0.05))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(children: [Icon(icon, color: color, size: 14), const SizedBox(width: 6), Text(title, style: TextStyle(color: theme.subText, fontSize: 9, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: theme.textColor, fontSize: 16, fontWeight: FontWeight.bold, fontFeatures: const [FontFeature.tabularFigures()])),
            Text(unit, style: TextStyle(color: theme.subText, fontSize: 10)),
          ]),
          SizedBox(width: 34, height: 34, child: Stack(alignment: Alignment.center, children: [CircularProgressIndicator(value: progress, strokeWidth: 3, backgroundColor: theme.subText.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(color))])),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();
  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager();
    return Row(
      children: [
        _miniTile(theme, Icons.water_drop_rounded, "1.2L", "Water", const Color(0xFF00D2D3)),
        const SizedBox(width: 10),
        _miniTile(theme, Icons.task_alt_rounded, "5/5", "Tasks", const Color(0xFFFFD700)),
        const SizedBox(width: 10),
        _miniTile(theme, Icons.nightlight_round, "7h", "Sleep", const Color(0xFFC56CF0)),
      ],
    );
  }

  Widget _miniTile(ThemeManager theme, IconData icon, String val, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 14, color: color)),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: TextStyle(color: theme.subText, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _DailyQuestSection extends StatelessWidget {
  final List<Task> tasks;
  final Function(String id) onQuestToggle;
  final Function(String id) onQuestDelete;

  const _DailyQuestSection({required this.tasks, required this.onQuestToggle, required this.onQuestDelete});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager();
    return Column(
      children: [
        // Start Focus Button from screenshot
        Container(
          width: double.infinity, height: 60,
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
          ),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.accentColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.timer_outlined, color: theme.accentColor)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text("START FOCUS", style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)), Text("0h 0m focused today", style: TextStyle(color: theme.subText, fontSize: 12))])),
              Icon(Icons.play_circle_fill_rounded, size: 32, color: theme.textColor),
            ],
          ),
        ),

        Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("ACTIVE PROTOCOLS", style: TextStyle(color: theme.textColor, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          Text("${tasks.where((t) => !t.isCompleted).length} PENDING", style: TextStyle(color: theme.subText, fontSize: 12, fontWeight: FontWeight.bold)),
        ])),
        const SizedBox(height: 16),
        tasks.isEmpty
            ? Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text("NO ACTIVE MISSIONS", style: TextStyle(color: theme.subText, letterSpacing: 2, fontWeight: FontWeight.bold))))
            : ListView.builder(
          padding: EdgeInsets.zero, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _QuestTile(task: task, index: index, onTap: () => onQuestToggle(task.id), onDelete: () => onQuestDelete(task.id));
          },
        ),
      ],
    );
  }
}

// --- QUEST TILE ---
class _QuestTile extends StatefulWidget {
  final Task task;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _QuestTile({required this.task, required this.index, required this.onTap, required this.onDelete});

  @override
  State<_QuestTile> createState() => _QuestTileState();
}

class _QuestTileState extends State<_QuestTile> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150), lowerBound: 0.95, upperBound: 1.0)..value = 1.0;
  }

  void _handleTap() async {
    await _scaleController.reverse();
    await _scaleController.forward();
    widget.onTap();
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'strength': return const Color(0xFFFF5252);
      case 'intellect': return const Color(0xFF6C63FF);
      case 'vitality': return const Color(0xFF00D2D3);
      case 'spirit': return const Color(0xFFFFD700);
      default: return const Color(0xFF54A0FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager();
    final accent = _getCategoryColor(widget.task.category);

    return Dismissible(
      key: ValueKey(widget.task.id),
      direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.delete_outline, color: Colors.white)),
      onDismissed: (_) => widget.onDelete(),
      child: GestureDetector(
        onTap: _handleTap,
        child: ScaleTransition(
          scale: _scaleController,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: widget.task.isCompleted ? accent.withOpacity(0.15) : theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.task.isCompleted ? accent.withOpacity(0.6) : theme.textColor.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: widget.task.isCompleted ? accent : accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: widget.task.isCompleted ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : Icon(Icons.circle_outlined, color: accent, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.task.title, style: TextStyle(color: widget.task.isCompleted ? theme.subText : theme.textColor, fontWeight: FontWeight.bold, fontSize: 16, decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null)),
                      const SizedBox(height: 4),
                      Text(widget.task.category.toUpperCase(), style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: theme.bgColor, borderRadius: BorderRadius.circular(8)),
                  child: Text("+${widget.task.xpReward} XP", style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                IconButton(onPressed: widget.onDelete, icon: Icon(Icons.delete_forever_rounded, color: theme.subText.withOpacity(0.3), size: 20), visualDensity: VisualDensity.compact),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SideQuestSection extends StatelessWidget {
  final VoidCallback onTap;
  const _SideQuestSection({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager();
    return GestureDetector(
      onTap: onTap,
      child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: theme.textColor.withOpacity(0.02), borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.textColor.withOpacity(0.1), width: 1.5)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle_outline_rounded, color: theme.subText, size: 20), const SizedBox(width: 8), Text("ACCEPT NEW MISSION", style: TextStyle(color: theme.subText, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5))])),
    );
  }
}