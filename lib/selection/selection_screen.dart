import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stride/ascension/ascension_screen.dart';

class AppColors {
  static const primary = Color(0xFF6C3CE8);
  static const secondary = Color(0xFF00E5FF);
  static const student = Color(0xFF10B981);
  static const background = Color(0xFFF8F9FD);
}

class SelectionScreen extends StatefulWidget {
  const SelectionScreen({Key? key}) : super(key: key);

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  String selectedMode = 'Student';

  final List<Map<String, dynamic>> modes = [
    {
      'id': 'Student',
      'asset': 'assets/illustrations/modes/student.svg',
      'iconAsset': 'assets/icons/modes/student.svg',
      'color': AppColors.student,
      'title': 'Your academic battleground.',
      'description':
      'Tackle study sessions, assignments, and daily goals while earning progress through focus and consistency.',
    },
    {
      'id': 'Standard',
      'asset': 'assets/illustrations/modes/standard.svg',
      'iconAsset': 'assets/icons/modes/standard.svg',
      'color': AppColors.secondary,
      'title': 'Your everyday productivity arena.',
      'description':
      'Tackle tasks, maintain habits, and earn steady progress through consistency without burning yourself out.',
    },
    {
      'id': 'Custom',
      'asset': 'assets/illustrations/modes/custom.svg',
      'iconAsset': 'assets/icons/modes/custom.svg',
      'color': AppColors.primary,
      'title': 'Your rules. Your game.',
      'description':
      'Design custom tasks, routines, and challenges to progress exactly the way you want.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final activeMode = modes.firstWhere((m) => m['id'] == selectedMode);
    final Color accent = activeMode['color'];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          /// ───────── TOP SECTION ─────────
          Positioned.fill(
            child: Container(
              color: accent.withOpacity(0.06),
              padding: const EdgeInsets.fromLTRB(36, 36, 36, 290),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// ILLUSTRATION
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.96,
                              end: 1.0,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: SvgPicture.asset(
                        activeMode['asset'],
                        key: ValueKey(selectedMode),
                      ),
                    ),
                  ),

                  /// TEXT (MOVED UPWARD)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        Text(
                          activeMode['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          activeMode['description'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ───────── BOTTOM SHEET ─────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(48),
              ),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    /// DRAG INDICATOR
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    const Text(
                      'Define Your Path',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 26),

                    /// MODE SELECTOR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: modes.map((mode) {
                        final bool isSelected =
                            selectedMode == mode['id'];

                        return GestureDetector(
                          onTap: () =>
                              setState(() => selectedMode = mode['id']),
                          child: AnimatedContainer(
                            duration:
                            const Duration(milliseconds: 220),
                            width:
                            MediaQuery.of(context).size.width * 0.26,
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade100,
                              borderRadius:
                              BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? mode['color']
                                    : Colors.grey.shade300,
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              children: [
                                SvgPicture.asset(
                                  mode['iconAsset'],
                                  height: 26,
                                  colorFilter: ColorFilter.mode(
                                    isSelected
                                        ? mode['color']
                                        : Colors.grey.shade500,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  mode['id'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: isSelected
                                        ? mode['color']
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 26),

                    /// CONTINUE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const AscensionScreen(),
                            ),
                                (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
