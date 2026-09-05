import 'package:flutter/material.dart';

/// No storage, providers, network or plugins are needed to render this shell.
class StartupStatusApp extends StatelessWidget {
  const StartupStatusApp({super.key, this.errorMessage, this.onRetry});

  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final failed = errorMessage != null;
    final theme = ThemeData.dark();
    final colors = theme.colorScheme;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      // No Navigator: preserve incoming web paths, queries and OAuth links.
      builder: (context, _) => Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (failed)
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colors.error,
                      size: 64,
                    )
                  else
                    const CircularProgressIndicator(
                      semanticsLabel: 'Starting Olitun',
                    ),
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      failed
                          ? 'Unable to Start Application'
                          : 'Starting Olitun',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (failed) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurface, fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      key: const Key('startup-retry'),
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry Startup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
