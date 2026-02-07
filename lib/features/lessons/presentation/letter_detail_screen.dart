import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/animated_buttons.dart';
import '../../../core/presentation/animations/scale_button.dart';

class LetterDetailScreen extends ConsumerStatefulWidget {
  final String letterId;
  final String lessonId;

  const LetterDetailScreen({
    super.key,
    required this.letterId,
    required this.lessonId,
  });

  @override
  ConsumerState<LetterDetailScreen> createState() => _LetterDetailScreenState();
}

class _LetterDetailScreenState extends ConsumerState<LetterDetailScreen> {
  int _currentIndex = 0;

  // Ol Chiki letters data with examples
  final Map<String, List<Map<String, dynamic>>> lessonLetters = {
    'alphabets_1': [
      {
        'char': 'ᱚ',
        'latin': 'a',
        'name': 'La',
        'example': 'ᱟᱡ',
        'exampleLatin': 'Aaj (Today)',
        'color': const Color(0xFFFFF0F5),
        'accentColor': const Color(0xFFE91E63),
        'emoji': '🌅',
      },
      {
        'char': 'ᱟ',
        'latin': 'aa',
        'name': 'Aah',
        'example': 'ᱟᱯᱟ',
        'exampleLatin': 'Apa (Father)',
        'color': const Color(0xFFF0F4FF),
        'accentColor': const Color(0xFF3F51B5),
        'emoji': '👨',
      },
      {
        'char': 'ᱤ',
        'latin': 'i',
        'name': 'Li',
        'example': 'ᱤᱧ',
        'exampleLatin': 'Ing (I/Me)',
        'color': const Color(0xFFF5FFF0),
        'accentColor': const Color(0xFF4CAF50),
        'emoji': '🙋',
      },
      {
        'char': 'ᱩ',
        'latin': 'u',
        'name': 'Lu',
        'example': 'ᱩᱞ',
        'exampleLatin': 'Ul (Mango)',
        'color': const Color(0xFFFFFBE5),
        'accentColor': const Color(0xFFFF9800),
        'emoji': '🥭',
      },
    ],
    'alphabets_2': [
      {
        'char': 'ᱚ',
        'latin': 'a',
        'name': 'A vowel',
        'example': 'ᱟᱢ',
        'exampleLatin': 'Am (You)',
        'color': const Color(0xFFFFF0F5),
        'accentColor': const Color(0xFFE91E63),
        'emoji': '👋',
      },
      {
        'char': 'ᱟ',
        'latin': 'aa',
        'name': 'AA vowel',
        'example': 'ᱟᱭᱳ',
        'exampleLatin': 'Ayo (Mother)',
        'color': const Color(0xFFFCE4EC),
        'accentColor': const Color(0xFFE91E63),
        'emoji': '👩',
      },
      {
        'char': 'ᱤ',
        'latin': 'i',
        'name': 'I vowel',
        'example': 'ᱤᱱ',
        'exampleLatin': 'In (House)',
        'color': const Color(0xFFE8F5E9),
        'accentColor': const Color(0xFF4CAF50),
        'emoji': '🏠',
      },
      {
        'char': 'ᱩ',
        'latin': 'u',
        'name': 'U vowel',
        'example': 'ᱩᱲᱩᱜ',
        'exampleLatin': 'Urub (Egg)',
        'color': const Color(0xFFFFF8E1),
        'accentColor': const Color(0xFFFF9800),
        'emoji': '🥚',
      },
      {
        'char': 'ᱮ',
        'latin': 'e',
        'name': 'E vowel',
        'example': 'ᱮᱞ',
        'exampleLatin': 'El (Come)',
        'color': const Color(0xFFE3F2FD),
        'accentColor': const Color(0xFF2196F3),
        'emoji': '🚶',
      },
      {
        'char': 'ᱳ',
        'latin': 'o',
        'name': 'O vowel',
        'example': 'ᱳᱞ',
        'exampleLatin': 'Ol (Write)',
        'color': const Color(0xFFEDE7F6),
        'accentColor': const Color(0xFF673AB7),
        'emoji': '✍️',
      },
    ],
    'alphabets_3': [
      {
        'char': 'ᱠ',
        'latin': 'k',
        'name': 'Ok',
        'example': 'ᱠᱩᱲᱤ',
        'exampleLatin': 'Kurhi (Girl)',
        'color': const Color(0xFFFCE4EC),
        'accentColor': const Color(0xFFE91E63),
        'emoji': '👧',
      },
      {
        'char': 'ᱜ',
        'latin': 'g',
        'name': 'Ol',
        'example': 'ᱜᱟᱰᱟ',
        'exampleLatin': 'Gada (River)',
        'color': const Color(0xFFE3F2FD),
        'accentColor': const Color(0xFF2196F3),
        'emoji': '🏞️',
      },
      {
        'char': 'ᱝ',
        'latin': 'ng',
        'name': 'Ong',
        'example': 'ᱥᱤᱝ',
        'exampleLatin': 'Sing (Sun)',
        'color': const Color(0xFFFFF8E1),
        'accentColor': const Color(0xFFFF9800),
        'emoji': '☀️',
      },
      {
        'char': 'ᱪ',
        'latin': 'c',
        'name': 'Uc',
        'example': 'ᱪᱟᱸᱫᱚ',
        'exampleLatin': 'Chando (Moon)',
        'color': const Color(0xFFEDE7F6),
        'accentColor': const Color(0xFF673AB7),
        'emoji': '🌙',
      },
      {
        'char': 'ᱡ',
        'latin': 'j',
        'name': 'Oj',
        'example': 'ᱡᱚᱡᱚ',
        'exampleLatin': 'Jojo (Baby)',
        'color': const Color(0xFFFFF0F5),
        'accentColor': const Color(0xFFE91E63),
        'emoji': '👶',
      },
    ],
    'alphabets_4': [
      {
        'char': 'ᱴ',
        'latin': 't',
        'name': 'Ot',
        'example': 'ᱴᱟᱹᱜᱤ',
        'exampleLatin': 'Taki (Axe)',
        'color': const Color(0xFFEFEBE9),
        'accentColor': const Color(0xFF795548),
        'emoji': '🪓',
      },
      {
        'char': 'ᱰ',
        'latin': 'd',
        'name': 'Od',
        'example': 'ᱰᱟᱹᱦᱤ',
        'exampleLatin': 'Dahi (Yogurt)',
        'color': const Color(0xFFFFFDE7),
        'accentColor': const Color(0xFFFFEB3B),
        'emoji': '🥛',
      },
      {
        'char': 'ᱱ',
        'latin': 'n',
        'name': 'On',
        'example': 'ᱱᱤᱫᱟ',
        'exampleLatin': 'Nida (Sleep)',
        'color': const Color(0xFFE8EAF6),
        'accentColor': const Color(0xFF3F51B5),
        'emoji': '😴',
      },
      {
        'char': 'ᱯ',
        'latin': 'p',
        'name': 'Op',
        'example': 'ᱯᱩᱥᱤ',
        'exampleLatin': 'Pusi (Cat)',
        'color': const Color(0xFFF3E5F5),
        'accentColor': AppColors.duoBlue,
        'emoji': '🐱',
      },
      {
        'char': 'ᱵ',
        'latin': 'b',
        'name': 'Ob',
        'example': 'ᱵᱟᱝ',
        'exampleLatin': 'Baha (Flower)',
        'color': const Color(0xFFFCE4EC),
        'accentColor': const Color(0xFFE91E63),
        'emoji': '🌸',
      },
    ],
  };

  List<Map<String, dynamic>> get letters =>
      lessonLetters[widget.lessonId] ?? lessonLetters['alphabets_1']!;

  @override
  void initState() {
    super.initState();
    // Find initial index based on letterId
    final index = letters.indexWhere((l) => l['char'] == widget.letterId);
    _currentIndex = index >= 0 ? index : 0;
  }

  void _goToLetter(int index) {
    if (index >= 0 && index < letters.length) {
      HapticFeedback.lightImpact();
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final letter = letters[_currentIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : letter['color'],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ScaleButton(
            onPressed: () => context.go('/lesson/${widget.lessonId}'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: letter['accentColor'],
              ),
            ),
          ),
        ),
        actions: [
          // Audio button
          // Audio button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ScaleButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                // TODO: Play audio
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: letter['accentColor'],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Hero illustration card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: letter['accentColor'].withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Big emoji illustration
                          Text(
                            letter['emoji'],
                            style: const TextStyle(fontSize: 100),
                          ),
                          const SizedBox(height: 24),

                          // Letter title
                          Text(
                            letter['exampleLatin'],
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: letter['accentColor'],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Large Ol Chiki character
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            letter['accentColor'].withOpacity(0.1),
                            letter['accentColor'].withOpacity(0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: letter['accentColor'].withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          letter['char'],
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w700,
                            color: letter['accentColor'],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Latin pronunciation
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: letter['accentColor'].withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            letter['latin'].toString().toUpperCase(),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: letter['accentColor'],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '• ${letter['name']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: letter['accentColor'].withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Example word
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Example Word',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            letter['example'],
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: letter['accentColor'],
                            ),
                          ),
                          Text(
                            letter['exampleLatin'],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Practice Button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: DuoButton(
                        text: 'PRACTICE WRITING',
                        icon: Icons.edit_rounded,
                        color: letter['accentColor'],
                        onPressed: () {
                          final encodedChar = Uri.encodeComponent(
                            letter['char'].toString(),
                          );
                          final encodedName = Uri.encodeComponent(
                            letter['name'].toString(),
                          );
                          context.push(
                            '/practice/$encodedChar/$encodedName',
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Bottom pagination
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(letters.length, (index) {
                  final isActive = index == _currentIndex;
                  return ScaleButton(
                    onPressed: () => _goToLetter(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: isActive ? 44 : 36,
                      height: isActive ? 44 : 36,
                      decoration: BoxDecoration(
                        color: isActive
                            ? letter['accentColor']
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(isActive ? 14 : 12),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: letter['accentColor'].withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: isActive ? 18 : 14,
                            fontWeight: FontWeight.w700,
                            color: isActive ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
