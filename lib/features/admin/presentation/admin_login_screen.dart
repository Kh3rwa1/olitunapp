import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_auth_provider.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _keyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isError = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _isError = false;
    });

    // Simulate network delay for "security check" feel
    await Future.delayed(const Duration(milliseconds: 1200));

    final success = ref
        .read(adminAuthProvider.notifier)
        .login(_keyController.text);

    if (success) {
      if (mounted) context.go('/admin');
    } else {
      setState(() {
        _isLoading = false;
        _isError = true;
      });
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Animated Abstract Background
          _buildBackground(isDark),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Icon
                  _buildAnimatedIcon(isDark),
                  const SizedBox(height: 32),

                  // Glassmorphism Card
                  _buildLoginCard(isDark),

                  const SizedBox(height: 24),

                  // Footer info
                  Text(
                    'SECURITY LEVEL: MAXIMUM',
                    style: TextStyle(
                      letterSpacing: 4,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white38 : Colors.black26,
                    ),
                  ).animate().fadeIn(delay: 1.seconds),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0A0E14),
                  const Color(0xFF1E1E2C),
                  const Color(0xFF0A0E14),
                ]
              : [
                  const Color(0xFFF0F4FF),
                  Colors.white,
                  const Color(0xFFE6EEFF),
                ],
        ),
      ),
      child: Stack(
        children: [
          // Moving blurred blobs
          _buildBlob(
            color: AppColors.primary.withOpacity(0.15),
            top: -50,
            left: -50,
            duration: 15.seconds,
          ),
          _buildBlob(
            color: AppColors.duoBlue.withOpacity(0.1),
            bottom: -100,
            right: -50,
            duration: 20.seconds,
          ),
        ],
      ),
    );
  }

  Widget _buildBlob({
    required Color color,
    double? top,
    double? left,
    double? bottom,
    double? right,
    required Duration duration,
  }) {
    return Positioned(
      top: top,
      left: left,
      bottom: bottom,
      right: right,
      child:
          Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: const Offset(0, 0),
                end: const Offset(50, 50),
                duration: duration,
                curve: Curves.easeInOut,
              )
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: duration,
                curve: Curves.easeInOut,
              ),
    );
  }

  Widget _buildAnimatedIcon(bool isDark) {
    return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.admin_panel_settings_rounded,
            size: 64,
            color: AppColors.primary,
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 3.seconds, color: Colors.white24)
        .scale(
          duration: 2.seconds,
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.05, 1.05),
        );
  }

  Widget _buildLoginCard(bool isDark) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Text(
              'Restricted Access',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your secret administrative key',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // Password Field
            TextFormField(
              controller: _keyController,
              obscureText: true,
              style: const TextStyle(letterSpacing: 8, fontSize: 18),
              textAlign: TextAlign.center,
              enabled: !_isLoading,
              onFieldSubmitted: (_) => _handleLogin(),
              decoration: InputDecoration(
                hintText: '••••••••',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white10 : Colors.black12,
                  letterSpacing: 8,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.black26
                    : Colors.black.withOpacity(0.02),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                errorStyle: const TextStyle(
                  height: 0,
                ), // Hide text error to handle it better
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ).animate(target: _isError ? 1 : 0).shake(duration: 400.ms, hz: 4),

            if (_isError) ...[
              const SizedBox(height: 12),
              Text(
                'INVALID ACCESS KEY',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ).animate().fadeIn(),
            ],

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_open_rounded),
                          SizedBox(width: 8),
                          Text(
                            'UNLOCK DASHBOARD',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9));
  }
}
