import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/appwrite_config.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/common/admin_destructive_dialog.dart';
import 'controllers/admin_access_controller.dart';
import 'widgets/access_card.dart';
import 'widgets/info_pill.dart';
import 'widgets/message_banner.dart';

class AdminAccessScreen extends ConsumerStatefulWidget {
  const AdminAccessScreen({super.key});

  @override
  ConsumerState<AdminAccessScreen> createState() => _AdminAccessScreenState();
}

class _AdminAccessScreenState extends ConsumerState<AdminAccessScreen> {
  final _addEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _passwordController.text = _generatePassword();
  }

  @override
  void dispose() {
    _addEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _addAdmin() async {
    final email = _addEmailController.text.trim();
    if (email.isEmpty) return;
    await ref.read(adminAccessControllerProvider.notifier).addAdmin(email);
    _addEmailController.clear();
  }

  Future<void> _removeAdmin(Map<String, dynamic> admin) async {
    final userId = admin['userId']?.toString() ?? '';
    final userEmail = admin['userEmail']?.toString() ?? userId;
    final userName = admin['userName']?.toString() ?? 'Admin';
    if (userId.isEmpty) return;

    final confirmed = await AdminDestructiveDialog.show(
      context: context,
      title: 'Remove Administrator Access',
      actionName: 'Revoke Admin Access',
      targetName: '$userName ($userEmail)',
      blastRadiusDescription:
          'This user will be removed from the Appwrite "$AppwriteConfig.adminTeamId" team and will lose all access to Olitun Content Studio immediately.',
      isReversible: true,
      confirmButtonLabel: 'Remove Administrator',
      icon: Icons.person_remove_rounded,
      onConfirm: () async {
        await ref
            .read(adminAccessControllerProvider.notifier)
            .removeAdmin(userId);
      },
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed admin access for $userEmail'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _confirmResetPassword() async {
    final state = ref.read(adminAccessControllerProvider);
    final targetId = state.selectedUserId;
    if (targetId == null || targetId.isEmpty) return;

    final targetAdmin = state.admins.firstWhere(
      (a) => a['userId'] == targetId,
      orElse: () => {'userId': targetId, 'userEmail': targetId},
    );
    final email = targetAdmin['userEmail']?.toString() ?? targetId;
    final password = _passwordController.text.trim();

    if (password.length < 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 16 characters long.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirmed = await AdminDestructiveDialog.show(
      context: context,
      title: 'Reset Admin Password',
      actionName: 'Rotate Account Credentials',
      targetName: email,
      blastRadiusDescription: state.revokeSessions
          ? 'The account password will be rotated and all existing active login sessions will be immediately terminated.'
          : 'The account password will be updated to the newly generated credential.',
      confirmButtonLabel: 'Reset Password',
      icon: Icons.lock_reset_rounded,
      isDanger: false,
      onConfirm: () async {
        await ref
            .read(adminAccessControllerProvider.notifier)
            .resetPassword(password);
      },
    );

    if (confirmed == true && mounted) {
      // Clear password field after successful reset for safety
      setState(() {
        _passwordController.text = _generatePassword();
        _obscurePassword = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password updated for $email!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Generated password copied to clipboard. Paste securely.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminAccessControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width < 600
                      ? 16
                      : AdminTokens.space7,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminPageHeader(
                      title: 'Admin Access',
                      subtitle:
                          'Manage Appwrite admin team members and rotate admin passwords safely.',
                      eyebrow: 'SYSTEM · ACCESS',
                    ),
                    const SizedBox(height: 24),
                    if (state.message != null) ...[
                      MessageBanner(message: state.message!, isDark: isDark),
                      const SizedBox(height: 18),
                    ],
                    AccessCard(
                      isDark: isDark,
                      icon: Icons.verified_user_rounded,
                      title: 'Trusted Admin Team',
                      subtitle:
                          'Only members of this immutable Appwrite team ID can open Olitun Studio.',
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          InfoPill(
                            label: 'Team ID',
                            value: AppwriteConfig.adminTeamId,
                            isDark: isDark,
                          ),
                          InfoPill(
                            label: 'Team name',
                            value: state.team?['name']?.toString() ?? 'admins',
                            isDark: isDark,
                          ),
                          InfoPill(
                            label: 'Members',
                            value: '${state.admins.length}',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AccessCard(
                      isDark: isDark,
                      icon: Icons.group_add_rounded,
                      title: 'Team Members',
                      subtitle:
                          'Add existing Appwrite users to the admin team or remove access.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow = constraints.maxWidth < 460;
                              if (isNarrow) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextField(
                                      controller: _addEmailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: 'Existing user email',
                                        hintText: 'admin@example.com',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    FilledButton.icon(
                                      onPressed: state.isBusy
                                          ? null
                                          : _addAdmin,
                                      icon: const Icon(
                                        Icons.person_add_rounded,
                                      ),
                                      label: const Text('Add Member'),
                                    ),
                                  ],
                                );
                              }

                              return Row(
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
                                    onPressed: state.isBusy ? null : _addAdmin,
                                    icon: const Icon(Icons.person_add_rounded),
                                    label: const Text('Add'),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          ...state.admins.map((admin) {
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
                                onPressed: state.isBusy
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
                    AccessCard(
                      isDark: isDark,
                      icon: Icons.password_rounded,
                      title: 'Password Rotation',
                      subtitle:
                          'Generate a strong password, reset an admin account, and revoke old sessions.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: state.selectedUserId,
                            items: state.admins
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
                            onChanged: state.isBusy
                                ? null
                                : (value) => ref
                                      .read(
                                        adminAccessControllerProvider.notifier,
                                      )
                                      .updateSelectedUserId(value),
                            decoration: const InputDecoration(
                              labelText: 'Admin account',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'New password',
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Reveal password'
                                        : 'Hide password',
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Copy password',
                                    onPressed: _copyPassword,
                                    icon: const Icon(Icons.copy_rounded),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: state.isBusy
                                    ? null
                                    : _regeneratePassword,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Generate'),
                              ),
                              FilterChip(
                                label: const Text('Revoke old sessions'),
                                selected: state.revokeSessions,
                                onSelected: state.isBusy
                                    ? null
                                    : (value) => ref
                                          .read(
                                            adminAccessControllerProvider
                                                .notifier,
                                          )
                                          .updateRevokeSessions(value),
                              ),
                              FilledButton.icon(
                                onPressed: state.isBusy
                                    ? null
                                    : _confirmResetPassword,
                                icon: const Icon(Icons.lock_reset_rounded),
                                label: const Text('Reset Password'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (state.isBusy) ...[
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
