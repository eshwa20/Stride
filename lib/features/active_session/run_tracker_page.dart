import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
// ✅ FIXED: We hide 'Path' from this library so it doesn't conflict with Flutter's drawing Path
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../theme/theme_manager.dart';

class RunTrackerPage extends StatefulWidget {
  final String taskName;

  const RunTrackerPage({super.key, required this.taskName});

  @override
  State<RunTrackerPage> createState() => _RunTrackerPageState();
}

class _RunTrackerPageState extends State<RunTrackerPage> {
  final ScreenshotController _screenshotController = ScreenshotController();

  // 📍 LOCATION DATA
  List<LatLng> _routePoints = [];
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;

  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 2,
  );

  // 👣 STEP DATA
  StreamSubscription<StepCount>? _stepStream;
  int _initialSteps = -1;
  int _currentSteps = 0;

  // ⏱️ TIMER & STATS
  Timer? _timer;
  Duration _duration = Duration.zero;
  double _totalDistanceKm = 0.0;
  double _caloriesBurned = 0.0;
  String _currentPace = "0'00\"";

  bool _isPaused = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndStart();
  }

  Future<void> _checkPermissionsAndStart() async {
    await [
      Permission.location,
      Permission.activityRecognition,
      Permission.storage,
    ].request();

    _startTimer();
    _startLocationTracking();
    _startStepTracking();

    setState(() => _isLoading = false);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _duration += const Duration(seconds: 1);
          _updatePace();
        });
      }
    });
  }

  void _startLocationTracking() async {
    _positionStream = Geolocator.getPositionStream(locationSettings: _locationSettings)
        .listen((Position position) {
      if (_isPaused) return;

      LatLng newPoint = LatLng(position.latitude, position.longitude);

      setState(() {
        if (_routePoints.isNotEmpty) {
          double dist = Geolocator.distanceBetween(
            _routePoints.last.latitude, _routePoints.last.longitude,
            newPoint.latitude, newPoint.longitude,
          );

          if (dist > 2.0) {
            _totalDistanceKm += (dist / 1000);
            _caloriesBurned += (dist * 0.06);
          }
        }

        _routePoints.add(newPoint);
        _mapController.move(newPoint, 17.0);
      });
    });
  }

  void _startStepTracking() {
    _stepStream = Pedometer.stepCountStream.listen((StepCount event) {
      if (_initialSteps == -1) _initialSteps = event.steps;
      setState(() {
        _currentSteps = event.steps - _initialSteps;
        if (_totalDistanceKm == 0) {
          _caloriesBurned = _currentSteps * 0.04;
        }
      });
    }, onError: (e) => debugPrint("Step Error: $e"));
  }

  void _updatePace() {
    if (_totalDistanceKm > 0) {
      double minutes = _duration.inMinutes.toDouble();
      double paceVal = minutes / _totalDistanceKm;
      int paceMin = paceVal.floor();
      int paceSec = ((paceVal - paceMin) * 60).round();
      _currentPace = "$paceMin'${paceSec.toString().padLeft(2, '0')}\"";
    }
  }

  void _togglePause() => setState(() => _isPaused = !_isPaused);

  // 📸 SHARE RUN IMAGE
  Future<void> _shareRunImage() async {
    try {
      final summaryCard = _buildShareSummaryCard();

      final image = await _screenshotController.captureFromWidget(
        summaryCard,
        delay: const Duration(milliseconds: 50),
        context: context,
      );

      final directory = await getApplicationDocumentsDirectory();
      final imagePath = await File('${directory.path}/stride_run_share.png').create();
      await imagePath.writeAsBytes(image);

      await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: "Just crushed a ${_totalDistanceKm.toStringAsFixed(2)}km run on Stride! 🏃🔥"
      );
    } catch (e) {
      debugPrint("Share Error: $e");
    }
  }

  // 🎨 CUSTOM SUMMARY CARD WIDGET
  Widget _buildShareSummaryCard() {
    final theme = ThemeManager();
    return Container(
      width: 400,
      height: 600,
      color: theme.bgColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. ROUTE LAYER
          if (_routePoints.isNotEmpty)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(50.0),
                child: CustomPaint(
                  painter: RoutePainter(routePoints: _routePoints, color: Colors.orangeAccent),
                ),
              ),
            ),

          // 2. STATS LAYER
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              _buildShareStat(theme, "DISTANCE", "${_totalDistanceKm.toStringAsFixed(2)} km"),
              const SizedBox(height: 30),
              _buildShareStat(theme, "PACE", _currentPace),
              const SizedBox(height: 30),
              _buildShareStat(theme, "TIME", _formatDuration(_duration)),

              const Spacer(),

              const Text(
                "STRIDE",
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareStat(ThemeManager theme, String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(color: theme.subText, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(color: theme.textColor, fontSize: 50, fontWeight: FontWeight.w900, height: 1.0),
        ),
      ],
    );
  }

  void _finishRun() {
    _timer?.cancel();
    _positionStream?.cancel();
    _stepStream?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeManager().cardColor,
        title: Text("Session Complete", style: TextStyle(color: ThemeManager().textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Distance: ${_totalDistanceKm.toStringAsFixed(2)} km", style: TextStyle(color: ThemeManager().subText)),
            Text("Calories: ${_caloriesBurned.toStringAsFixed(0)} kcal", style: TextStyle(color: ThemeManager().subText)),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              label: const Text("Share Stats"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _shareRunImage();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: const Text("Close", style: TextStyle(color: Colors.grey)),
          )
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    _stepStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager();

    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: theme.bgColor,
        body: Stack(
          children: [
            // 🗺️ MAP
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(0, 0),
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.stride',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 6.0,
                      color: Colors.orangeAccent,
                    ),
                  ],
                ),
                if (_routePoints.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _routePoints.last,
                        width: 25, height: 25,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 8)],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // ⚡ TOP STATS
            Positioned(
              top: 50, left: 20, right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGlassMetric("TIME", _formatDuration(_duration)),
                  _buildGlassMetric("PACE", _currentPace),
                ],
              ),
            ),

            // 👟 BOTTOM CARD
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: const Offset(0, -5))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _totalDistanceKm.toStringAsFixed(2),
                      style: TextStyle(color: theme.textColor, fontSize: 64, fontWeight: FontWeight.w900, height: 1),
                    ),
                    Text("KILOMETERS", style: TextStyle(color: theme.subText, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),

                    const SizedBox(height: 25),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSimpleStat(theme, Icons.local_fire_department_rounded, "${_caloriesBurned.toInt()}", "KCAL"),
                        Container(height: 30, width: 1, color: Colors.grey.withOpacity(0.3)),
                        _buildSimpleStat(theme, Icons.directions_walk_rounded, "$_currentSteps", "STEPS"),
                      ],
                    ),

                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          heroTag: "pause",
                          backgroundColor: _isPaused ? Colors.green : Colors.orangeAccent,
                          elevation: 4,
                          onPressed: _togglePause,
                          child: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 32, color: Colors.white),
                        ),
                        const SizedBox(width: 25),
                        FloatingActionButton(
                          heroTag: "stop",
                          backgroundColor: theme.textColor,
                          elevation: 4,
                          onPressed: _finishRun,
                          child: const Icon(Icons.stop_rounded, size: 32, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 🔙 BACK BUTTON
            Positioned(
              top: 40, left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(ThemeManager theme, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.orangeAccent, size: 26),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: theme.textColor, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: theme.subText, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// 🖌️ CUSTOM PAINTER
class RoutePainter extends CustomPainter {
  final List<LatLng> routePoints;
  final Color color;

  RoutePainter({required this.routePoints, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (routePoints.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    double minLat = routePoints.first.latitude;
    double maxLat = routePoints.first.latitude;
    double minLon = routePoints.first.longitude;
    double maxLon = routePoints.first.longitude;

    for (var point in routePoints) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLon = math.min(minLon, point.longitude);
      maxLon = math.max(maxLon, point.longitude);
    }

    final latSpan = maxLat - minLat;
    final lonSpan = maxLon - minLon;

    if (latSpan == 0 || lonSpan == 0) return;

    // ✅ FIXED: Now using Flutter's native Path class because we hid the other one
    final path = Path();

    Offset normalize(LatLng point) {
      final x = (point.longitude - minLon) / lonSpan * size.width;
      final y = (maxLat - point.latitude) / latSpan * size.height;
      return Offset(x, y);
    }

    path.moveTo(normalize(routePoints.first).dx, normalize(routePoints.first).dy);

    for (int i = 1; i < routePoints.length; i++) {
      final offset = normalize(routePoints[i]);
      path.lineTo(offset.dx, offset.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}