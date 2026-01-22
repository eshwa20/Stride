import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:intl/intl.dart';

import '../theme/theme_manager.dart';
import '../services/notification_service.dart';

class ClockScreen extends StatefulWidget {
  final int initialTabIndex;
  const ClockScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, child) {
        final theme = ThemeManager();
        return Scaffold(
          backgroundColor: theme.bgColor,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 30),
                Center(
                  child: Text("TEMPORAL SYSTEM",
                      style: TextStyle(color: theme.subText, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: theme.textColor.withOpacity(0.05)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: theme.accentColor,
                      borderRadius: BorderRadius.circular(21),
                      boxShadow: [BoxShadow(color: theme.accentColor.withOpacity(0.3), blurRadius: 10)],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: theme.subText,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                    tabs: const [Tab(text: "FOCUS"), Tab(text: "ALARM"), Tab(text: "STOPWATCH")],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [FocusTimerTab(), AlarmTab(), StopwatchTab()],
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

// --- FOCUS TIMER TAB ---
class FocusTimerTab extends StatefulWidget {
  const FocusTimerTab({super.key});
  @override
  State<FocusTimerTab> createState() => _FocusTimerTabState();
}

class _FocusTimerTabState extends State<FocusTimerTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Timer? _timer;
  int _initialSeconds = 1500;
  int _remainingSeconds = 1500;
  bool _isRunning = false;

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _stopTimer();
        _showCompletionDialog();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _stopTimer();
    setState(() => _remainingSeconds = _initialSeconds);
  }

  void _showCompletionDialog() {
    final theme = ThemeManager();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "MISSION COMPLETE",
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.accentColor, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        content: Text(
          "Focus session successful. Tactical rewards pending.",
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.textColor.withOpacity(0.8)),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _resetTimer();
              },
              child: Text("CLAIM XP", style: TextStyle(color: theme.accentColor, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = ThemeManager();
    String timeString = "${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}";
    double progress = _remainingSeconds / _initialSeconds;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // --- CIRCULAR FRAME ---
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 250,
              height: 250,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: theme.textColor.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation<Color>(theme.accentColor),
              ),
            ),
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.accentColor.withOpacity(0.2), width: 1),
              ),
              child: Center(
                child: Text(
                  timeString,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 60),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.refresh, color: theme.subText),
              onPressed: _resetTimer,
            ),
            const SizedBox(width: 30),
            FloatingActionButton.large(
              backgroundColor: theme.accentColor,
              onPressed: _isRunning ? _stopTimer : _startTimer,
              elevation: 4,
              child: Icon(
                _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(width: 30),
            // Placeholder to balance the refresh icon
            const SizedBox(width: 48),
          ],
        )
      ],
    );
  }
}

// --- ALARM TAB ---
class AlarmTab extends StatefulWidget {
  const AlarmTab({super.key});
  @override
  State<AlarmTab> createState() => _AlarmTabState();
}

class _AlarmTabState extends State<AlarmTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> alarms = [];
  List<Map<String, dynamic>> history = [];

  DateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = DateTime.now();
    DateTime scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  void _addAlarm() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context, 
      initialTime: TimeOfDay.now()
    );

    if (picked != null) {
      final int alarmId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final String label = 'Mission ${alarms.length + 1}';
      
      final newAlarm = {
        'id': alarmId, 
        'time': picked, 
        'label': label, 
        'isActive': true
      };

      setState(() {
        alarms.add(newAlarm);
        history.insert(0, {
          'label': label, 
          'time': picked, 
          'type': 'CREATED', 
          'at': DateTime.now()
        });
      });

      // FIXED: Calling scheduleAlarm with the now-supported 'body' parameter
      await NotificationService.scheduleAlarm(
        id: alarmId,
        title: "TEMPORAL NOTIFICATION",
        body: "$label is starting now.",
        scheduledTime: _nextInstanceOfTime(picked),
      );
    }
  }

  void _deleteAlarm(int index) {
    final deleted = alarms[index];
    setState(() {
      history.insert(0, {
        'label': deleted['label'], 
        'time': deleted['time'], 
        'type': 'DELETED', 
        'at': DateTime.now()
      });
      alarms.removeAt(index);
    });
    NotificationService.cancelNotification(deleted['id']);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = ThemeManager();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          onPressed: _addAlarm,
          backgroundColor: theme.accentColor,
          child: const Icon(Icons.add_alarm, color: Colors.white),
        ),
      ),
      body: ListView(
        // FIXED: Increased bottom padding (160) to ensure the list scrolls past bottom navigation
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 160), 
        children: [
          Text("ACTIVE MISSIONS", 
            style: TextStyle(color: theme.subText, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          
          if (alarms.isEmpty) 
            Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text("NO ACTIVE ALARMS", style: TextStyle(color: theme.subText.withOpacity(0.3))),
            )),

          ...alarms.asMap().entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor, 
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.textColor.withOpacity(0.05)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.value['time'].format(context), 
                          style: TextStyle(color: theme.textColor, fontSize: 32, fontWeight: FontWeight.bold)),
                        Text(e.value['label'], 
                          style: TextStyle(color: theme.subText, fontSize: 12)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent), 
                      onPressed: () => _deleteAlarm(e.key)
                    ),
                  ],
                ),
              )),
          
          const SizedBox(height: 40),
          Text("LOG HISTORY", 
            style: TextStyle(color: theme.subText, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 12),

          ...history.map((h) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  h['type'] == 'CREATED' ? Icons.add_circle_outline : Icons.remove_circle_outline, 
                  color: h['type'] == 'CREATED' ? theme.accentColor : Colors.redAccent.withOpacity(0.5), 
                  size: 18
                ),
                title: Text("${h['label']} (${h['time'].format(context)})", 
                  style: TextStyle(color: theme.textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text("${h['type']} AT ${DateFormat('HH:mm').format(h['at'])}", 
                  style: TextStyle(color: theme.subText, fontSize: 10)),
              )),
        ],
      ),
    );
  }
}

// --- STOPWATCH TAB ---
class StopwatchTab extends StatefulWidget {
  const StopwatchTab({super.key});
  @override
  State<StopwatchTab> createState() => _StopwatchTabState();
}

class _StopwatchTabState extends State<StopwatchTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  void _toggle() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _timer?.cancel();
    } else {
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(milliseconds: 30), (t) => setState(() {}));
    }
    setState(() {});
  }

  void _reset() {
    _stopwatch.reset();
    if (!_stopwatch.isRunning) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = ThemeManager();
    final elapsed = _stopwatch.elapsed;
    String display = "${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}.${(elapsed.inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0')}";

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(display,
            style: TextStyle(color: theme.textColor, fontSize: 64, fontWeight: FontWeight.bold, fontFeatures: const [FontFeature.tabularFigures()])),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(icon: Icon(Icons.refresh, color: theme.subText), onPressed: _reset),
            const SizedBox(width: 20),
            IconButton(icon: Icon(_stopwatch.isRunning ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 64, color: theme.accentColor), onPressed: _toggle),
          ],
        ),
      ],
    );
  }
}