import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../local_store.dart';
import 'sync_backend.dart';

/// 导入结果：applied 是写入本地的条数，keptLocal 是因本地较新而保留的条数。
class ImportResult {
  final int applied;
  final int keptLocal;

  const ImportResult({required this.applied, required this.keptLocal});
}

/// 调度同步、按 updatedAt 合并，并在本地数据变化后通知界面。
/// 任何失败都静默吞掉，不阻塞界面。
class SyncEngine {
  SyncEngine({SyncBackend? backend}) : _backend = backend ?? NoopSyncBackend();

  static final SyncEngine instance = SyncEngine();

  /// 数据版本号。合并真正改写本地数据后自增，进度页监听它来刷新。
  static final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);

  final SyncBackend _backend;
  Future<void>? _inFlight;

  /// 启动、回到前台、结束一次练习时调用。已在进行的同步不会重入。
  Future<void> sync() {
    final current = _inFlight;
    if (current != null) return current;
    final flight = _sync();
    _inFlight = flight;
    return flight.whenComplete(() {
      if (identical(_inFlight, flight)) {
        _inFlight = null;
      }
    });
  }

  /// 对每个键比较 updatedAt，较新者胜。时间相同保留本地。
  /// 删除标记只是带 deleted 的普通记录，同样参与比较。
  static Map<String, Map<String, dynamic>> merge({
    required Map<String, Map<String, dynamic>> local,
    required Map<String, Map<String, dynamic>> remote,
  }) {
    final result = <String, Map<String, dynamic>>{};
    final keys = <String>{...local.keys, ...remote.keys};
    for (final key in keys) {
      final left = local[key];
      final right = remote[key];
      if (left == null && right == null) continue;
      if (left == null) {
        result[key] = Map<String, dynamic>.from(right!);
        continue;
      }
      if (right == null) {
        result[key] = Map<String, dynamic>.from(left);
        continue;
      }
      final leftAt = LocalStore.updatedAtOf(left);
      final rightAt = LocalStore.updatedAtOf(right);
      final winner = rightAt > leftAt ? right : left;
      result[key] = Map<String, dynamic>.from(winner);
    }
    return result;
  }

  /// 把进度和错题打成一份可分享的 JSON。
  Future<Map<String, dynamic>> exportDocument() async {
    final items = <String, Map<String, dynamic>>{};
    for (final prefix in [LocalStore.srsPrefix]) {
      final keys = await LocalStore.instance.keysWithPrefix(prefix);
      for (final key in keys) {
        final value = await LocalStore.instance.get(key);
        if (value != null) {
          items[key] = value;
        }
      }
    }
    return {
      'schema_version': LocalStore.currentSchemaVersion,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
      'items': items,
    };
  }

  /// 校验导出文件，再按合并规则写入。不会覆盖本地较新的数据。
  Future<ImportResult> importJson(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('学习数据格式不正确');
    }
    final document = Map<String, dynamic>.from(decoded);
    final version = document['schema_version'];
    if (version is! num || version != LocalStore.currentSchemaVersion) {
      throw FormatException('不支持的学习数据版本：$version');
    }
    final itemsRaw = document['items'];
    if (itemsRaw is! Map) {
      throw const FormatException('学习数据缺少 items');
    }

    final incoming = <String, Map<String, dynamic>>{};
    for (final entry in itemsRaw.entries) {
      final key = entry.key.toString();
      if (!key.startsWith(LocalStore.srsPrefix)) {
        continue;
      }
      if (entry.value is! Map) {
        throw FormatException('条目格式不正确：$key');
      }
      final value = Map<String, dynamic>.from(entry.value as Map);
      value['updatedAt'] = LocalStore.updatedAtOf(value);
      incoming[key] = value;
    }

    return _applyIncoming(incoming);
  }

  Future<void> _sync() async {
    try {
      final store = LocalStore.instance;
      final since = await store.getSyncCursor();
      final remote = await _backend.pull(since: since);
      final pending = await store.pendingValues();
      final local = Map<String, Map<String, dynamic>>.from(pending);
      for (final key in remote.keys) {
        final stored = await store.get(key);
        if (stored != null) {
          local[key] = stored;
        }
      }

      final merged = merge(local: local, remote: remote);
      var changed = false;
      var cursor = since;
      for (final entry in remote.entries) {
        final winner = merged[entry.key];
        if (winner == null) continue;
        cursor = _max(cursor, LocalStore.updatedAtOf(entry.value));
        if (_jsonEquals(local[entry.key], winner)) continue;
        // 云端获胜的条目已经在远端，不必再推回去。
        await store.writeRaw(entry.key, winner, pending: false);
        changed = true;
      }

      final toPush = await store.pendingValues();
      if (toPush.isNotEmpty) {
        final accepted = await _backend.push(toPush);
        if (accepted.isNotEmpty) {
          await store.clearPending(accepted);
          for (final key in accepted) {
            final value = toPush[key];
            if (value != null) {
              cursor = _max(cursor, LocalStore.updatedAtOf(value));
            }
          }
        }
      }

      if (cursor != since) {
        await store.setSyncCursor(cursor);
      }
      if (changed) {
        dataVersion.value++;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('同步失败，已忽略: $e');
      }
    }
  }

  Future<ImportResult> _applyIncoming(
    Map<String, Map<String, dynamic>> incoming,
  ) async {
    final store = LocalStore.instance;
    final local = <String, Map<String, dynamic>>{};
    for (final key in incoming.keys) {
      final stored = await store.get(key);
      if (stored != null) {
        local[key] = stored;
      }
    }
    final merged = merge(local: local, remote: incoming);
    var applied = 0;
    var keptLocal = 0;
    for (final key in incoming.keys) {
      final winner = merged[key];
      if (winner == null) continue;
      if (_jsonEquals(local[key], winner)) {
        keptLocal++;
        continue;
      }
      // 导入的数据以后仍要能同步出去，所以记入待同步集合。
      await store.writeRaw(key, winner, pending: true);
      applied++;
    }
    if (applied > 0) {
      dataVersion.value++;
    }
    return ImportResult(applied: applied, keptLocal: keptLocal);
  }

  static int _max(int a, int b) => a > b ? a : b;

  static bool _jsonEquals(
    Map<String, dynamic>? left,
    Map<String, dynamic>? right,
  ) {
    if (left == null || right == null) return left == null && right == null;
    return jsonEncode(left) == jsonEncode(right);
  }
}
