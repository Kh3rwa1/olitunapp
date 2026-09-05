import 'package:flutter/material.dart';

/// No storage, providers, network or plugins are needed to render this shell.
class StartupStatusApp extends StatelessWidget {
  const StartupStatusApp({super.key, this.errorMessage, this.onRetry});

  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final failed = errorMessage != null;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: const Color(0xFF1E1E2C),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (failed)
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFFB74D),
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
                      failed ? 'Unable to Start Application' : 'Starting Olitun',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
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
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      key: const Key('startup-retry'),
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry Startup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        foregroundColor: Colors.white,
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
