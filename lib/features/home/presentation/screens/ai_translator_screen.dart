import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/api/ai_service.dart';
import '../../../../shared/widgets/animated_buttons.dart';
import '../../../rhymes/presentation/widgets/enchanted_visualizer.dart';

class AiTranslatorScreen extends ConsumerStatefulWidget {
  const AiTranslatorScreen({super.key});

  @override
  ConsumerState<AiTranslatorScreen> createState() => _AiTranslatorScreenState();
}

class _AiTranslatorScreenState extends ConsumerState<AiTranslatorScreen> {
  final TextEditingController _controller = TextEditingController();
  String _result = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _translate() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final aiService = ref.read(aiServiceProvider);
      final result = await aiService.translate(
        _controller.text.trim(),
        from: 'auto',
        to: 'sat',
      );

      if (mounted) {
        setState(() {
          _result = result?.translation ?? 'Translation failed.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _result = 'Error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0E1A)
          : const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.1,
            ),
            child: IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: Text(
          'AI Translator',
          style: GoogleFonts.fredoka(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Global Premium Background
          _buildPremiumBackground(isDark),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    "Speak With\nConfidence",
                    style: GoogleFonts.fredoka(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.1),

                  const SizedBox(height: 50),

                  // Input Field with Glassmorphism
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.05,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.1),
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: "Type anything in English...",
                        hintStyle: GoogleFonts.inter(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.3),
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 800.ms),

                  const SizedBox(height: 32),

                  if (_isLoading)
                    Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ).animate().scale(duration: 400.ms),
                    )
                  else if (_result.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.15),
                            AppColors.primaryDark.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "SANTALI (OL CHIKI)",
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _result,
                            style: TextStyle(
                              fontFamily: 'OlChiki',
                              fontSize: 56,
                              height: 1.1,
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().scale(
                      begin: const Offset(0.95, 0.95),
                      curve: Curves.easeOutBack,
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom Button - Duo Styles
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: DuoButton(
              text: _isLoading ? "MAGIC IN PROGRESS..." : "TRANSLATE MAGIC",
              color: AppColors.primary,
              onPressed: _translate,
              height: 64,
              borderRadius: 20,
              width: double.infinity,
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBackground(bool isDark) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [
                        Color(0xFF0A0E1A),
                        Color(0xFF121A2B),
                        Color(0xFF1E2A44),
                      ]
                    : const [
                        Color(0xFFF3F8FF),
                        Color(0xFFF8FAFF),
                        Color(0xFFE8F0FF),
                      ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: EnchantedVisualizer(
            isPlaying: true,
            color: AppColors.primary,
            showWaves: false,
            showParticles: true,
            height: 400,
          ),
        ),
      ],
    );
  }
}
