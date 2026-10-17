/// 一条知识点的复习卡片。
/// 二元评分：没失误过的答对进入 review；有失误时要连续答对两次才拉长间隔。答错回到 learning。
enum SrsState { learning, review }

/// 调度里不变的界限。
class SrsLimits {
  static const double initialEase = 2.5;
  static const double maxIntervalDays = 180;
  static const double masteredIntervalDays = 21;
  static const Duration fastThreshold = Duration(seconds: 8);
  static const Duration lapseDelay = Duration(minutes: 10);
}

class SrsCard {
  final String itemKey;
  final SrsState state;
  final DateTime dueAt;
  final double intervalDays;
  final double ease;
  final int lapses;
  final int reps;

  /// 连续答对次数。答错清零。旧数据缺这个字段时当作 0。
  final int correctStreak;
  final DateTime? lastReviewedAt;
  final int updatedAt;

  const SrsCard({
    required this.itemKey,
    required this.state,
    required this.dueAt,
    required this.intervalDays,
    this.ease = SrsLimits.initialEase,
    this.lapses = 0,
    this.reps = 0,
    this.correctStreak = 0,
    this.lastReviewedAt,
    this.updatedAt = 0,
  });

  bool get isMastered =>
      state == SrsState.review &&
      intervalDays >= SrsLimits.masteredIntervalDays;

  SrsCard copyWith({
    SrsState? state,
    DateTime? dueAt,
    double? intervalDays,
    double? ease,
    int? lapses,
    int? reps,
    int? correctStreak,
    DateTime? lastReviewedAt,
    int? updatedAt,
  }) {
    return SrsCard(
      itemKey: itemKey,
      state: state ?? this.state,
      dueAt: dueAt ?? this.dueAt,
      intervalDays: intervalDays ?? this.intervalDays,
      ease: ease ?? this.ease,
      lapses: lapses ?? this.lapses,
      reps: reps ?? this.reps,
      correctStreak: correctStreak ?? this.correctStreak,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemKey': itemKey,
      'state': state == SrsState.review ? 'review' : 'learning',
      'dueAt': dueAt.millisecondsSinceEpoch,
      'intervalDays': intervalDays,
      'ease': ease,
      'lapses': lapses,
      'reps': reps,
      'correctStreak': correctStreak,
      if (lastReviewedAt != null)
        'lastReviewedAt': lastReviewedAt!.millisecondsSinceEpoch,
      'updatedAt': updatedAt,
    };
  }

  /// 缺字段时用默认值，避免旧数据读不出来。
  factory SrsCard.fromJson(
    Map<String, dynamic> json, {
    String? fallbackItemKey,
  }) {
    final rawKey = json['itemKey'];
    final itemKey = rawKey is String && rawKey.isNotEmpty
        ? rawKey
        : (fallbackItemKey ?? '');
    return SrsCard(
      itemKey: itemKey,
      state: json['state'] == 'review' ? SrsState.review : SrsState.learning,
      dueAt: DateTime.fromMillisecondsSinceEpoch(_asInt(json['dueAt']) ?? 0),
      intervalDays: _asDouble(json['intervalDays']) ?? 0,
      ease: _asDouble(json['ease']) ?? SrsLimits.initialEase,
      lapses: _asInt(json['lapses']) ?? 0,
      reps: _asInt(json['reps']) ?? 0,
      correctStreak: _asInt(json['correctStreak']) ?? 0,
      lastReviewedAt: _asTime(json['lastReviewedAt']),
      updatedAt: _asInt(json['updatedAt']) ?? 0,
    );
  }
}

int? _asInt(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.round();
  return null;
}

double? _asDouble(Object? raw) {
  if (raw is double) return raw;
  if (raw is num) return raw.toDouble();
  return null;
}

DateTime? _asTime(Object? raw) {
  final millis = _asInt(raw);
  if (millis == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(millis);
}
