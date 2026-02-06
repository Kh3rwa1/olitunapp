import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WordDetailScreen extends ConsumerStatefulWidget {
  final String wordId;
  final String lessonId;

  const WordDetailScreen({
    super.key,
    required this.wordId,
    required this.lessonId,
  });

  @override
  ConsumerState<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends ConsumerState<WordDetailScreen> {
  int _currentIndex = 0;

  // Words and phrases data
  final Map<String, List<Map<String, dynamic>>> lessonWords = {
    'words_1': [
      {
        'olchiki': 'ᱡᱚᱦᱟᱨ',
        'latin': 'Johar',
        'meaning': 'Hello / Greetings',
        'usage': 'Used when meeting someone',
        'color': const Color(0xFFFFF8E1),
        'accentColor': const Color(0xFFFF9800),
        'emoji': '👋',
      },
      {
        'olchiki': 'ᱥᱮᱨᱢᱟ',
        'latin': 'Serma',
        'meaning': 'Good morning',
        'usage': 'Morning greeting',
        'color': const Color(0xFFFFF3E0),
        'accentColor': const Color(0xFFFF5722),
        'emoji': '🌅',
      },
      {
        'olchiki': 'ᱵᱳᱭᱤᱱ',
        'latin': 'Boyin',
        'meaning': 'Goodbye',
        'usage': 'When leaving or parting',
        'color': const Color(0xFFE3F2FD),
        'accentColor': const Color(0xFF2196F3),
        'emoji': '👋',
      },
      {
        'olchiki': 'ᱫᱷᱟᱱᱭᱟᱵᱟᱫ',
        'latin': 'Dhanyabad',
        'meaning': 'Thank you',
        'usage': 'To express gratitude',
        'color': const Color(0xFFE8F5E9),
        'accentColor': const Color(0xFF4CAF50),
        'emoji': '🙏',
      },
    ],
    'words_2': [
      {
        'olchiki': 'ᱟᱯᱟ',
        'latin': 'Apa',
        'meaning': 'Father',
        'usage': 'Addressing your father',
        'color': const Color(0xFFE3F2FD),
        'accentColor': const Color(0xFF2196F3),
        'emoji': '👨',
      },
      {
        'olchiki': 'ᱟᱭᱳ',
        'latin': 'Ayo',
        'meaning': 'Mother',
        'usage': 'Addressing your mother',
        'color': const Color(0xFFFCE4EC),
        'accentColor': const Color(0xFFE91E63),
        'emoji': '👩',
      },
      {
        'olchiki': 'ᱵᱳᱭᱦᱟ',
        'latin': 'Boyha',
        'meaning': 'Brother',
        'usage': 'Addressing your brother',
        'color': const Color(0xFFE8F5E9),
        'accentColor': const Color(0xFF4CAF50),
        'emoji': '👦',
      },
      {
        'olchiki': 'ᱢᱤᱥᱨᱟ',
        'latin': 'Misra',
        'meaning': 'Sister',
        'usage': 'Addressing your sister',
        'color': const Color(0xFFF3E5F5),
        'accentColor': AppColors.duoBlue,
        'emoji': '👧',
      },
    ],
    'phrases_1': [
      {
        'olchiki': 'ᱟᱢ ᱪᱮᱫᱟᱜ ᱢᱮᱱᱟᱜ ᱟ?',
        'latin': 'Am chedag menag a?',
        'meaning': 'How are you?',
        'usage': 'Asking about wellbeing',
        'color': const Color(0xFFE8F5E9),
        'accentColor': const Color(0xFF4CAF50),
        'emoji': '🤔',
      },
      {
        'olchiki': 'ᱤᱧ ᱵᱷᱟᱞᱮ ᱢᱮᱱᱟᱜ ᱟ',
        'latin': 'Ing bhale menag a',
        'meaning': 'I am fine',
        'usage': 'Responding to "How are you?"',
        'color': const Color(0xFFFFF8E1),
        'accentColor': const Color(0xFFFF9800),
        'emoji': '😊',
      },
      {
        'olchiki': 'ᱟᱢ ᱧᱩᱛᱩᱢ ᱪᱮᱫᱟᱜ?',
        'latin': 'Am nyutum chedag?',
        'meaning': 'What is your name?',
        'usage': 'Asking someone\'s name',
        'color': const Color(0xFFE3F2FD),
        'accentColor': const Color(0xFF2196F3),
        'emoji': '❓',
      },
      {
        'olchiki': 'ᱤᱧᱟᱜ ᱧᱩᱛᱩᱢ...',
        'latin': 'Ingag nyutum...',
        'meaning': 'My name is...',
        'usage': 'Introducing yourself',
        'color': const Color(0xFFFCE4EC),
        'accentColor': const Color(0xFFE91E63),
        'emoji': '🙋',
      },
    ],
  };

  List<Map<String, dynamic>> get words =>
      lessonWords[widget.lessonId] ?? lessonWords['words_1']!;

  @override
  void initState() {
    super.initState();
    final index = words.indexWhere((w) => w['olchiki'] == widget.wordId);
    _currentIndex = index >= 0 ? index : 0;
  }

  void _goToWord(int index) {
    if (index >= 0 && index < words.length) {
      HapticFeedback.lightImpact();
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = words[_currentIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : word['color'],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back_rounded, color: word['accentColor']),
          ),
          onPressed: () => context.go('/lesson/${widget.lessonId}'),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.volume_up_rounded, color: word['accentColor']),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Hero illustration
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: word['accentColor'].withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            word['emoji'],
                            style: const TextStyle(fontSize: 100),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            word['meaning'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: word['accentColor'],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Ol Chiki word
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            word['accentColor'].withOpacity(0.1),
                            word['accentColor'].withOpacity(0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: word['accentColor'].withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            word['olchiki'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: word['accentColor'],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: word['accentColor'].withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              word['latin'],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: word['accentColor'],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Usage hint
                    Container(
                      width: double.infinity,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                color: word['accentColor'],
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'When to use',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: word['accentColor'],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            word['usage'],
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
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
                children: List.generate(words.length, (index) {
                  final isActive = index == _currentIndex;
                  return GestureDetector(
                    onTap: () => _goToWord(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: isActive ? 44 : 36,
                      height: isActive ? 44 : 36,
                      decoration: BoxDecoration(
                        color: isActive
                            ? word['accentColor']
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(isActive ? 14 : 12),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: word['accentColor'].withOpacity(0.4),
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
