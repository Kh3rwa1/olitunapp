sealed class BuildVersionStatus {
  const BuildVersionStatus();
}

class BuildVersionMatch extends BuildVersionStatus {
  const BuildVersionMatch();

  @override
  bool operator ==(Object other) => other is BuildVersionMatch;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'BuildVersionStatus.match()';
}

class BuildVersionStale extends BuildVersionStatus {
  final String serverSha;
  const BuildVersionStale(this.serverSha);

  @override
  bool operator ==(Object other) =>
      other is BuildVersionStale && other.serverSha == serverSha;

  @override
  int get hashCode => serverSha.hashCode;

  @override
  String toString() => 'BuildVersionStatus.stale($serverSha)';
}

class BuildVersionUnknown extends BuildVersionStatus {
  final String reason;
  const BuildVersionUnknown(this.reason);

  @override
  bool operator ==(Object other) =>
      other is BuildVersionUnknown && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'BuildVersionStatus.unknown($reason)';
}
