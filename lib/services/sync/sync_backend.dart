/// 可替换的同步后端。本阶段只有空实现，以后接入云端时替换它即可。
abstract class SyncBackend {
  /// 拉取 since 之后云端有变化的条目。
  Future<Map<String, Map<String, dynamic>>> pull({required int since});

  /// 推送本地有变化的条目，返回已被云端接受的键。
  Future<Set<String>> push(Map<String, Map<String, dynamic>> items);
}

/// 什么都不做的同步实现。拉取永远为空，推送也不会被接受。
class NoopSyncBackend implements SyncBackend {
  @override
  Future<Map<String, Map<String, dynamic>>> pull({required int since}) async {
    return {};
  }

  @override
  Future<Set<String>> push(Map<String, Map<String, dynamic>> items) async {
    return {};
  }
}
