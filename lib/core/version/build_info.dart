class BuildInfo {
  final String sha;
  final String? builtAt;

  const BuildInfo({required this.sha, this.builtAt});

  static const current = BuildInfo(
    sha: String.fromEnvironment('BUILD_SHA', defaultValue: 'unknown'),
    builtAt: String.fromEnvironment('BUILT_AT'),
  );
}
