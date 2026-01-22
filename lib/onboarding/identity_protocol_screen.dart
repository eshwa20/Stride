import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class IdentityProtocolScreen extends StatefulWidget {
  const IdentityProtocolScreen({super.key});

  @override
  State<IdentityProtocolScreen> createState() => _IdentityProtocolScreenState();
}

class _IdentityProtocolScreenState extends State<IdentityProtocolScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();

  // --- DATA ---
  String _name = "";
  int _age = 18;
  String _gender = "Male";
  double _weight = 70.0;
  double _height = 175.0;
  String _currentPhysiqueLabel = "Average Mesomorph";
  double _physiqueSliderValue = 3.0;
  String _targetPhysique = "Lean Muscle";
  double _currentStudyHours = 2.0;
  double _goalStudyHours = 6.0;
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
    );
    setState(() => _currentIndex++);
  }

  void _finishInitialization() async {
    var box = Hive.box('settingsBox');
    await box.put('userName', _name);
    await box.put('userAge', _age);
    await box.put('userGender', _gender);
    await box.put('userWeight', _weight);
    await box.put('userHeight', _height);
    await box.put('currentPhysique', _currentPhysiqueLabel);
    await box.put('targetPhysique', _targetPhysique);
    await box.put('currentStudyHours', _currentStudyHours);
    await box.put('goalStudyHours', _goalStudyHours);
    await box.put('hasSeenOnboarding', true);

    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  // --- THEME ---
  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF2F4F7);
    const Color cardColor = Colors.white;
    const Color textColor = Color(0xFF1D1F24);
    const Color subText = Color(0xFF98A2B3);
    const Color accentColor = Color(0xFF6200EA);
    const Color systemBubbleColor = Color(0xFF2D3142);

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            _buildHeader(bgColor, systemBubbleColor, accentColor, Colors.white),

            // PAGES
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildIdentityPage(cardColor, textColor, accentColor, subText),
                  _buildBioMetricsPage(cardColor, textColor, accentColor, subText),
                  _buildPhysiquePage(cardColor, textColor, accentColor, subText),
                  _buildIntellectPage(cardColor, textColor, accentColor, subText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HEADER ---
  Widget _buildHeader(Color bg, Color bubbleColor, Color accent, Color text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / 4,
              backgroundColor: Colors.grey[300],
              color: accent,
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 25),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Astra Mascot (Free floating)
              SizedBox(
                width: 110, height: 110,
                child: Image.asset(
                  'assets/images/astra_head.png',
                  fit: BoxFit.contain,
                  errorBuilder: (c, o, s) => const Icon(Icons.account_circle, size: 80, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 10),
              // Dialogue Bubble
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                        topLeft: Radius.circular(4),
                      ),
                      boxShadow: [BoxShadow(color: bubbleColor.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]
                  ),
                  child: Text(
                    _getAstraDialogue(),
                    style: TextStyle(color: text, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- DIALOGUE ---
  String _getAstraDialogue() {
    if (_currentIndex == 0) return "Many seek to Arise, but few survive the naming. Who are you, Hunter?";
    if (_currentIndex == 1) return "Scanning hardware... Define the vessel's base parameters.";
    if (_currentIndex == 2) return "Evolution requires a starting point and a destination. Define both.";
    return "Analyzing processing power. How much time will you dedicate to knowledge?";
  }

  // --- PAGE 1: IDENTITY ---
  Widget _buildIdentityPage(Color card, Color text, Color accent, Color subText) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("IDENTIFIER", style: TextStyle(color: subText, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 2)),
          const SizedBox(height: 15),
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: TextStyle(color: text, fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "ENTER CALLSIGN",
                hintStyle: TextStyle(color: Colors.grey[300], fontSize: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) => setState(() => _name = val),
            ),
          ),
          const SizedBox(height: 30),
          _buildSliderCard(card, text, accent, subText, "CHRONOLOGICAL AGE", "${_age} YEARS", _age.toDouble(), 10, 100, (v) => setState(() => _age = v.toInt())),
          const Spacer(),
          _buildActionButton(card, text, accent, "CONFIRM ID", () { if (_name.isNotEmpty) _nextPage(); }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- PAGE 2: BIO-METRICS ---
  Widget _buildBioMetricsPage(Color card, Color text, Color accent, Color subText) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),

          Text("SELECT VESSEL TYPE", style: TextStyle(color: subText, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAvatarOption("Male", 'assets/images/astra_male.png', accent),
              const SizedBox(width: 30),
              _buildAvatarOption("Female", 'assets/images/astra_female.png', accent),
            ],
          ),

          const SizedBox(height: 30),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                _buildWheelPicker(
                  label: "WEIGHT",
                  value: _weight.toInt(),
                  min: 40, max: 150, suffix: " KG",
                  accent: accent, text: text,
                  onChanged: (val) => setState(() => _weight = val.toDouble()),
                ),

                const SizedBox(height: 30),

                _buildWheelPicker(
                  label: "HEIGHT",
                  value: _height.toInt(),
                  min: 140, max: 220, suffix: " CM",
                  accent: accent, text: text,
                  onChanged: (val) => setState(() => _height = val.toDouble()),
                ),
              ],
            ),
          ),

          const Spacer(),
          _buildActionButton(card, text, accent, "CONFIRM SPECS", _nextPage),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- PAGE 3: PHYSIQUE (Image Updated) ---
  Widget _buildPhysiquePage(Color card, Color text, Color accent, Color subText) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
            ),
            child: Column(
              children: [
                Text("CURRENT BUILD", style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 15),

                // --- IMAGE SIZE INCREASED HERE ---
                Image.asset(
                    'assets/images/body_types.png',
                    height: 140, // Increased from 60 to 140
                    fit: BoxFit.contain
                ),
                // ---------------------------------

                const SizedBox(height: 15),
                Text(
                  _currentPhysiqueLabel.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: accent,
                    inactiveTrackColor: Colors.grey[200],
                    thumbColor: Colors.white,
                    trackHeight: 4,
                    thumbShape: SystemSliderThumb(thumbRadius: 10, color: Colors.white, ringColor: accent),
                  ),
                  child: Slider(
                    value: _physiqueSliderValue,
                    min: 1, max: 6, divisions: 5,
                    onChanged: (val) {
                      setState(() {
                        _physiqueSliderValue = val;
                        _currentPhysiqueLabel = _getPhysiqueLabel(val);
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("ECTO", style: TextStyle(color: subText, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text("MESO", style: TextStyle(color: subText, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text("ENDO", style: TextStyle(color: subText, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          Text("SELECT TARGET FORM", style: TextStyle(color: subText, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 15),

          _buildCompactOption(card, text, accent, "Lean Muscle", "Agility & Speed"),
          const SizedBox(height: 10),
          _buildCompactOption(card, text, accent, "Bulky", "Raw Power & Mass"),
          const SizedBox(height: 10),
          _buildCompactOption(card, text, accent, "Balanced", "Hybrid Build"),

          const SizedBox(height: 30),
          _buildActionButton(card, text, accent, "CONFIRM EVOLUTION", _nextPage),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- PAGE 4: INTELLECT ---
  Widget _buildIntellectPage(Color card, Color text, Color accent, Color subText) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          _buildSliderCard(card, text, accent, subText, "CURRENT STUDY HOURS", "${_currentStudyHours.toStringAsFixed(1)} HRS", _currentStudyHours, 0, 12, (v) => setState(() => _currentStudyHours = v)),
          const SizedBox(height: 20),
          _buildSliderCard(card, text, accent, subText, "EXPECTED GRIND", "${_goalStudyHours.toStringAsFixed(1)} HRS", _goalStudyHours, 1, 16, (v) => setState(() => _goalStudyHours = v)),
          const Spacer(),
          _buildActionButton(card, text, accent, "INITIALIZE SYSTEM", _finishInitialization, isFinal: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildCompactOption(Color card, Color text, Color accent, String title, String subtitle) {
    bool isSelected = _targetPhysique == title;
    return GestureDetector(
      onTap: () => setState(() => _targetPhysique = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? accent : card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 8)]
              : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isSelected ? Colors.white : text, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: TextStyle(color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey[400], fontSize: 11)),
              ],
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.white, size: 20)
            else
              Icon(Icons.circle_outlined, color: Colors.grey[300], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOption(String label, String imagePath, Color accent) {
    bool isSelected = _gender == label;
    return GestureDetector(
      onTap: () => setState(() => _gender = label),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            width: isSelected ? 90 : 70,
            height: isSelected ? 90 : 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: isSelected ? accent : Colors.transparent, width: 3),
              boxShadow: isSelected
                  ? [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)]
                  : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(imagePath, fit: BoxFit.contain, errorBuilder: (c, o, s) => Icon(label == "Male" ? Icons.male : Icons.female, color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: isSelected ? accent : Colors.grey[400],
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.5,
              fontFamily: 'Roboto',
            ),
            child: Text(label.toUpperCase()),
          ),
        ],
      ),
    );
  }

  Widget _buildWheelPicker({required String label, required int value, required int min, required int max, required String suffix, required Color accent, required Color text, required Function(int) onChanged}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Text("$value$suffix", style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 35,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              thumbColor: accent,
              thumbShape: SystemSliderThumb(thumbRadius: 8, color: accent, ringColor: accent.withOpacity(0.2)),
              overlayColor: accent.withOpacity(0.1),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(20, (index) => Container(width: 1, height: index % 5 == 0 ? 12 : 6, color: Colors.grey[300]))),
                Slider(value: value.toDouble(), min: min.toDouble(), max: max.toDouble(), onChanged: (val) => onChanged(val.toInt())),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderCard(Color card, Color text, Color accent, Color subText, String label, String value, double val, double min, double max, Function(double) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: card, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: subText, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(value, style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 40,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6, activeTrackColor: accent, inactiveTrackColor: Colors.grey[200],
                thumbShape: SystemSliderThumb(thumbRadius: 12, color: Colors.white, ringColor: accent),
                overlayColor: accent.withOpacity(0.1),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                trackShape: const RoundedRectSliderTrackShape(),
              ),
              child: Stack(
                children: [
                  Positioned(bottom: 0, left: 10, right: 10, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(11, (index) => Container(width: 2, height: index % 5 == 0 ? 8 : 4, color: Colors.grey.withOpacity(0.3))))),
                  Center(child: Slider(value: val, min: min, max: max, divisions: (max - min).toInt(), onChanged: onChanged)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Color card, Color text, Color accent, String label, VoidCallback onTap, {bool isFinal = false}) {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isFinal ? accent : Colors.white, foregroundColor: isFinal ? Colors.white : accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: isFinal ? BorderSide.none : BorderSide(color: accent)),
          elevation: isFinal ? 5 : 0,
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ),
    );
  }

  String _getPhysiqueLabel(double value) {
    int index = value.round();
    switch (index) {
      case 1: return "Extreme Ectomorph";
      case 2: return "Lean / Skinny";
      case 3: return "Average Mesomorph";
      case 4: return "Muscular / Athletic";
      case 5: return "Bulky / Soft";
      case 6: return "Heavy Endomorph";
      default: return "Average";
    }
  }
}

// --- CUSTOM THUMB CLASS ---
class SystemSliderThumb extends SliderComponentShape {
  final double thumbRadius;
  final Color color;
  final Color ringColor;

  const SystemSliderThumb({required this.thumbRadius, required this.color, required this.ringColor});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.fromRadius(thumbRadius);

  @override
  void paint(PaintingContext context, Offset center, {required Animation<double> activationAnimation, required Animation<double> enableAnimation, required bool isDiscrete, required TextPainter labelPainter, required RenderBox parentBox, required SliderThemeData sliderTheme, required TextDirection textDirection, required double value, required double textScaleFactor, required Size sizeWithOverflow}) {
    final Canvas canvas = context.canvas;
    final Path shadowPath = Path()..addOval(Rect.fromCircle(center: center, radius: thumbRadius + 2));
    canvas.drawShadow(shadowPath, Colors.black.withOpacity(0.2), 3, true);
    final Paint fillPaint = Paint()..color = color..style = PaintingStyle.fill;
    canvas.drawCircle(center, thumbRadius, fillPaint);
    final Paint borderPaint = Paint()..color = ringColor..style = PaintingStyle.stroke..strokeWidth = 3.0;
    canvas.drawCircle(center, thumbRadius - 1.5, borderPaint);
    final Paint centerDot = Paint()..color = ringColor;
    canvas.drawCircle(center, 3, centerDot);
  }
}