import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

// 1. THE TASK MODEL
class Task {
  final String id;
  final String title;
  final String category;
  bool isCompleted;
  final int xpReward;

  Task({
    required this.id,
    required this.title,
    this.category = "General",
    this.isCompleted = false,
    this.xpReward = 50,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'isCompleted': isCompleted,
      'xpReward': xpReward,
    };
  }

  factory Task.fromMap(Map<dynamic, dynamic> map) {
    return Task(
      id: map['id'] ?? const Uuid().v4(),
      title: map['title'] ?? 'Untitled',
      category: map['category'] ?? 'General',
      isCompleted: map['isCompleted'] ?? false,
      xpReward: map['xpReward'] ?? 50,
    );
  }
}

// 2. THE CONTROLLER
class TaskController extends ChangeNotifier {
  List<Task> _tasks = [];
  final Box _box = Hive.box('tasks');

  List<Task> get tasks => _tasks;

  TaskController() {
    _loadTasks();
  }

  void _loadTasks() {
    if (_box.isEmpty) {
      _addDummyData();
    } else {
      _tasks = _box.values.map((e) => Task.fromMap(Map<String, dynamic>.from(e))).toList();
    }
    notifyListeners();
  }

  void _addDummyData() {
    final List<Map<String, String>> starters = [
      {"title": "Morning Run (2km)", "cat": "Strength"},
      {"title": "Read Neural Networks", "cat": "Intellect"},
      {"title": "Drink 2L Water", "cat": "Vitality"},
      {"title": "Meditation Sequence", "cat": "Spirit"},
      {"title": "Debug System Core", "cat": "Intellect"},
    ];

    for (var data in starters) {
      final task = Task(
          id: const Uuid().v4(),
          title: data["title"]!,
          category: data["cat"]!
      );
      _box.put(task.id, task.toMap());
      _tasks.add(task);
    }
  }

  // UPDATED ADD TASK
  void addTask(String title, {String category = "General"}) {
    final newTask = Task(
        id: const Uuid().v4(),
        title: title,
        category: category
    );
    _box.put(newTask.id, newTask.toMap());
    _tasks.add(newTask);
    notifyListeners();
  }

  void toggleTask(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      _box.put(_tasks[index].id, _tasks[index].toMap());
      notifyListeners();
    }
  }

  void deleteTask(String id) {
    _box.delete(id);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // --- THIS WAS MISSING: THE RESET METHOD ---
  Future<void> resetAllData() async {
    await _box.clear(); // Wipes the database
    _tasks.clear();     // Wipes local memory
    _addDummyData();    // Adds fresh starter tasks
    notifyListeners();  // Tells the UI to update
  }
}