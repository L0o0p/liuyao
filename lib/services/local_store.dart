import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/knowledge_catalog.dart';
import '../models/srs_card.dart';
import 'srs_scheduler.dart';

/// SharedPreferences 的薄封装。
/// 每条可同步的数据都是一份完整 JSON，并带有 updatedAt。
/// 删除写成带 deleted 标记的记录，而不是直接抹掉，方便以后同步到其他设备。
class LocalStore {
  LocalStore();

  static final LocalStore instance = LocalStore();

  static const String schemaVersionKey = 'schema_version';
  static const int currentSchemaVersion = 4;
  static const String pendingSyncKey = '_pending_sync_keys';
  static const String syncCursorKey = 'sync_cursor';

  static const String srsPrefix = 'srs:';
  static const String srsDailyKey = 'srs_daily';
  static const String progressPrefix = 'progress:';
  static const String wrongPrefix = 'wrong:';
  static const String legacyProgressPrefix = 'module_progress_';
  static const String legacyWrongKey = 'wrong_questions';

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  /// 读取一条记录。删除标记也会原样返回，调用方自己判断。
  Future<Map<String, dynamic>?> get(String key) async {
    final prefs = await _prefs();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// 写入一条记录，并记入待同步集合。
  /// 调用方如果已经写入了正的 updatedAt，则原样保留，便于内存和磁盘一致；
  /// 没有时间戳时自动补上当前时间。
  Future<void> put(String key, Map<String, dynamic> value) async {
    final stored = Map<String, dynamic>.from(value);
    final current = updatedAtOf(stored);
    if (current <= 0) {
      stored['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    }
    stored.remove('deleted');
    await _write(key, stored, pending: true);
  }

  /// 按原样写入，不改 updatedAt。迁移和合并远程数据时使用。
  Future<void> writeRaw(
    String key,
    Map<String, dynamic> value, {
    required bool pending,
  }) async {
    final stored = Map<String, dynamic>.from(value);
    stored['updatedAt'] = updatedAtOf(stored);
    await _write(key, stored, pending: pending);
  }

  /// 写入不参与同步的本地 JSON，例如当天引入过的小组。
  Future<void> writePlain(String key, Map<String, dynamic> value) async {
    final prefs = await _prefs();
    await prefs.setString(key, jsonEncode(value));
  }

  /// 写入删除标记，而不是物理删除。
  Future<void> delete(String key) async {
    await _write(key, {
      'deleted': true,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, pending: true);
  }

  Future<List<String>> keysWithPrefix(String prefix) async {
    final prefs = await _prefs();
    return prefs.getKeys().where((key) => key.startsWith(prefix)).toList();
  }

  /// 返回待同步集合里、updatedAt 晚于 [timestamp] 的条目。
  /// timestamp 为 0 时返回全部待同步条目，包括迁移来的 updatedAt = 0。
  Future<Map<String, Map<String, dynamic>>> changedSince(int timestamp) async {
    final prefs = await _prefs();
    final pending = await _readPending(prefs);
    final result = <String, Map<String, dynamic>>{};
    for (final key in pending) {
      final value = await get(key);
      if (value == null) continue;
      if (timestamp == 0 || updatedAtOf(value) > timestamp) {
        result[key] = value;
      }
    }
    return result;
  }

  Future<Map<String, Map<String, dynamic>>> pendingValues() async {
    return changedSince(0);
  }

  Future<void> clearPending(Set<String> keys) async {
    if (keys.isEmpty) return;
    final prefs = await _prefs();
    final pending = await _readPending(prefs);
    pending.removeAll(keys);
    await _savePending(prefs, pending);
  }

  Future<int> getSyncCursor() async {
    final prefs = await _prefs();
    return prefs.getInt(syncCursorKey) ?? 0;
  }

  Future<void> setSyncCursor(int timestamp) async {
    final prefs = await _prefs();
    await prefs.setInt(syncCursorKey, timestamp);
  }

  /// 把旧进度和错题迁到 srs:{itemKey}，再把旧十二长生卡并到规则卡上。
  /// 版本 2 之前先把 module_progress_* / wrong_questions 收成 progress: 和 wrong:。
  /// 成功后再删旧键，并写入 schema_version = 4。
  Future<void> migrateIfNeeded() async {
    final prefs = await _prefs();
    final version = prefs.getInt(schemaVersionKey) ?? 0;
    if (version >= currentSchemaVersion) return;

    if (version < 2) {
      await _migrateLegacy(prefs);
    }
    if (version < 3) {
      await _migrateToSrs(prefs);
    }
    await _migrateChangSheng(prefs);
    await prefs.setInt(schemaVersionKey, currentSchemaVersion);
  }

  /// 旧卡写删除标记并记入待同步，其他设备同步后也会删掉。
  Future<void> _migrateChangSheng(SharedPreferences prefs) async {
    final cards = <String, SrsCard>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_changShengSrsPrefix)) continue;
      final map = _readObject(prefs, key);
      if (map == null || isDeleted(map)) continue;
      final itemKey = key.substring(srsPrefix.length);
      cards[itemKey] = SrsCard.fromJson(map, fallbackItemKey: itemKey);
    }
    final merged = mergeLegacyChangSheng(cards);
    for (final card in merged.ruleCards.values) {
      await writeRaw('$srsPrefix${card.itemKey}', card.toJson(), pending: true);
    }
    for (final itemKey in merged.legacyKeys) {
      await delete('$srsPrefix$itemKey');
    }
  }

  /// 旧版和新版十二长生卡的 srs: 键都以此开头。
  static const String _changShengSrsPrefix =
      '$srsPrefix${KnowledgeCatalog.legacyChangShengType}';

  static const String _legacyChangShengPrefix =
      '${KnowledgeCatalog.legacyChangShengType}:';

  /// 把旧十二长生卡（changsheng:日支_爻支）并到它依赖的两张规则卡上：
  /// 按日支五行并到起点卡，按推出的阶段并到阶段卡。启动迁移和导入共用。
  ///
  /// 同一规则卡收到多张旧卡时取最弱的那张（learning 弱于 review，其次间隔更短、
  /// 到期更早），lapses、reps 取最大，updatedAt 和 lastReviewedAt 取最晚。
  /// [cards] 里已有这张规则卡时按 updatedAt 较新者保留，相同时保留已有的。
  /// 返回要写入的规则卡和要删掉的旧卡键（认不出的旧键也在内）。没有旧卡时都为空。
  static ({Map<String, SrsCard> ruleCards, Set<String> legacyKeys})
  mergeLegacyChangSheng(Map<String, SrsCard> cards) {
    final legacyKeys = <String>{};
    final grouped = <String, List<SrsCard>>{};
    for (final entry in cards.entries) {
      if (!entry.key.startsWith(_legacyChangShengPrefix)) continue;
      legacyKeys.add(entry.key);
      final rules = KnowledgeCatalog.legacyChangShengRules(
        entry.key.substring(_legacyChangShengPrefix.length),
      );
      if (rules == null) continue;
      for (final ruleKey in [rules.startKey, rules.stageKey]) {
        grouped.putIfAbsent(ruleKey, () => []).add(entry.value);
      }
    }

    final ruleCards = <String, SrsCard>{};
    for (final entry in grouped.entries) {
      final group = entry.value;
      var weakest = group.first;
      var lapses = 0;
      var reps = 0;
      var updatedAt = 0;
      DateTime? lastReviewedAt;
      for (final card in group) {
        if (_isWeaker(card, weakest)) weakest = card;
        if (card.lapses > lapses) lapses = card.lapses;
        if (card.reps > reps) reps = card.reps;
        updatedAt = _max(updatedAt, card.updatedAt);
        final reviewed = card.lastReviewedAt;
        if (reviewed != null &&
            (lastReviewedAt == null || reviewed.isAfter(lastReviewedAt))) {
          lastReviewedAt = reviewed;
        }
      }
      final existing = cards[entry.key];
      if (existing != null && existing.updatedAt >= updatedAt) continue;
      ruleCards[entry.key] = SrsCard(
        itemKey: entry.key,
        state: weakest.state,
        dueAt: weakest.dueAt,
        intervalDays: weakest.intervalDays,
        ease: weakest.ease,
        lapses: lapses,
        reps: reps,
        correctStreak: weakest.correctStreak,
        lastReviewedAt: lastReviewedAt,
        updatedAt: updatedAt,
      );
    }
    return (ruleCards: ruleCards, legacyKeys: legacyKeys);
  }

  /// 导入用：去掉 srs: 记录里的旧十二长生卡（含删除标记），换成并好的规则卡。
  static Map<String, Map<String, dynamic>> recordsWithChangShengRules(
    Map<String, Map<String, dynamic>> records,
  ) {
    final cards = <String, SrsCard>{};
    for (final entry in records.entries) {
      if (!entry.key.startsWith(_changShengSrsPrefix)) continue;
      if (isDeleted(entry.value)) continue;
      final itemKey = entry.key.substring(srsPrefix.length);
      cards[itemKey] = SrsCard.fromJson(entry.value, fallbackItemKey: itemKey);
    }
    final merged = mergeLegacyChangSheng(cards);
    final result = <String, Map<String, dynamic>>{
      for (final entry in records.entries)
        if (!entry.key.startsWith('$srsPrefix$_legacyChangShengPrefix'))
          entry.key: entry.value,
    };
    for (final card in merged.ruleCards.values) {
      result['$srsPrefix${card.itemKey}'] = card.toJson();
    }
    return result;
  }

  static bool _isWeaker(SrsCard a, SrsCard b) {
    if (a.state != b.state) return a.state == SrsState.learning;
    if (a.intervalDays != b.intervalDays) {
      return a.intervalDays < b.intervalDays;
    }
    return a.dueAt.isBefore(b.dueAt);
  }

  Future<void> _migrateLegacy(SharedPreferences prefs) async {
    final oldKeys = prefs
        .getKeys()
        .where(
          (key) =>
              key.startsWith(legacyProgressPrefix) || key == legacyWrongKey,
        )
        .toList();

    final writes = <String, Map<String, dynamic>>{};

    for (final key in oldKeys) {
      if (!key.startsWith(legacyProgressPrefix)) continue;
      final map = _readObject(prefs, key);
      if (map == null) continue;
      map['updatedAt'] = updatedAtOf(map);
      final moduleId = key.substring(legacyProgressPrefix.length);
      writes['$progressPrefix$moduleId'] = map;
    }

    final wrongRaw = prefs.getString(legacyWrongKey);
    if (wrongRaw != null) {
      final decoded = _decode(wrongRaw);
      if (decoded is! List) {
        throw FormatException('无法迁移 $legacyWrongKey');
      }
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final type = map['questionType'];
        final input = map['input'];
        if (type is! String ||
            input is! String ||
            type.isEmpty ||
            input.isEmpty) {
          continue;
        }
        map['updatedAt'] = updatedAtOf(map);
        writes['$wrongPrefix$type:$input'] = map;
      }
    }

    for (final entry in writes.entries) {
      await writeRaw(entry.key, entry.value, pending: true);
    }
    for (final key in oldKeys) {
      await prefs.remove(key);
    }
  }

  /// 错题变成立刻到期的卡，lapses 取 wrongCount。
  /// 对得上 itemKey 且分数 >= 60 的熟练度变成 review，间隔按分数映射到 1–7 天；
  /// 其余已学条目变成 learning，立刻到期。两边都有时，错题把到期时间拉到现在。
  Future<void> _migrateToSrs(SharedPreferences prefs) async {
    final oldKeys = prefs
        .getKeys()
        .where(
          (key) =>
              key.startsWith(progressPrefix) || key.startsWith(wrongPrefix),
        )
        .toList();

    final records = <String, Map<String, dynamic>>{};
    for (final key in oldKeys) {
      final map = _readObject(prefs, key);
      if (map != null) records[key] = map;
    }
    final cards = cardsFromVersion2(records, DateTime.now());

    for (final card in cards.values) {
      await writeRaw('$srsPrefix${card.itemKey}', card.toJson(), pending: true);
    }
    for (final key in oldKeys) {
      await prefs.remove(key);
    }
  }

  /// 把版本 2 的 progress: 和 wrong: 记录转成复习卡片。
  /// 启动迁移和导入旧备份共用这一套规则。
  static Map<String, SrsCard> cardsFromVersion2(
    Map<String, Map<String, dynamic>> records,
    DateTime now,
  ) {
    final cards = <String, SrsCard>{};

    for (final entry in records.entries) {
      if (!entry.key.startsWith(progressPrefix)) continue;
      final map = entry.value;
      if (map['deleted'] == true) continue;
      final progressUpdated = updatedAtOf(map);
      final scores = <String, int>{};
      final proficiency = map['proficiency'];
      if (proficiency is Map) {
        proficiency.forEach((rawKey, value) {
          final itemKey = rawKey.toString();
          final score = _asInt(value);
          if (score == null || !_isKnownItemKey(itemKey)) return;
          final previous = scores[itemKey];
          if (previous == null || score > previous) {
            scores[itemKey] = score;
          }
        });
      }
      final learned = <String>{};
      final learnedRaw = map['learnedItems'];
      if (learnedRaw is List) {
        for (final item in learnedRaw) {
          if (item is String && _isKnownItemKey(item)) learned.add(item);
        }
      }

      for (final itemKey in {...scores.keys, ...learned}) {
        final score = scores[itemKey];
        final SrsCard card;
        if (score != null && score >= 60) {
          final days = SrsScheduler.intervalDaysForScore(score);
          card = SrsCard(
            itemKey: itemKey,
            state: SrsState.review,
            dueAt: SrsScheduler.addDays(now, days),
            intervalDays: days,
            ease: SrsLimits.initialEase,
            updatedAt: progressUpdated,
          );
        } else {
          card = SrsCard(
            itemKey: itemKey,
            state: SrsState.learning,
            dueAt: now,
            intervalDays: 0,
            ease: SrsLimits.initialEase,
            updatedAt: progressUpdated,
          );
        }
        _keepPreferredCard(cards, card);
      }
    }

    for (final entry in records.entries) {
      if (!entry.key.startsWith(wrongPrefix)) continue;
      final map = entry.value;
      if (map['deleted'] == true) continue;
      final type = map['questionType'];
      final input = map['input'];
      if (type is! String ||
          input is! String ||
          type.isEmpty ||
          input.isEmpty) {
        continue;
      }
      final itemKey = '$type:$input';
      final parsedLapses = _asInt(map['wrongCount']);
      final lapses = parsedLapses == null
          ? 1
          : (parsedLapses < 0 ? 0 : parsedLapses);
      final recordUpdated = updatedAtOf(map);
      final existing = cards[itemKey];
      final lastReviewedAt = _parseTime(map['lastWrongTime']);
      if (existing == null) {
        cards[itemKey] = SrsCard(
          itemKey: itemKey,
          state: SrsState.learning,
          dueAt: now,
          intervalDays: 0,
          ease: SrsLimits.initialEase,
          lapses: lapses,
          lastReviewedAt: lastReviewedAt,
          updatedAt: recordUpdated,
        );
      } else {
        cards[itemKey] = existing.copyWith(
          dueAt: now,
          lapses: lapses,
          lastReviewedAt: lastReviewedAt ?? existing.lastReviewedAt,
          updatedAt: _max(existing.updatedAt, recordUpdated),
        );
      }
    }

    return cards;
  }

  static int updatedAtOf(Map<String, dynamic> value) {
    final raw = value['updatedAt'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return 0;
  }

  static bool isDeleted(Map<String, dynamic>? value) =>
      value?['deleted'] == true;

  Future<void> _write(
    String key,
    Map<String, dynamic> value, {
    required bool pending,
  }) async {
    final prefs = await _prefs();
    await prefs.setString(key, jsonEncode(value));
    final keys = await _readPending(prefs);
    if (pending) {
      keys.add(key);
    } else {
      keys.remove(key);
    }
    await _savePending(prefs, keys);
  }

  Future<Set<String>> _readPending(SharedPreferences prefs) async {
    final raw = prefs.getString(pendingSyncKey);
    if (raw == null) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toSet();
      }
    } catch (_) {
      return <String>{};
    }
    return <String>{};
  }

  Future<void> _savePending(SharedPreferences prefs, Set<String> keys) async {
    await prefs.setString(pendingSyncKey, jsonEncode(keys.toList()));
  }

  Map<String, dynamic>? _readObject(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return null;
    final decoded = _decode(raw);
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  }

  Object? _decode(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  /// 旧十二长生键也算认得，留给后面并到规则卡上。
  static bool _isKnownItemKey(String itemKey) {
    final separator = itemKey.indexOf(':');
    if (separator <= 0 || separator >= itemKey.length - 1) return false;
    final type = itemKey.substring(0, separator);
    final input = itemKey.substring(separator + 1);
    if (type == KnowledgeCatalog.legacyChangShengType) {
      return KnowledgeCatalog.legacyChangShengRules(input) != null;
    }
    return KnowledgeCatalog.find(type, input) != null;
  }

  static void _keepPreferredCard(Map<String, SrsCard> cards, SrsCard card) {
    final existing = cards[card.itemKey];
    if (existing == null) {
      cards[card.itemKey] = card;
      return;
    }
    final preferIncoming =
        card.state == SrsState.review &&
        (existing.state != SrsState.review ||
            card.intervalDays > existing.intervalDays);
    final winner = preferIncoming ? card : existing;
    cards[card.itemKey] = winner.copyWith(
      updatedAt: _max(existing.updatedAt, card.updatedAt),
    );
  }

  static int? _asInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return null;
  }

  static DateTime? _parseTime(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static int _max(int a, int b) => a > b ? a : b;
}
