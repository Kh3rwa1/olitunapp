import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/appwrite_auth_service.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/admin_page_header.dart';

class AdminAccessScreen extends ConsumerStatefulWidget {
  const AdminAccessScreen({super.key});

  @override
  ConsumerState<AdminAccessScreen> createState() => _AdminAccessScreenState();
}

class _AdminAccessScreenState extends ConsumerState<AdminAccessScreen> {
  final _addEmailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = true;
  bool _isBusy = false;
  bool _revokeSessions = true;
  String? _message;
  String? _selectedUserId;
  Map<String, dynamic>? _team;
  List<Map<String, dynamic>> _admins = const [];

  @override
  void initState() {
    super.initState();
    _passwordController.text = _generatePassword();
    _loadSummary();
  }

  @override
  void dispose() {
    _addEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      final data = await _call({'action': 'summary'});
      _applySummary(data);
    } catch (e) {
      _setMessage('Could not load admin access: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _call(Map<String, dynamic> payload) {
    return ref.read(appwriteAuthServiceProvider).executeAdminAccess(payload);
  }

  void _applySummary(Map<String, dynamic> data) {
    final admins = (data['admins'] as List? ?? const [])
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
    setState(() {
      _team = data['team'] is Map
          ? Map<String, dynamic>.from(data['team'] as Map)
          : null;
      _admins = admins;
      if (_selectedUserId == null ||
          !_admins.any((admin) => admin['userId'] == _selectedUserId)) {
        _selectedUserId = _admins.isEmpty
            ? null
            : _admins.first['userId']?.toString();
      }
    });
  }

  void _setMessage(String message) {
    if (!mounted) return;
    setState(() => _message = message);
  }

  Future<void> _runAdminAction(
    Future<Map<String, dynamic>> Function() action,
    String successMessage,
  ) async {
    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      final data = await action();
      _applySummary(data);
      _setMessage(successMessage);
    } catch (e) {
      _setMessage(e.toString());
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _addAdmin() async {
    final email = _addEmailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      _setMessage('Enter an existing Appwrite user email.');
      return;
    }
    await _runAdminAction(
      () => _call({'action': 'add_admin', 'email': email}),
      'Admin access granted.',
    );
    _addEmailController.clear();
  }

  Future<void> _removeAdmin(Map<String, dynamic> admin) async {
    final userId = admin['userId']?.toString();
    if (userId == null || userId.isEmpty) return;
    await _runAdminAction(
      () => _call({'action': 'remove_admin', 'targetUserId': userId}),
      'Admin access removed.',
    );
  }

  Future<void> _resetPassword() async {
    final userId = _selectedUserId;
    if (userId == null || userId.isEmpty) {
      _setMessage('Choose an admin account first.');
      return;
    }
    final password = _passwordController.text.trim();
    if (password.length < 16) {
      _setMessage('Use a password with at least 16 characters.');
      return;
    }
    await _runAdminAction(
      () => _call({
        'action': 'reset_password',
        'targetUserId': userId,
        'password': password,
        'revokeSessions': _revokeSessions,
      }),
      _revokeSessions
          ? 'Password reset and active sessions revoked.'
          : 'Password reset.',
    );
  }

  String _generatePassword() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%^*-_=+?';
    final random = Random.secure();
    while (true) {
      final password = List.generate(
        24,
        (_) => chars[random.nextInt(chars.length)],
      ).join();
      if (RegExp('[a-z]').hasMatch(password) &&
          RegExp('[A-Z]').hasMatch(password) &&
          RegExp('[0-9]').hasMatch(password)) {
        return password;
      }
    }
  }

  void _regeneratePassword() {
    setState(() => _passwordController.text = _generatePassword());
  }

  Future<void> _copyPassword() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: password));
    _setMessage('Generated password copied.');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AdminTokens.space7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminPageHeader(
                      title: 'Admin Access',
                      subtitle:
                          'Manage Appwrite admin team members and rotate admin passwords.',
                      eyebrow: 'SYSTEM · ACCESS',
                    ),
                    const SizedBox(height: 24),
                    if (_message != null) ...[
                      _MessageBanner(message: _message!, isDark: isDark),
                      const SizedBox(height: 18),
                    ],
                    _AccessCard(
                      isDark: isDark,
                      icon: Icons.verified_user_rounded,
                      title: 'Trusted Admin Team',
                      subtitle:
                          'Only members of this immutable Appwrite team ID can open Olitun Studio.',
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _InfoPill(
                            label: 'Team ID',
                            value: AppwriteConfig.adminTeamId,
                            isDark: isDark,
                          ),
                          _InfoPill(
                            label: 'Team name',
                            value: _team?['name']?.toString() ?? 'admins',
                            isDark: isDark,
                          ),
                          _InfoPill(
                            label: 'Members',
                            value: '${_admins.length}',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _AccessCard(
                      isDark: isDark,
                      icon: Icons.group_add_rounded,
                      title: 'Team Members',
                      subtitle:
                          'Add existing Appwrite users to the admin team or remove access.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _addEmailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Existing user email',
                                    hintText: 'admin@example.com',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              FilledButton.icon(
                                onPressed: _isBusy ? null : _addAdmin,
                                icon: const Icon(Icons.person_add_rounded),
                                label: const Text('Add'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          ..._admins.map((admin) {
                            final email = admin['userEmail']?.toString() ?? '';
                            final name = admin['userName']?.toString() ?? '';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: AdminTokens.accentSoft(isDark),
                                child: const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: Text(
                                email.isEmpty
                                    ? admin['userId'].toString()
                                    : email,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                name.isEmpty ? 'Admin team member' : name,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                tooltip: 'Remove admin access',
                                onPressed: _isBusy
                                    ? null
                                    : () => _removeAdmin(admin),
                                icon: const Icon(Icons.person_remove_rounded),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _AccessCard(
                      isDark: isDark,
                      icon: Icons.password_rounded,
                      title: 'Password Rotation',
                      subtitle:
                          'Generate a strong password, reset an admin account, and revoke old sessions.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _selectedUserId,
                            items: _admins
                                .map(
                                  (admin) => DropdownMenuItem<String>(
                                    value: admin['userId']?.toString(),
                                    child: Text(
                                      admin['userEmail']
                                                  ?.toString()
                                                  .isNotEmpty ==
                                              true
                                          ? admin['userEmail'].toString()
                                          : admin['userId'].toString(),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _isBusy
                                ? null
                                : (value) =>
                                      setState(() => _selectedUserId = value),
                            decoration: const InputDecoration(
                              labelText: 'Admin account',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'New password',
                              suffixIcon: IconButton(
                                tooltip: 'Copy password',
                                onPressed: _copyPassword,
                                icon: const Icon(Icons.copy_rounded),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _isBusy ? null : _regeneratePassword,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Generate'),
                              ),
                              FilterChip(
                                label: const Text('Revoke old sessions'),
                                selected: _revokeSessions,
                                onSelected: _isBusy
                                    ? null
                                    : (value) => setState(
                                        () => _revokeSessions = value,
                                      ),
                              ),
                              FilledButton.icon(
                                onPressed: _isBusy ? null : _resetPassword,
                                icon: const Icon(Icons.lock_reset_rounded),
                                label: const Text('Reset Password'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_isBusy) ...[
                      const SizedBox(height: 18),
                      const LinearProgressIndicator(minHeight: 3),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        border: Border.all(color: AdminTokens.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AdminTokens.cardTitle(isDark)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AdminTokens.body(
                        isDark,
                      ).copyWith(color: AdminTokens.textSecondary(isDark)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AdminTokens.sunken(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
        border: Border.all(color: AdminTokens.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AdminTokens.label(isDark)),
          const SizedBox(height: 2),
          SelectableText(value, style: AdminTokens.bodyStrong(isDark)),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message, required this.isDark});

  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminTokens.accentSoft(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
        border: Border.all(color: AdminTokens.accentBorder(isDark)),
      ),
      child: Text(message, style: AdminTokens.bodyStrong(isDark)),
    );
  }
}
