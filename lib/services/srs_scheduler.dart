import '../models/srs_card.dart';

/// 今日队列拆成到期部分和新学部分。
class TodayPlan {
  final List<String> dueKeys;
  final List<String> newKeys;

  const TodayPlan({required this.dueKeys, required this.newKeys});

  List<String> get itemKeys => [...dueKeys, ...newKeys];

  int get dueCount => dueKeys.length;

  int get newCount => newKeys.length;

  bool get isEmpty => itemKeys.isEmpty;
}

/// 一个模块里已掌握、学习中、未学的条数。
class SrsCounts {
  final int mastered;
  final int learning;
  final int unseen;

  const SrsCounts({
    required this.mastered,
    required this.learning,
    required this.unseen,
  });

  int get total => mastered + learning + unseen;
}

/// 纯函数调度。不读存储，方便单测。
class SrsScheduler {
  /// 新卡第一次出现：learning，立刻到期。
  static SrsCard introduce(String itemKey, DateTime now) {
    return SrsCard(
      itemKey: itemKey,
      state: SrsState.learning,
      dueAt: now,
      intervalDays: 0,
      ease: SrsLimits.initialEase,
    );
  }

  /// 二元评分。
  /// 答错：连续答对清零，回到 learning，间隔清掉，10 分钟后再到期。
  /// 有失误且连续答对还没到 2：记一次答对，但间隔先不拉长。
  /// 没失误过，或连续第二次答对：learning 毕业为 1 天；review 间隔乘 ease，封顶 180 天。
  /// 超过 8 秒的间隔折扣只作用在这一次真正毕业上。
  static SrsCard grade({
    required SrsCard card,
    required bool correct,
    required Duration elapsed,
    required DateTime now,
    bool missedInSession = false,
  }) {
    final reviewed = card.copyWith(reps: card.reps + 1, lastReviewedAt: now);
    if (!correct) {
      return reviewed.copyWith(
        state: SrsState.learning,
        intervalDays: 0,
        dueAt: now.add(SrsLimits.lapseDelay),
        lapses: card.lapses + 1,
        correctStreak: 0,
      );
    }

    final nextStreak = card.correctStreak + 1;
    if (_awaitingSecondCorrect(card, missedInSession: missedInSession)) {
      return reviewed.copyWith(correctStreak: nextStreak);
    }

    final days = _nextIntervalDays(
      state: card.state,
      intervalDays: card.intervalDays,
      ease: card.ease,
      fast: elapsed <= SrsLimits.fastThreshold,
    );
    return reviewed.copyWith(
      state: SrsState.review,
      intervalDays: days,
      dueAt: addDays(now, days),
      correctStreak: nextStreak,
    );
  }

  /// 答错，或有失误且这次答对还凑不满连续 2 次。此时间隔先不拉长。
  static bool replaysInSession({
    required SrsCard card,
    required bool correct,
    bool missedInSession = false,
  }) {
    if (!correct) return true;
    return _awaitingSecondCorrect(card, missedInSession: missedInSession);
  }

  /// [card] 是这次答对之前的卡片。
  static bool _awaitingSecondCorrect(
    SrsCard card, {
    required bool missedInSession,
  }) {
    final hadMistake = card.lapses > 0 || missedInSession;
    return hadMistake && card.correctStreak + 1 < 2;
  }

  /// 60 分映射到 1 天，100 分映射到 7 天。
  static double intervalDaysForScore(int score) {
    final clamped = score.clamp(60, 100).toInt();
    return 1 + (clamped - 60) * 6 / 40;
  }

  static DateTime addDays(DateTime now, double days) {
    final micros = (days * Duration.microsecondsPerDay).round();
    return now.add(Duration(microseconds: micros));
  }

  static bool isDue(SrsCard card, DateTime now) => !card.dueAt.isAfter(now);

  static bool isMastered(SrsCard card) => card.isMastered;

  /// 先放到期卡，再放今天要引入的那组里还没有卡片的知识点。
  /// 不引入新组时 [groupKeys] 为空。
  static TodayPlan planToday({
    required List<String> catalogOrder,
    required Map<String, SrsCard> cards,
    required DateTime now,
    List<String> groupKeys = const [],
  }) {
    final order = <String, int>{
      for (var i = 0; i < catalogOrder.length; i++) catalogOrder[i]: i,
    };
    final due = <String>[];
    for (final key in catalogOrder) {
      final card = cards[key];
      if (card != null && isDue(card, now)) due.add(key);
    }
    due.sort((a, b) {
      final byTime = cards[a]!.dueAt.compareTo(cards[b]!.dueAt);
      if (byTime != 0) return byTime;
      return order[a]!.compareTo(order[b]!);
    });
    return TodayPlan(
      dueKeys: due,
      newKeys: [
        for (final key in groupKeys)
          if (!cards.containsKey(key)) key,
      ],
    );
  }

  /// 到期或学习中的在前，其余已有卡片按离到期从近到远，没学过的按目录顺序垫后。
  /// 不受今日小组引入的约束。
  static List<String> moduleQueue({
    required List<String> moduleItemKeys,
    required Map<String, SrsCard> cards,
    required DateTime now,
  }) {
    final order = <String, int>{
      for (var i = 0; i < moduleItemKeys.length; i++) moduleItemKeys[i]: i,
    };
    final front = <String>[];
    final later = <String>[];
    final unseen = <String>[];
    for (final key in moduleItemKeys) {
      final card = cards[key];
      if (card == null) {
        unseen.add(key);
        continue;
      }
      if (card.state == SrsState.learning || isDue(card, now)) {
        front.add(key);
      } else {
        later.add(key);
      }
    }
    int compare(String a, String b) {
      final byTime = cards[a]!.dueAt.compareTo(cards[b]!.dueAt);
      if (byTime != 0) return byTime;
      return order[a]!.compareTo(order[b]!);
    }

    front.sort(compare);
    later.sort(compare);
    return [...front, ...later, ...unseen];
  }

  static SrsCounts count(Iterable<String> itemKeys, Map<String, SrsCard> cards) {
    var mastered = 0;
    var learning = 0;
    var unseen = 0;
    for (final key in itemKeys) {
      final card = cards[key];
      if (card == null) {
        unseen++;
      } else if (isMastered(card)) {
        mastered++;
      } else {
        learning++;
      }
    }
    return SrsCounts(mastered: mastered, learning: learning, unseen: unseen);
  }

  /// 连续学习天数，按本地日历日计。
  /// 卡片只留最后一次复习时间，同一张卡更早的复习日看不到，所以结果只会偏少。
  /// 今天还没复习时从昨天往前数，不让连续记录在当天早上就断掉。
  static int studyStreakDays(Iterable<SrsCard> cards, DateTime now) {
    final days = <DateTime>{};
    for (final card in cards) {
      final reviewed = card.lastReviewedAt?.toLocal();
      if (reviewed == null) continue;
      days.add(DateTime(reviewed.year, reviewed.month, reviewed.day));
    }
    final local = now.toLocal();
    var day = DateTime(local.year, local.month, local.day);
    if (!days.contains(day)) {
      day = DateTime(day.year, day.month, day.day - 1);
    }
    var streak = 0;
    while (days.contains(day)) {
      streak++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return streak;
  }

  static double _nextIntervalDays({
    required SrsState state,
    required double intervalDays,
    required double ease,
    required bool fast,
  }) {
    final target = state == SrsState.learning
        ? 1.0
        : _min(SrsLimits.maxIntervalDays, intervalDays * ease);
    if (fast) return target;
    return intervalDays + (target - intervalDays) / 2;
  }

  static double _min(double a, double b) => a < b ? a : b;
}
