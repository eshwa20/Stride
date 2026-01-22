import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../theme/theme_manager.dart';

// Services
import '../services/notification_service.dart';

// Modals
import '../home/dashboard/modals/add_project_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Track events in state
  final Map<DateTime, List<Map<String, dynamic>>> _events = {
    DateTime.utc(2025, 1, 15): [
      {'id': 101, 'type': 1, 'title': 'Flutter Prototype', 'expected': '4h', 'actual': '5.5h'}
    ],
    DateTime.utc(2025, 1, 20): [
      {'id': 102, 'type': 2, 'title': "Astra's Creation Day"}
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    NotificationService.init();
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  // --- NEW: DELETE FUNCTION ---
  void _deleteEvent(DateTime day, Map<String, dynamic> event) async {
    final utcDate = DateTime.utc(day.year, day.month, day.day);
    
    setState(() {
      _events[utcDate]?.removeWhere((e) => e['id'] == event['id']);
      if (_events[utcDate]!.isEmpty) {
        _events.remove(utcDate);
      }
    });

    // Cancel the notification using the stored ID
    await NotificationService.cancelNotification(event['id']);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Mission '${event['title']}' aborted."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _openAddProjectSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddProjectSheet(),
    );

    if (result != null) {
      final String title = result['title'];
      final DateTime date = result['date'];
      final DateTime utcDate = DateTime.utc(date.year, date.month, date.day);
      
      // Generate a unique ID for the notification and local list
      final int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      setState(() {
        if (_events[utcDate] == null) _events[utcDate] = [];
        _events[utcDate]!.add({
          'id': id,
          'type': 1,
          'title': title,
          'expected': 'TBD',
          'actual': '0h',
        });
        _selectedDay = utcDate;
        _focusedDay = utcDate;
      });

      await NotificationService.scheduleDeadlineNotification(
        id: id,
        title: title,
        date: date,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, child) {
        final theme = ThemeManager();
        const Color accentRed = Color(0xFFFF5252);
        const Color accentGold = Color(0xFFFFD700);

        return Scaffold(
          backgroundColor: theme.bgColor,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 80.0),
            child: FloatingActionButton.extended(
              onPressed: _openAddProjectSheet,
              backgroundColor: accentRed,
              icon: const Icon(Icons.add_task, color: Colors.white),
              label: const Text("NEW OP", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    "OPERATION TIMELINE",
                    style: TextStyle(color: theme.subText, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                ),
                const SizedBox(height: 20),
                
                // --- CALENDAR CARD ---
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.textColor.withOpacity(0.05)),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    rowHeight: 52,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    eventLoader: _getEventsForDay,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    calendarStyle: CalendarStyle(
                      markerDecoration: BoxDecoration(color: theme.accentColor, shape: BoxShape.circle),
                      selectedDecoration: BoxDecoration(color: theme.accentColor, shape: BoxShape.circle),
                      todayDecoration: BoxDecoration(border: Border.all(color: theme.accentColor), shape: BoxShape.circle),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- MISSION LOG ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Container(width: 3, height: 14, color: theme.accentColor),
                      const SizedBox(width: 8),
                      Text(
                        "MISSION LOG: ${DateFormat('MMM d').format(_selectedDay ?? DateTime.now()).toUpperCase()}",
                        style: TextStyle(color: theme.subText, fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      ..._getEventsForDay(_selectedDay ?? DateTime.now()).map((event) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: event['type'] == 1 
                              ? _buildDeadlineCard(theme, event, _selectedDay!) 
                              : _buildBirthdayCard(theme, event, accentGold, _selectedDay!),
                        );
                      }),
                      if (_getEventsForDay(_selectedDay ?? DateTime.now()).isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40.0),
                            child: Text("NO OPERATIONS SCHEDULED", 
                                style: TextStyle(color: theme.subText.withOpacity(0.5), fontWeight: FontWeight.bold)),
                          ),
                        ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- UPDATED WIDGET BUILDERS WITH DELETE ICON ---

  Widget _buildDeadlineCard(ThemeManager theme, Map<String, dynamic> event, DateTime day) {
    Color color = const Color(0xFFFF5252);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.textColor.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.timer_off_outlined, color: color, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event['title'], style: TextStyle(color: theme.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                      Text("Critical Deadline", style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _deleteEvent(day, event),
                icon: Icon(Icons.delete_sweep_outlined, color: theme.subText.withOpacity(0.5), size: 20),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatColumn(theme, "EXPECTED", event['expected'] ?? 'TBD', theme.textColor)),
              Container(width: 1, height: 24, color: theme.subText.withOpacity(0.2)),
              Expanded(child: _buildStatColumn(theme, "ACTUAL", event['actual'] ?? '0h', color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBirthdayCard(ThemeManager theme, Map<String, dynamic> event, Color color, DateTime day) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.cake_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event['title'], style: TextStyle(color: theme.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                  Text("Guild Member Anniversary", style: TextStyle(color: theme.subText, fontSize: 11)),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () => _deleteEvent(day, event),
            icon: Icon(Icons.delete_sweep_outlined, color: theme.subText.withOpacity(0.5), size: 20),
          )
        ],
      ),
    );
  }

  Widget _buildStatColumn(ThemeManager theme, String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: theme.subText, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}