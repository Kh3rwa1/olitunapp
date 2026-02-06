import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../onboarding_screen.dart';

class OnboardingSlide extends StatelessWidget {
  final OnboardingData data;
  final double offset;

  const OnboardingSlide({super.key, required this.data, required this.offset});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Parallax Decoration 1
        Positioned(
          top: 100 - (offset * 50),
          left: 50 + (offset * 20),
          child:
              Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: data.accentColor.withOpacity(0.1),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: 0, end: 20, duration: 3.seconds),
        ),

        // Parallax Decoration 2
        Positioned(
          bottom: 150 + (offset * 40),
          right: 30 - (offset * 30),
          child:
              Icon(
                    Icons.auto_awesome_rounded,
                    size: 60,
                    color: data.accentColor.withOpacity(0.2),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.5, 1.5),
                    duration: 4.seconds,
                  ),
        ),

        Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Illustration with Tilt/Parallax
                Transform.translate(
                  offset: Offset(offset * 30, 0),
                  child:
                      Container(
                        height: MediaQuery.of(context).size.height * 0.35,
                        constraints: const BoxConstraints(
                          maxHeight: 300,
                          minHeight: 150,
                        ),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: data.accentColor.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: data.imagePath != null
                              ? Image.asset(data.imagePath!, fit: BoxFit.cover)
                              : Container(
                                  color: Colors.white,
                                  child: Icon(
                                    data.icon,
                                    size: 100,
                                    color: data.accentColor,
                                  ),
                                ),
                        ),
                      ).animate().scale(
                        duration: 800.ms,
                        curve: Curves.easeOutBack,
                      ),
                ),

                const SizedBox(height: 40),

                // Title
                Transform.translate(
                  offset: Offset(offset * 50, 0),
                  child: Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.primaryDark,
                      height: 1.1,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                ),

                const SizedBox(height: 16),

                // Description
                Transform.translate(
                  offset: Offset(offset * 80, 0),
                  child: Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.white70 : Colors.black54,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                ),
                // Add spacer for the floating nav bar
                const SizedBox(height: 140),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
