import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 的薄封装。
/// 每条可同步的数据都是一份完整 JSON，并带有 updatedAt。
/// 删除写成带 deleted 标记的记录，而不是直接抹掉，方便以后同步到其他设备。
class LocalStore {
  LocalStore();

  static final LocalStore instance = LocalStore();

  static const String schemaVersionKey = 'schema_version';
  static const int currentSchemaVersion = 2;
  static const String pendingSyncKey = '_pending_sync_keys';
  static const String syncCursorKey = 'sync_cursor';

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

  /// 把旧的 module_progress_* 和 wrong_questions 迁到新键。
  /// 成功后删除旧键，并写入 schema_version = 2。
  Future<void> migrateIfNeeded() async {
    final prefs = await _prefs();
    final version = prefs.getInt(schemaVersionKey) ?? 0;
    if (version >= currentSchemaVersion) return;

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
      final raw = prefs.getString(key);
      if (raw == null) continue;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw FormatException('无法迁移 $key');
      }
      final map = Map<String, dynamic>.from(decoded);
      map['updatedAt'] = updatedAtOf(map);
      final moduleId = key.substring(legacyProgressPrefix.length);
      writes['$progressPrefix$moduleId'] = map;
    }

    final wrongRaw = prefs.getString(legacyWrongKey);
    if (wrongRaw != null) {
      final decoded = jsonDecode(wrongRaw);
      if (decoded is! List) {
        throw FormatException('无法迁移 $legacyWrongKey');
      }
      for (final item in decoded) {
        if (item is! Map) {
          throw FormatException('错题记录格式不正确');
        }
        final map = Map<String, dynamic>.from(item);
        map['updatedAt'] = updatedAtOf(map);
        final type = map['questionType'];
        final input = map['input'];
        if (type is! String || input is! String) {
          throw FormatException('错题记录缺少题型或输入');
        }
        writes['$wrongPrefix$type:$input'] = map;
      }
    }

    for (final entry in writes.entries) {
      await writeRaw(entry.key, entry.value, pending: true);
    }
    for (final key in oldKeys) {
      await prefs.remove(key);
    }
    await prefs.setInt(schemaVersionKey, currentSchemaVersion);
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
}
