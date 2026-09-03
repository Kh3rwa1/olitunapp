part of 'onboarding_screen.dart';

// STEP: TEACHING / MOTHER TONGUE LANGUAGE (MANDATORY)
class _TeachingLanguageStep extends StatelessWidget {
  const _TeachingLanguageStep({
    required this.isDark,
    required this.selectedLanguage,
    required this.onSelected,
  });

  final bool isDark;
  final String? selectedLanguage;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const teachingOptions = [
      ('en', 'English', 'English explanations & interface'),
      ('hi', 'हिंदी', 'हिंदी माध्यम और अनुवाद'),
      ('bn', 'বাংলা', 'বাংলা মাধ্যম ও অনুবাদ'),
      ('or', 'ଓଡ଼ିଆ', 'ଓଡ଼ିଆ ମାଧ୍ୟମ ଏବଂ ଅନୁବାଦ'),
      ('sat', 'ᱥᱟᱱᱛᱟᱲᱤ', 'ᱥᱟᱱᱛᱟᱲᱤ ᱛᱮ ᱪᱮᱫᱚᱜ'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'REQUIRED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Step 1 of 5',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Which language do you understand best?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your mother tongue. We will use this language to explain Ol Chiki letters, word meanings, and audio lessons.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isDark ? Colors.white60 : AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: 20),
          ...teachingOptions.map((item) {
            final code = item.$1;
            final name = item.$2;
            final desc = item.$3;
            final isSelected = selectedLanguage == code;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MinimumTapTarget(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(code);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                              ? AppColors.primary.withValues(alpha: 0.18)
                              : AppColors.primary.withValues(alpha: 0.12))
                        : (isDark
                              ? AppColors.darkSurfaceElevated
                              : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white10 : Colors.black12),
                      width: isSelected ? 2.2 : 1.2,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : (isDark ? Colors.white10 : Colors.black12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.translate_rounded,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white60
                                    : AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? Colors.white30 : Colors.black26),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
