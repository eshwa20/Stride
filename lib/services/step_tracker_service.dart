import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class StepTrackerService {
  // Singleton Pattern
  static final StepTrackerService _instance = StepTrackerService._internal();
  factory StepTrackerService() => _instance;
  StepTrackerService._internal();

  final _box = Hive.box('stepBox');
  StreamSubscription<StepCount>? _stepSubscription;

  // Reactive Stream for UI to listen to
  final StreamController<int> _stepController = StreamController<int>.broadcast();
  Stream<int> get stepStream => _stepController.stream;

  // KEYS FOR DATABASE
  static const String _keyDaySteps = 'todaySteps';
  static const String _keyLastDate = 'lastDate';
  static const String _keyAnchor = 'anchorSteps'; // The sensor value at start of day

  Future<void> initService() async {
    // 1. Request Permissions
    if (await Permission.activityRecognition.request().isGranted) {
      _startListening();
    } else {
      print("Step Permission Denied");
    }
  }

  void _startListening() {
    _stepSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: (error) => print("Step Error: $error"),
    );
  }

  void _onStepCount(StepCount event) {
    int sensorSteps = event.steps;
    String today = DateTime.now().toIso8601String().split('T')[0]; // "2024-01-08"
    String? lastDate = _box.get(_keyLastDate);

    // --- MIDNIGHT RESET LOGIC ---
    if (lastDate != today) {
      // It's a new day!
      // 1. (Optional) Save yesterday's final count to a history list here
      // 2. Reset for today
      _box.put(_keyLastDate, today);
      _box.put(_keyAnchor, sensorSteps); // New Anchor for today
      _box.put(_keyDaySteps, 0); // Reset display to 0

      _stepController.add(0); // Update UI
    } else {
      // Same day: Calculate progress
      int anchor = _box.get(_keyAnchor, defaultValue: sensorSteps);
      int todaySteps = sensorSteps - anchor;

      // Prevent negative numbers (if phone rebooted)
      if (todaySteps < 0) {
        anchor = sensorSteps;
        _box.put(_keyAnchor, anchor);
        todaySteps = 0;
      }

      _box.put(_keyDaySteps, todaySteps); // Save progress
      _stepController.add(todaySteps); // Update UI
    }
  }

  // Get current value immediately (for when app first opens)
  int getSavedSteps() {
    // Check if we need to reset before returning (in case user opens app next day)
    String today = DateTime.now().toIso8601String().split('T')[0];
    String? lastDate = _box.get(_keyLastDate);

    if (lastDate != today) {
      return 0;
    }
    return _box.get(_keyDaySteps, defaultValue: 0);
  }
}