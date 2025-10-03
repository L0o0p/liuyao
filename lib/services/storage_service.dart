import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/module_progress.dart';

/// 本地存储服务
/// 负责管理用户学习进度的持久化存储
/// 使用 SharedPreferences 作为存储引擎
class StorageService {
  static const String _keyPrefix = 'module_progress_';

  /// 保存模块进度到本地
  /// @param progress 要保存的进度对象
  static Future<void> saveProgress(ModuleProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyPrefix + progress.moduleId;
    final jsonString = jsonEncode(progress.toJson());
    await prefs.setString(key, jsonString);
  }

  /// 从本地加载模块进度
  /// @param moduleId 模块ID
  /// @return 进度对象，如果不存在则返回新创建的默认进度
  static Future<ModuleProgress> loadProgress(String moduleId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyPrefix + moduleId;
    final jsonString = prefs.getString(key);

    if (jsonString == null) {
      // 首次学习该模块，返回默认进度
      return ModuleProgress(moduleId: moduleId);
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ModuleProgress.fromJson(json);
    } catch (e) {
      // 解析失败，返回默认进度
      print('Failed to parse progress for $moduleId: $e');
      return ModuleProgress(moduleId: moduleId);
    }
  }

  /// 清除某个模块的进度（重置学习）
  /// @param moduleId 模块ID
  static Future<void> clearProgress(String moduleId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyPrefix + moduleId;
    await prefs.remove(key);
  }

  /// 清除所有模块的进度
  static Future<void> clearAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_keyPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  /// 检查模块是否是首次学习
  /// @param moduleId 模块ID
  /// @return true 表示首次学习，false 表示已有学习记录
  static Future<bool> isFirstTime(String moduleId) async {
    final progress = await loadProgress(moduleId);
    return !progress.firstRoundCompleted;
  }
}
