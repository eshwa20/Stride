import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'timer_service.dart';
import 'timer_statistics_screen.dart';
import 'floating_timer_widget.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with TickerProviderStateMixin {
  // Timer Controllers
  late AnimationController _timerAnimationController;
  late Animation<double> _timerAnimation;

  // Timer State
  Timer? _timer;
  int _remainingSeconds = 25 * 60; // Default 25 minutes
  int _totalSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isBreak = false;

  // Timer Modes
  final List<Map<String, dynamic>> _presets = [
    {'name': 'Classic', 'focus': 25, 'shortBreak': 5, 'longBreak': 15},
    {'name': 'Deep Focus', 'focus': 50, 'shortBreak': 10, 'longBreak': 20},
    {'name': 'Quick', 'focus': 15, 'shortBreak': 3, 'longBreak': 10},
  ];

  // Audio & Notifications
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Settings and Statistics
  TimerSettings _settings = TimerSettings();
  TimerStatistics _stats = TimerStatistics();
  int _currentSession = 0;

  // UI State
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _initializeTimerAnimation();
    _loadData();
  }

  void _initializeTimerAnimation() {
    _timerAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    );

    _timerAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_timerAnimationController);
  }

  Future<void> _loadData() async {
    _settings = await TimerService.loadSettings();
    _stats = await TimerService.loadStatistics();
    setState(() {
      _remainingSeconds = _settings.focusMinutes * 60;
      _totalSeconds = _remainingSeconds;
    });
    _resetTimer();
  }

  Future<void> _saveSettings() async {
    await TimerService.saveSettings(_settings);
  }

  Future<void> _saveStatistics() async {
    await TimerService.saveStatistics(_stats);
  }

  void _applyPreset(String presetName) {
    final preset = _presets.firstWhere((p) => p['name'] == presetName);
    setState(() {
      _settings.focusMinutes = preset['focus'];
      _settings.shortBreakMinutes = preset['shortBreak'];
      _settings.longBreakMinutes = preset['longBreak'];
      _settings.selectedPreset = presetName;
    });
    _resetTimer();
    _saveSettings();
  }

  void _startTimer() {
    if (_remainingSeconds > 0) {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
      _timerAnimationController.forward(from: (_totalSeconds - _remainingSeconds) / _totalSeconds);
    }
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
      _isPaused = true;
    });
    _timer?.cancel();
    _timerAnimationController.stop();
  }

  void _resumeTimer() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    _timerAnimationController.forward();
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _remainingSeconds = _isBreak ? _getBreakDuration() * 60 : _settings.focusMinutes * 60;
      _totalSeconds = _remainingSeconds;
    });
    _timerAnimationController.reset();
    _initializeTimerAnimation();
  }

  void _tick(Timer timer) {
    if (_remainingSeconds > 0) {
      setState(() => _remainingSeconds--);
    } else {
      _timerComplete();
    }
  }

  void _timerComplete() {
    _timer?.cancel();
    _playNotificationSound();
    _vibrate();

    if (!_isBreak) {
      // Focus session completed
      _currentSession++;
      _stats.totalSessionsCompleted++;
      TimerService.updateDailyStats(_settings.focusMinutes);

      // Award XP
      final xpGained = TimerService.calculateXpGain(_settings.focusMinutes, true);
      _stats.totalXpEarned += xpGained;

      // Check for long break
      if (_currentSession % _settings.sessionsBeforeLongBreak == 0) {
        _startBreak(_settings.longBreakMinutes);
      } else {
        _startBreak(_settings.shortBreakMinutes);
      }
    } else {
      // Break completed, start next focus session
      _startFocusSession();
    }

    _saveStatistics();
  }

  void _startBreak(int minutes) {
    setState(() {
      _isBreak = true;
      _remainingSeconds = minutes * 60;
      _totalSeconds = minutes * 60;
      _isRunning = false;
      _isPaused = false;
    });
    _timerAnimationController.reset();
    _initializeTimerAnimation();
  }

  void _startFocusSession() {
    setState(() {
      _isBreak = false;
      _remainingSeconds = _settings.focusMinutes * 60;
      _totalSeconds = _settings.focusMinutes * 60;
      _isRunning = false;
      _isPaused = false;
    });
    _timerAnimationController.reset();
    _initializeTimerAnimation();
  }

  int _getBreakDuration() {
    return (_currentSession % _settings.sessionsBeforeLongBreak == 0)
        ? _settings.longBreakMinutes
        : _settings.shortBreakMinutes;
  }

  Future<void> _playNotificationSound() async {
    if (!_settings.soundEnabled) return;

    try {
      await _audioPlayer.play(AssetSource('sounds/${_settings.selectedSound}.mp3'));
    } catch (e) {
      // Fallback to system sound
    }
  }

  Future<void> _vibrate() async {
    if (_settings.vibrationEnabled && await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 500);
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerAnimationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Focus Timer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.bar_chart,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TimerStatisticsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _showSettings ? Icons.close : Icons.settings,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _showSettings = !_showSettings),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.5),
            radius: 1.3,
            colors: [Color(0xFF0F3D2E), Colors.black],
          ),
        ),
        child: _showSettings
            ? _buildSettingsView()
            : _settings.alwaysOnDisplay && (_isRunning || _isPaused)
                ? AlwaysOnTimerOverlay(
                    remainingSeconds: _remainingSeconds,
                    isRunning: _isRunning,
                    isBreak: _isBreak,
                    onTap: () => setState(() => _showSettings = false),
                  )
                : _buildTimerView(),
      ),
    );
  }

  Widget _buildTimerView() {
    final progress = (_totalSeconds - _remainingSeconds) / _totalSeconds;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Timer Display
          const SizedBox(height: 40), // Space from top
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Circular Progress
                SizedBox(
                  width: 280,
                  height: 280,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isBreak ? Colors.green : Colors.blue,
                    ),
                  ),
                ),

                // Timer Text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isBreak ? 'Break Time' : 'Focus Session',
                      style: TextStyle(
                        fontSize: 18,
                        color: _isBreak ? Colors.green : Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_isBreak) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Session ${_currentSession + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 60), // Space between timer and controls

          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isRunning && !_isPaused) ...[
                // Start Button
                ElevatedButton.icon(
                  onPressed: _startTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isBreak ? Colors.green : Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ] else if (_isRunning) ...[
                // Pause Button
                ElevatedButton.icon(
                  onPressed: _pauseTimer,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ] else ...[
                // Resume Button
                ElevatedButton.icon(
                  onPressed: _resumeTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Resume'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isBreak ? Colors.green : Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],

              const SizedBox(width: 16),

              // Reset Button
              OutlinedButton.icon(
                onPressed: _resetTimer,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Statistics Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Today', '${_stats.dailyFocusMinutes}m'),
                _buildStatItem('Streak', '${_stats.currentStreak}d'),
                _buildStatItem('XP', _stats.totalXpEarned.toString()),
                _buildStatItem('Sessions', _stats.totalSessionsCompleted.toString()),
              ],
            ),
          ),
          const SizedBox(height: 40), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
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

  Widget _buildSettingsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timer Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Presets
          const Text(
            'Presets',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _presets.map((preset) {
              return ChoiceChip(
                label: Text(preset['name']),
                selected: _settings.selectedPreset == preset['name'],
                onSelected: (selected) {
                  if (selected) _applyPreset(preset['name']);
                },
                backgroundColor: Colors.white.withOpacity(0.1),
                selectedColor: Colors.blue,
                labelStyle: TextStyle(
                  color: _settings.selectedPreset == preset['name'] ? Colors.white : Colors.grey,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Custom Durations
          const Text(
            'Custom Durations (minutes)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          _buildDurationSetting('Focus Session', _settings.focusMinutes, (value) {
            setState(() => _settings.focusMinutes = value);
            _saveSettings();
          }),

          const SizedBox(height: 16),

          _buildDurationSetting('Short Break', _settings.shortBreakMinutes, (value) {
            setState(() => _settings.shortBreakMinutes = value);
            _saveSettings();
          }),

          const SizedBox(height: 16),

          _buildDurationSetting('Long Break', _settings.longBreakMinutes, (value) {
            setState(() => _settings.longBreakMinutes = value);
            _saveSettings();
          }),

          const SizedBox(height: 32),

          // Sessions Before Long Break
          const Text(
            'Sessions Before Long Break',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: _settings.sessionsBeforeLongBreak.toDouble(),
            min: 2,
            max: 8,
            divisions: 6,
            label: _settings.sessionsBeforeLongBreak.toString(),
            onChanged: (value) {
              setState(() => _settings.sessionsBeforeLongBreak = value.toInt());
              _saveSettings();
            },
          ),

          const SizedBox(height: 32),

          // Sound Settings
          const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Sound', style: TextStyle(color: Colors.white)),
            value: _settings.soundEnabled,
            onChanged: (value) {
              setState(() => _settings.soundEnabled = value);
              _saveSettings();
            },
            activeColor: Colors.blue,
          ),

          SwitchListTile(
            title: const Text('Vibration', style: TextStyle(color: Colors.white)),
            value: _settings.vibrationEnabled,
            onChanged: (value) {
              setState(() => _settings.vibrationEnabled = value);
              _saveSettings();
            },
            activeColor: Colors.blue,
          ),

          SwitchListTile(
            title: const Text('Always-on Display', style: TextStyle(color: Colors.white)),
            value: _settings.alwaysOnDisplay,
            onChanged: (value) {
              setState(() => _settings.alwaysOnDisplay = value);
              _saveSettings();
            },
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSetting(String label, int value, Function(int) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove, color: Colors.white),
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
            ),
            Container(
              width: 60,
              alignment: Alignment.center,
              child: Text(
                value.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: value < 120 ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}