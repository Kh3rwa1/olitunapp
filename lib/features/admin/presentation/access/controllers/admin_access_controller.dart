import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import '../../../domain/admin_failure.dart';

class AdminAccessState {
  final bool isLoading;
  final bool isBusy;
  final String? message;
  final String? selectedUserId;
  final Map<String, dynamic>? team;
  final List<Map<String, dynamic>> admins;
  final bool revokeSessions;

  const AdminAccessState({
    this.isLoading = true,
    this.isBusy = false,
    this.message,
    this.selectedUserId,
    this.team,
    this.admins = const [],
    this.revokeSessions = true,
  });

  AdminAccessState copyWith({
    bool? isLoading,
    bool? isBusy,
    String? Function()? message,
    String? Function()? selectedUserId,
    Map<String, dynamic>? Function()? team,
    List<Map<String, dynamic>>? admins,
    bool? revokeSessions,
  }) {
    return AdminAccessState(
      isLoading: isLoading ?? this.isLoading,
      isBusy: isBusy ?? this.isBusy,
      message: message != null ? message() : this.message,
      selectedUserId: selectedUserId != null
          ? selectedUserId()
          : this.selectedUserId,
      team: team != null ? team() : this.team,
      admins: admins ?? this.admins,
      revokeSessions: revokeSessions ?? this.revokeSessions,
    );
  }
}

class AdminAccessController extends StateNotifier<AdminAccessState> {
  AdminAccessController(this._authService) : super(const AdminAccessState()) {
    loadSummary();
  }

  final AppwriteAuthService _authService;

  Future<void> loadSummary() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, message: () => null);
    try {
      final data = await _authService.executeAdminAccess({'action': 'summary'});
      if (!mounted) return;
      _applySummary(data);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(message: () => 'Could not load admin access: $e');
    } finally {
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  void _applySummary(Map<String, dynamic> data) {
    final admins = (data['admins'] as List? ?? const [])
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);

    final team = data['team'] is Map
        ? Map<String, dynamic>.from(data['team'] as Map)
        : null;

    String? selectedUserId = state.selectedUserId;
    if (selectedUserId == null ||
        !admins.any((admin) => admin['userId'] == selectedUserId)) {
      selectedUserId = admins.isEmpty
          ? null
          : admins.first['userId']?.toString();
    }

    state = state.copyWith(
      team: () => team,
      admins: admins,
      selectedUserId: () => selectedUserId,
    );
  }

  void updateRevokeSessions(bool value) {
    state = state.copyWith(revokeSessions: value);
  }

  void updateSelectedUserId(String? value) {
    state = state.copyWith(selectedUserId: () => value);
  }

  void setMessage(String? value) {
    state = state.copyWith(message: () => value);
  }

  Future<void> _runAdminAction(
    Future<Map<String, dynamic>> Function() action,
    String successMessage,
  ) async {
    state = state.copyWith(isBusy: true, message: () => null);
    try {
      final data = await action();
      _applySummary(data);
      state = state.copyWith(message: () => successMessage);
    } catch (e) {
      final failure = AdminFailure.fromException(e);
      state = state.copyWith(message: () => failure.userMessage);
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<void> addAdmin(String email) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isEmpty) {
      state = state.copyWith(
        message: () => 'Enter an existing Appwrite user email.',
      );
      return;
    }
    await _runAdminAction(
      () => _authService.executeAdminAccess({
        'action': 'add_admin',
        'email': trimmedEmail,
      }),
      'Admin access granted.',
    );
  }

  Future<void> removeAdmin(String userId) async {
    if (userId.isEmpty) return;
    await _runAdminAction(
      () => _authService.executeAdminAccess({
        'action': 'remove_admin',
        'targetUserId': userId,
      }),
      'Admin access removed.',
    );
  }

  Future<void> resetPassword(String password) async {
    final userId = state.selectedUserId;
    if (userId == null || userId.isEmpty) {
      state = state.copyWith(message: () => 'Choose an admin account first.');
      return;
    }
    final trimmedPassword = password.trim();
    if (trimmedPassword.length < 16) {
      state = state.copyWith(
        message: () => 'Use a password with at least 16 characters.',
      );
      return;
    }
    await _runAdminAction(
      () => _authService.executeAdminAccess({
        'action': 'reset_password',
        'targetUserId': userId,
        'password': trimmedPassword,
        'revokeSessions': state.revokeSessions,
      }),
      state.revokeSessions
          ? 'Password reset and active sessions revoked.'
          : 'Password reset.',
    );
  }
}

final adminAccessControllerProvider =
    StateNotifierProvider<AdminAccessController, AdminAccessState>((ref) {
      final authService = ref.watch(appwriteAuthServiceProvider);
      return AdminAccessController(authService);
    });
