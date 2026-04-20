import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/storage_service.dart';
import 'auth_providers.dart';
import 'progress_provider.dart';

// ============== USER DATA ==============

final userNameProvider = StateProvider<String>((ref) {
  return prefs.getString('user_name') ?? 'Learner';
});

// Derived from progressProvider — single source of truth
final userStarsProvider = Provider<int>((ref) {
  return ref.watch(progressProvider).totalStars;
});

final lessonsCompletedProvider = Provider<int>((ref) {
  return ref.watch(progressProvider).lessonsCompletedCount;
});

final quizzesCompletedProvider = Provider<int>((ref) {
  return ref.watch(progressProvider).quizzesCompletedCount;
});

Future<void> updateUserName(WidgetRef ref, String name) async {
  prefs.setString('user_name', name);
  ref.read(userNameProvider.notifier).state = name;
  try {
    final authRepo = ref.read(authRepositoryProvider);
    final loggedIn = await authRepo.isLoggedIn();
    if (loggedIn) {
      await authRepo.updateDisplayName(name);
    }
  } catch (e) {
    debugPrint('Failed to sync user name to cloud: $e');
  }
}

/// Synchronize profile name from Appwrite to local storage
Future<void> syncProfileName(WidgetRef ref) async {
  try {
    final authRepo = ref.read(authRepositoryProvider);
    final loggedIn = await authRepo.isLoggedIn();
    if (!loggedIn) return;

    final user = await authRepo.getMe();
    final cloudName = user.name;

    if (cloudName.isNotEmpty) {
      final localName = prefs.getString('user_name');
      if (localName != cloudName) {
        prefs.setString('user_name', cloudName);
        ref.read(userNameProvider.notifier).state = cloudName;
      }
    } else {
      final localName = prefs.getString('user_name');
      if (localName != null && localName != 'Learner') {
        await authRepo.updateDisplayName(localName);
      }
    }
  } catch (e) {
    debugPrint('Profile sync failed: $e');
  }
}

// ============== MEMBER SINCE ==============

final memberSinceProvider = StateProvider<String>((ref) {
  final stored = prefs.getString('member_since');
  if (stored != null) return stored;
  final now = DateTime.now();
  final dateStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  prefs.setString('member_since', dateStr);
  return dateStr;
});

// ============== AVATAR ==============

final userAvatarEmojiProvider = StateProvider<String>((ref) {
  return prefs.getString('user_avatar_emoji') ?? '';
});

void updateAvatarEmoji(WidgetRef ref, String emoji) {
  prefs.setString('user_avatar_emoji', emoji);
  ref.read(userAvatarEmojiProvider.notifier).state = emoji;
}

final userAvatarColorIndexProvider = StateProvider<int>((ref) {
  return prefs.getInt('user_avatar_color') ?? 0;
});

void updateAvatarColorIndex(WidgetRef ref, int index) {
  prefs.setInt('user_avatar_color', index);
  ref.read(userAvatarColorIndexProvider.notifier).state = index;
}

const avatarPalettes = [
  [Color(0xFF1EE088), Color(0xFF00C767)],
  [Color(0xFF1CB0F6), Color(0xFF1899D6)],
  [Color(0xFFFF9600), Color(0xFFD37D00)],
  [Color(0xFFCE82FF), Color(0xFFAF67E9)],
  [Color(0xFFFF4B4B), Color(0xFFD33131)],
  [Color(0xFFFFC800), Color(0xFFE5A100)],
  [Color(0xFF00E5FF), Color(0xFF00B8D4)],
  [Color(0xFFFF4081), Color(0xFFF50057)],
];

final userAvatarColorsProvider = Provider<List<Color>>((ref) {
  final index = ref.watch(userAvatarColorIndexProvider);
  return avatarPalettes[index.clamp(0, avatarPalettes.length - 1)];
});

// ============== SETTINGS ==============

final shellTabIndexProvider = StateProvider<int>((ref) => 0);

final themeModeProvider = StateProvider<String>((ref) {
  return prefs.getString('theme_mode') ?? 'system';
});

final scriptModeProvider = StateProvider<String>((ref) {
  return prefs.getString('script_mode') ?? 'both';
});

final soundEnabledProvider = StateProvider<bool>((ref) {
  return prefs.getBool('sound_enabled') ?? true;
});

void updateThemeMode(WidgetRef ref, String mode) {
  prefs.setString('theme_mode', mode);
  ref.read(themeModeProvider.notifier).state = mode;
}

void updateScriptMode(WidgetRef ref, String mode) {
  prefs.setString('script_mode', mode);
  ref.read(scriptModeProvider.notifier).state = mode;
}

void toggleSound(WidgetRef ref) {
  final current = ref.read(soundEnabledProvider);
  prefs.setBool('sound_enabled', !current);
  ref.read(soundEnabledProvider.notifier).state = !current;
}

// ============== USER PROFILE (Local) ==============

final userProfileProvider = Provider<AsyncValue<UserProfileLocal?>>((ref) {
  final name = ref.watch(userNameProvider);
  final progress = ref.watch(progressProvider);
  return AsyncValue.data(
    UserProfileLocal(
      displayName: name,
      stats: UserStatsLocal(
        streak: progress.currentStreak,
        stars: progress.totalStars,
        totalLessonsCompleted: progress.lessonsCompletedCount,
        totalQuizzesCompleted: progress.quizzesCompletedCount,
      ),
    ),
  );
});

class UserProfileLocal {
  final String displayName;
  final UserStatsLocal stats;
  UserProfileLocal({required this.displayName, required this.stats});
}

class UserStatsLocal {
  final int streak;
  final int stars;
  final int totalLessonsCompleted;
  final int totalQuizzesCompleted;

  UserStatsLocal({
    required this.streak,
    required this.stars,
    required this.totalLessonsCompleted,
    required this.totalQuizzesCompleted,
  });
}
