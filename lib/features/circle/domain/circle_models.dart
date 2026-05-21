class WeeklyCircle {
  final String circleId;
  final String weekId;
  final String learnerLevel;
  final String activityTier;
  final String scriptMode;
  final int memberCount;
  final int targetMembers;
  final int maxMembers;
  final String status; // open, full, closed, archived
  final DateTime createdAt;
  final DateTime startsAt;
  final DateTime endsAt;

  WeeklyCircle({
    required this.circleId,
    required this.weekId,
    required this.learnerLevel,
    required this.activityTier,
    required this.scriptMode,
    required this.memberCount,
    required this.targetMembers,
    required this.maxMembers,
    required this.status,
    required this.createdAt,
    required this.startsAt,
    required this.endsAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'circleId': circleId,
      'weekId': weekId,
      'learnerLevel': learnerLevel,
      'activityTier': activityTier,
      'scriptMode': scriptMode,
      'memberCount': memberCount,
      'targetMembers': targetMembers,
      'maxMembers': maxMembers,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'startsAt': startsAt.toIso8601String(),
      'endsAt': endsAt.toIso8601String(),
    };
  }

  factory WeeklyCircle.fromMap(Map<String, dynamic> map) {
    return WeeklyCircle(
      circleId: map['circleId'] ?? '',
      weekId: map['weekId'] ?? '',
      learnerLevel: map['learnerLevel'] ?? 'beginner',
      activityTier: map['activityTier'] ?? 'medium',
      scriptMode: map['scriptMode'] ?? 'latin',
      memberCount: map['memberCount'] ?? 0,
      targetMembers: map['targetMembers'] ?? 20,
      maxMembers: map['maxMembers'] ?? 20,
      status: map['status'] ?? 'open',
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      startsAt: DateTime.parse(
        map['startsAt'] ?? DateTime.now().toIso8601String(),
      ),
      endsAt: DateTime.parse(map['endsAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class CircleMember {
  final String circleId;
  final String userId;
  final String weekId;
  final String displayName;
  final String anonymousName;
  final String avatarEmoji;
  final String learnerLevel;
  final int circlePoints;
  final int starsThisWeek;
  final int lessonsCompleted;
  final int quizzesTaken;
  final int bakhedListened;
  final int missionDaysCompleted;
  final int mistakeReviewsCompleted;
  final int rank;
  final DateTime joinedAt;
  final DateTime lastActiveAt;

  CircleMember({
    required this.circleId,
    required this.userId,
    required this.weekId,
    required this.displayName,
    required this.anonymousName,
    required this.avatarEmoji,
    required this.learnerLevel,
    required this.circlePoints,
    required this.starsThisWeek,
    required this.lessonsCompleted,
    required this.quizzesTaken,
    required this.bakhedListened,
    required this.missionDaysCompleted,
    required this.mistakeReviewsCompleted,
    required this.rank,
    required this.joinedAt,
    required this.lastActiveAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'circleId': circleId,
      'userId': userId,
      'weekId': weekId,
      'displayName': displayName,
      'anonymousName': anonymousName,
      'avatarEmoji': avatarEmoji,
      'learnerLevel': learnerLevel,
      'circlePoints': circlePoints,
      'starsThisWeek': starsThisWeek,
      'lessonsCompleted': lessonsCompleted,
      'quizzesTaken': quizzesTaken,
      'bakhedListened': bakhedListened,
      'missionDaysCompleted': missionDaysCompleted,
      'mistakeReviewsCompleted': mistakeReviewsCompleted,
      'rank': rank,
      'joinedAt': joinedAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
    };
  }

  factory CircleMember.fromMap(Map<String, dynamic> map) {
    return CircleMember(
      circleId: map['circleId'] ?? '',
      userId: map['userId'] ?? '',
      weekId: map['weekId'] ?? '',
      displayName: map['displayName'] ?? '',
      anonymousName: map['anonymousName'] ?? '',
      avatarEmoji: map['avatarEmoji'] ?? '🌿',
      learnerLevel: map['learnerLevel'] ?? 'beginner',
      circlePoints: map['circlePoints'] ?? 0,
      starsThisWeek: map['starsThisWeek'] ?? 0,
      lessonsCompleted: map['lessonsCompleted'] ?? 0,
      quizzesTaken: map['quizzesTaken'] ?? 0,
      bakhedListened: map['bakhedListened'] ?? 0,
      missionDaysCompleted: map['missionDaysCompleted'] ?? 0,
      mistakeReviewsCompleted: map['mistakeReviewsCompleted'] ?? 0,
      rank: map['rank'] ?? 1,
      joinedAt: DateTime.parse(
        map['joinedAt'] ?? DateTime.now().toIso8601String(),
      ),
      lastActiveAt: DateTime.parse(
        map['lastActiveAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class CircleEvent {
  final String circleId;
  final String userId;
  final String weekId;
  final String eventType;
  final String sourceId;
  final int points;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  CircleEvent({
    required this.circleId,
    required this.userId,
    required this.weekId,
    required this.eventType,
    required this.sourceId,
    required this.points,
    required this.metadata,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'circleId': circleId,
      'userId': userId,
      'weekId': weekId,
      'eventType': eventType,
      'sourceId': sourceId,
      'points': points,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CircleEvent.fromMap(Map<String, dynamic> map) {
    return CircleEvent(
      circleId: map['circleId'] ?? '',
      userId: map['userId'] ?? '',
      weekId: map['weekId'] ?? '',
      eventType: map['eventType'] ?? '',
      sourceId: map['sourceId'] ?? '',
      points: map['points'] ?? 0,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
