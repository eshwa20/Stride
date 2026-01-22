import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_manager.dart';
import '../../services/step_tracker_service.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/xp_controller.dart';

// Sections
import 'dashboard/sections/header_section.dart';
import 'dashboard/sections/progress_section.dart';
import 'dashboard/sections/hunter_bento_section.dart';
import 'dashboard/sections/quick_actions_section.dart';
import 'dashboard/sections/daily_quest_section.dart';
import 'dashboard/sections/side_quest_section.dart';
import 'dashboard/modals/add_task_sheet.dart';

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  int _currentSteps = 0;
  final StepTrackerService _stepService = StepTrackerService();

  @override
  void initState() {
    super.initState();
    _initSteps();
  }

  void _initSteps() {
    _stepService.initService();
    if (mounted) setState(() => _currentSteps = _stepService.getSavedSteps());
    _stepService.stepStream.listen((steps) {
      if (mounted) setState(() => _currentSteps = steps);
    });
  }

  void _openNewMissionSheet(BuildContext context, TaskController controller) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTaskSheet(),
    );

    if (result != null && result['title'] != null) {
      controller.addTask(result['title']);
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
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const HeaderSection(),
                  const SizedBox(height: 28),
                  const ProgressSection(),
                  const SizedBox(height: 24),

                  HunterBentoSection(
                    steps: _currentSteps,
                    completedTasks: taskController.tasks.where((t) => t.isCompleted).length,
                    totalTasks: taskController.tasks.length,
                  ),

                  const SizedBox(height: 24),
                  const QuickActionsSection(),
                  const SizedBox(height: 32),

                  // FIX: Added onQuestDelete
                  DailyQuestSection(
                    quests: taskController.tasks,
                    onQuestToggle: (id) {
                      taskController.toggleTask(id);
                      final task = taskController.tasks.firstWhere((t) => t.id == id);
                      if (task.isCompleted) xpController.addXp(50);
                    },
                    onQuestDelete: (id) => taskController.deleteTask(id), // <--- ADDED THIS
                  ),

                  const SizedBox(height: 16),
                  SideQuestSection(onTap: () => _openNewMissionSheet(context, taskController)),
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