import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// Theme & Controllers
import '../../theme/theme_manager.dart';
import '../../controllers/xp_controller.dart';

// Services
import '../../services/pdf_service.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with TickerProviderStateMixin {
  // Chart State
  int _selectedChart = 0; // 0=Flow, 1=Radar, 2=Span
  String _timeHorizon = "WEEK"; // DAY, WEEK, MONTH, YEAR

  // Toggle Visibility State
  bool _showStreak = true;
  bool _showPerformance = true;
  bool _showMomentum = true;
  bool _showInsights = true;

  // Real Data Containers
  Map<int, int> _hourlyFocusData = {};
  List<int> _sessionDurations = [];
  List<bool> _weeklyStreak = List.filled(7, false);
  int _totalFocusMinutesToday = 0;

  // Momentum Data
  int _thisWeekTotalMins = 0;
  int _lastWeekTotalMins = 0;
  double _trendPercentage = 0.0;
  bool _isImproving = true;

  // Animations
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);

    // LOAD REAL DATA
    _loadDatabaseData();
  }

  Future<void> _loadDatabaseData() async {
    var statsBox = await Hive.openBox('statsBox');

    DateTime now = DateTime.now();
    String todayKey = DateFormat('yyyy-MM-dd').format(now);

    // Load Data
    Map<dynamic, dynamic> rawHourly = statsBox.get('hourly_$todayKey', defaultValue: {});
    List<int> rawSessions = List<int>.from(statsBox.get('session_logs', defaultValue: []));

    // Calculate Momentum
    int thisWeekSum = 0;
    int lastWeekSum = 0;

    for (int i = 0; i < 7; i++) {
      String key = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: i)));
      Map<dynamic, dynamic> dayData = statsBox.get('hourly_$key', defaultValue: {});
      int dayTotal = dayData.values.fold(0, (sum, val) => (sum as int) + (val as int));
      thisWeekSum += dayTotal;
      if (i < 7) _weeklyStreak[6 - i] = dayTotal > 0;
    }

    for (int i = 7; i < 14; i++) {
      String key = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: i)));
      Map<dynamic, dynamic> dayData = statsBox.get('hourly_$key', defaultValue: {});
      int dayTotal = dayData.values.fold(0, (sum, val) => (sum as int) + (val as int));
      lastWeekSum += dayTotal;
    }

    double trend = 0.0;
    if (lastWeekSum == 0) {
      trend = thisWeekSum > 0 ? 100.0 : 0.0;
    } else {
      trend = ((thisWeekSum - lastWeekSum) / lastWeekSum) * 100;
    }

    if (mounted) {
      setState(() {
        _hourlyFocusData = rawHourly.map((key, value) => MapEntry(key as int, value as int));
        _totalFocusMinutesToday = _hourlyFocusData.values.fold(0, (sum, val) => sum + val);
        _sessionDurations = rawSessions;
        _thisWeekTotalMins = thisWeekSum;
        _lastWeekTotalMins = lastWeekSum;
        _trendPercentage = trend;
        _isImproving = trend >= 0;
        _isLoading = false;
      });
      _entranceController.forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  // --- CONFIG SHEET ---
  void _openFilterSheet(ThemeManager theme) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setSheetState) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.subText.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Icon(Icons.tune_rounded, color: theme.accentColor),
                          const SizedBox(width: 12),
                          Text("DASHBOARD CONFIG", style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 30),

                      Text("TIME HORIZON", style: TextStyle(color: theme.subText, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      const SizedBox(height: 12),
                      Row(
                        children: ["DAY", "WEEK", "MONTH", "YEAR"].map((label) {
                          bool isSelected = _timeHorizon == label;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setSheetState(() => _timeHorizon = label);
                                setState(() => _timeHorizon = label);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? theme.accentColor : theme.bgColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isSelected ? theme.accentColor : theme.subText.withOpacity(0.1)),
                                ),
                                alignment: Alignment.center,
                                child: Text(label, style: TextStyle(color: isSelected ? Colors.white : theme.subText, fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 30),

                      Text("ACTIVE MODULES", style: TextStyle(color: theme.subText, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      const SizedBox(height: 12),

                      _buildSwitchTile(theme, "Streak Log", _showStreak, (val) {
                        setSheetState(() => _showStreak = val);
                        setState(() => _showStreak = val);
                      }),
                      _buildSwitchTile(theme, "Elite Performance", _showPerformance, (val) {
                        setSheetState(() => _showPerformance = val);
                        setState(() => _showPerformance = val);
                      }),
                      _buildSwitchTile(theme, "Growth Velocity", _showMomentum, (val) {
                        setSheetState(() => _showMomentum = val);
                        setState(() => _showMomentum = val);
                      }),
                      _buildSwitchTile(theme, "AI Insights", _showInsights, (val) {
                        setSheetState(() => _showInsights = val);
                        setState(() => _showInsights = val);
                      }),

                      const SizedBox(height: 40),

                      // --- EXPORT BUTTON (ENABLED) ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context); // Close sheet

                            // Get Real Data from Provider
                            final xpController = Provider.of<XpController>(context, listen: false);

                            // Trigger PDF Service
                            await PdfService.exportReport(
                              totalMinutes: _totalFocusMinutesToday,
                              currentXp: xpController.currentXp,
                              level: xpController.level,
                              attributes: xpController.attributes,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.textColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: Icon(Icons.download_rounded, color: theme.bgColor),
                          label: Text("EXPORT REPORT (PDF)", style: TextStyle(color: theme.bgColor, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              }
          );
        }
    );
  }

  Widget _buildSwitchTile(ThemeManager theme, String label, bool isActive, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 14)),
          Switch(
            value: isActive,
            activeColor: theme.accentColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final xpController = context.watch<XpController>();

    return ListenableBuilder(
        listenable: ThemeManager(),
        builder: (context, child) {
          final theme = ThemeManager();
          return Scaffold(
            backgroundColor: theme.bgColor,
            body: SafeArea(
              bottom: false,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: theme.accentColor))
                  : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildCustomHeader(theme),
                    const SizedBox(height: 30),

                    if (_showStreak) ...[
                      _buildSectionHeader("STREAK LOG", Icons.calendar_month_rounded, theme),
                      const SizedBox(height: 15),
                      _buildStreakCalendar(theme),
                      const SizedBox(height: 30),
                    ],

                    if (_showPerformance) ...[
                      _buildPerformanceScore(theme, xpController),
                      const SizedBox(height: 30),
                    ],

                    _buildChartToggle(theme),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: _buildSelectedChart(theme, xpController),
                    ),
                    const SizedBox(height: 30),

                    _buildOverviewSection(theme, xpController),
                    const SizedBox(height: 30),

                    if (_showMomentum) ...[
                      _buildSectionHeader("GROWTH VELOCITY", Icons.trending_up_rounded, theme),
                      const SizedBox(height: 15),
                      _buildMomentumCard(theme),
                      const SizedBox(height: 30),
                    ],

                    _buildAttentionSpanCard(theme),
                    const SizedBox(height: 30),

                    if (_showInsights) ...[
                      _buildAIInsights(theme),
                      const SizedBox(height: 120),
                    ] else ...[
                      const SizedBox(height: 120),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
    );
  }

  // --- WIDGETS ---

  Widget _buildCustomHeader(ThemeManager theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 40),
        Text(
            "COMMAND CENTER",
            style: TextStyle(
                color: theme.subText,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.5
            )
        ),
        IconButton(
          icon: Icon(Icons.tune_rounded, color: theme.subText),
          onPressed: () => _openFilterSheet(theme),
          splashRadius: 20,
        ),
      ],
    );
  }

  Widget _buildSelectedChart(ThemeManager theme, XpController xp) {
    switch (_selectedChart) {
      case 0: return _buildFocusFlowChart(theme);
      case 1: return _buildRadarChart(theme, xp);
      case 2: return _buildAttentionSpanChart(theme);
      default: return _buildFocusFlowChart(theme);
    }
  }

  Widget _buildStreakCalendar(ThemeManager theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          bool isActive = _weeklyStreak[index];
          bool isToday = index == 6;

          return Column(
            children: [
              Text(_getDayInitial(index), style: TextStyle(color: theme.subText, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                height: 32, width: 32,
                decoration: BoxDecoration(
                  color: isToday ? theme.accentColor : (isActive ? Colors.green.withOpacity(0.15) : theme.bgColor),
                  shape: BoxShape.circle,
                  border: isToday ? null : Border.all(color: isActive ? Colors.green : theme.subText.withOpacity(0.1)),
                ),
                child: isActive ? Icon(Icons.check, size: 16, color: isToday ? Colors.white : Colors.green) : null,
              ),
            ],
          );
        }),
      ),
    );
  }

  String _getDayInitial(int index) {
    DateTime day = DateTime.now().subtract(Duration(days: 6 - index));
    return DateFormat('E').format(day)[0];
  }

  Widget _buildPerformanceScore(ThemeManager theme, XpController xp) {
    double score = (xp.currentXp % 1000) / 10;
    if (score > 100) score = 100;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.accentColor.withOpacity(0.1), theme.cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.accentColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 80, width: 80,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 80, height: 80,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      backgroundColor: theme.subText.withOpacity(0.1),
                      color: theme.accentColor,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
                Center(child: Text(score.toInt().toString(), style: TextStyle(color: theme.textColor, fontSize: 22, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ELITE PERFORMANCE", style: TextStyle(color: theme.accentColor, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text("Based on your XP gain today. Keep grinding to maintain Elite status.", style: TextStyle(color: theme.subText, fontSize: 12, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChartToggle(ThemeManager theme) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.subText.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          _buildToggleBtn(theme, "FLOW", 0),
          _buildToggleBtn(theme, "STATS", 1),
          _buildToggleBtn(theme, "SPAN", 2),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(ThemeManager theme, String text, int index) {
    bool isSelected = _selectedChart == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedChart = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? theme.accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(text, style: TextStyle(color: isSelected ? Colors.white : theme.subText, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
        ),
      ),
    );
  }

  Widget _buildFocusFlowChart(ThemeManager theme) {
    List<FlSpot> spots = [];
    for (int i = 0; i < 24; i++) {
      spots.add(FlSpot(i.toDouble(), (_hourlyFocusData[i] ?? 0).toDouble()));
    }

    return Container(
      key: const ValueKey("EKG"),
      height: 280,
      padding: const EdgeInsets.fromLTRB(10, 25, 20, 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.subText.withOpacity(0.05)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: theme.subText.withOpacity(0.05), strokeWidth: 1, dashArray: [5, 5])),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 4,
                getTitlesWidget: (value, meta) => Padding(padding: const EdgeInsets.only(top: 8.0), child: Text("${value.toInt()}h", style: TextStyle(color: theme.subText, fontSize: 10, fontWeight: FontWeight.bold))),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots.isEmpty ? [const FlSpot(0,0)] : spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: theme.accentColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [theme.accentColor.withOpacity(0.3), theme.accentColor.withOpacity(0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          minX: 0, maxX: 24, minY: 0, maxY: 60,
        ),
      ),
    );
  }

  Widget _buildRadarChart(ThemeManager theme, XpController xp) {
    return Container(
      key: const ValueKey("RADAR"),
      height: 280,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.subText.withOpacity(0.05)),
      ),
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          ticksTextStyle: const TextStyle(color: Colors.transparent),
          gridBorderData: BorderSide(color: theme.subText.withOpacity(0.1)),
          titlePositionPercentageOffset: 0.2,
          titleTextStyle: TextStyle(color: theme.textColor, fontSize: 10, fontWeight: FontWeight.bold),
          dataSets: [
            RadarDataSet(
              fillColor: theme.accentColor.withOpacity(0.2),
              borderColor: theme.accentColor,
              entryRadius: 2,
              dataEntries: [
                RadarEntry(value: xp.attributes['STR'] ?? 0),
                RadarEntry(value: xp.attributes['AGI'] ?? 0),
                RadarEntry(value: xp.attributes['INT'] ?? 0),
                RadarEntry(value: xp.attributes['VIT'] ?? 0),
                RadarEntry(value: xp.attributes['SEN'] ?? 0)
              ],
            )
          ],
          getTitle: (i, angle) {
            const titles = ['STR', 'AGI', 'INT', 'VIT', 'SEN'];
            return RadarChartTitle(text: titles[i]);
          },
        ),
      ),
    );
  }

  Widget _buildAttentionSpanChart(ThemeManager theme) {
    int short = 0;
    int sweet = 0;
    int deep = 0;
    int marathon = 0;

    for (var min in _sessionDurations) {
      if (min < 15) short++;
      else if (min < 30) sweet++;
      else if (min < 50) deep++;
      else marathon++;
    }

    return Container(
      key: const ValueKey("SPAN"),
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.subText.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("SESSION ENDURANCE", style: TextStyle(color: theme.subText, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text("REAL DATA", style: TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = ['<15m', '25m', '45m', '60m+'];
                        if (value.toInt() < labels.length) {
                          return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(labels[value.toInt()], style: TextStyle(color: theme.subText, fontSize: 10, fontWeight: FontWeight.bold)));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                barGroups: [
                  _makeSpanBar(0, short.toDouble(), theme, false),
                  _makeSpanBar(1, sweet.toDouble(), theme, true),
                  _makeSpanBar(2, deep.toDouble(), theme, false),
                  _makeSpanBar(3, marathon.toDouble(), theme, false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeSpanBar(int x, double y, ThemeManager theme, bool isSweetSpot) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isSweetSpot ? theme.accentColor : theme.subText.withOpacity(0.2),
          width: 24,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: 10, color: theme.bgColor),
        ),
      ],
    );
  }

  Widget _buildOverviewSection(ThemeManager theme, XpController xp) {
    int h = _totalFocusMinutesToday ~/ 60;
    int m = _totalFocusMinutesToday % 60;
    String timeStr = "${h}h ${m}m";

    return Row(
      children: [
        _buildSummaryCard(theme, "FOCUS TIME", timeStr, "TODAY", Colors.purple),
        const SizedBox(width: 12),
        _buildSummaryCard(theme, "TOTAL XP", xp.currentXp.toString(), "Lvl ${xp.level}", Colors.orange),
      ],
    );
  }

  Widget _buildSummaryCard(ThemeManager theme, String title, String value, String trend, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.subText.withOpacity(0.05)),
          boxShadow: theme.isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.bolt_rounded, color: color, size: 20),
                Text(trend, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(color: theme.textColor, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: theme.subText, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentumCard(ThemeManager theme) {
    String thisWeekStr = "${(_thisWeekTotalMins / 60).toStringAsFixed(1)}h";
    String lastWeekStr = "${(_lastWeekTotalMins / 60).toStringAsFixed(1)}h";

    String trendStr = _trendPercentage.isInfinite ? "NEW" : "${_trendPercentage.abs().toStringAsFixed(1)}%";
    String statusStr = _isImproving ? "IMPROVING" : "DECLINING";
    Color statusColor = _isImproving ? Colors.green : Colors.redAccent;
    String sign = _isImproving ? "+" : "-";
    if (_trendPercentage.isInfinite) sign = "+";

    double maxVal = (_thisWeekTotalMins > _lastWeekTotalMins ? _thisWeekTotalMins : _lastWeekTotalMins).toDouble();
    if (maxVal == 0) maxVal = 1;
    double thisWeekPct = _thisWeekTotalMins / maxVal;
    double lastWeekPct = _lastWeekTotalMins / maxVal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.subText.withOpacity(0.05)),
        boxShadow: theme.isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("WEEKLY TREND", style: TextStyle(color: theme.subText, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text("$sign$trendStr", style: TextStyle(color: statusColor, fontSize: 28, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(statusStr, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ],
              ),
              Icon(Icons.rocket_launch_rounded, color: theme.accentColor, size: 32),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressBar(theme, "This Week", thisWeekPct, theme.accentColor, thisWeekStr),
          const SizedBox(height: 12),
          _buildProgressBar(theme, "Last Week", lastWeekPct, theme.subText.withOpacity(0.3), lastWeekStr),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ThemeManager theme, String label, double pct, Color color, String value) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: theme.subText, fontSize: 12)),
            Text(value, style: TextStyle(color: theme.textColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(color: theme.bgColor, borderRadius: BorderRadius.circular(4)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: pct > 1.0 ? 1.0 : pct,
            child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          ),
        ),
      ],
    );
  }

  Widget _buildAttentionSpanCard(ThemeManager theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.subText.withOpacity(0.05)),
        boxShadow: theme.isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader("ATTENTION SPAN", Icons.timelapse_rounded, theme),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: const Text("SWEET SPOT: 25m", style: TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(height: 180, child: _buildAttentionSpanChart(theme)),
          const SizedBox(height: 15),
          Text(
            "Insight: Based on your session logs, you are most consistent with 25m sprints.",
            style: TextStyle(color: theme.subText, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsights(ThemeManager theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF6C63FF), size: 18),
              const SizedBox(width: 8),
              Text("ASTRA INSIGHTS", style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "\"I've analyzed your trends. You're growing at ${_trendPercentage.abs().toStringAsFixed(1)}% this week. Great work!\"",
            style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.5, fontSize: 14, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeManager theme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.accentColor),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: theme.subText, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ],
    );
  }
}