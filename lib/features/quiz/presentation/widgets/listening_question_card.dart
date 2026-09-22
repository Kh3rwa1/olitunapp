import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/accessibility/learning_semantics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/content_models.dart';

/// Phase 7 listening-quiz question card (spec §14, `listen_meaning` type).
///
/// Shows a large play button instead of the Ol Chiki prompt — the learner
/// hears the Santali audio and picks the meaning. Playback routes through
/// the single global `PlaybackController` (wired by the caller, mirroring
/// the `LessonBlockDetailScreen._playAudio` precedent) so there is never a
/// second audio service. The card never crashes when audio is missing: the
/// play button simply reports the failure via [onPlaybackError].
class ListeningQuestionCard extends StatelessWidget {
  final QuizQuestion question;
  final bool isPlaying;
  final bool isLoading;
  final String? playbackError;
  final VoidCallback onPlayTap;
  final VoidCallback onStopTap;

  const ListeningQuestionCard({
    super.key,
    required this.question,
    required this.isPlaying,
    required this.isLoading,
    required this.playbackError,
    required this.onPlayTap,
    required this.onStopTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAudio =
        question.audioUrl != null && question.audioUrl!.trim().isNotEmpty;

    return Semantics(
      key: const ValueKey('listening-question-semantics'),
      container: true,
      label:
          'Listening question. ${LearningSemantics.quizQuestion(prompt: '', latin: question.promptLatin ?? 'Listen and choose the correct meaning:')}',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                question.promptLatin ??
                    'Listen and choose the correct meaning:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _PlayButton(
                isPlaying: isPlaying,
                isLoading: isLoading,
                onTap: isPlaying ? onStopTap : onPlayTap,
              ),
              if (playbackError != null) ...[
                const SizedBox(height: 12),
                Text(
                  playbackError!,
                  key: const ValueKey('listening-playback-error'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (!hasAudio) ...[
                const SizedBox(height: 12),
                Text(
                  'Audio is not available for this question.',
                  key: const ValueKey('listening-no-audio-hint'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  const _PlayButton({
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isPlaying ? 'Stop audio' : 'Play audio',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.white.withValues(alpha: 0.18),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 88,
              height: 88,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Icon(
                        isPlaying
                            ? Icons.stop_rounded
                            : Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
