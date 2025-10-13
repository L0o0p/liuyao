import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/module_progress.dart';
import '../models/wrong_question_record.dart';

class CloudKitStorageService {
  static const platform = MethodChannel('cloudkit_channel');

  /// 保存学习进度
  static Future<bool> saveProgress(String word, int score) async {
    try {
      await platform.invokeMethod('saveProgress', {
        'word': word,
        'score': score,
      });
      if (kDebugMode) {
        print('✅ CloudKit 存储成功: $word - $score');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ CloudKit 存储失败: $e');
      }
      return false;
    }
  }

  /// 获取学习进度
  static Future<List<Map<String, dynamic>>> fetchProgress() async {
    try {
      final result = await platform.invokeMethod('fetchProgress');
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      if (kDebugMode) {
        print('❌ CloudKit 获取进度失败: $e');
      }
      return [];
    }
  }

  /// 保存模块进度
  static Future<bool> saveModuleProgress(ModuleProgress progress) async {
    try {
      await platform.invokeMethod('saveModuleProgress', {
        'moduleId': progress.moduleId,
        'progress': progress.accuracy, // 使用正确率作为进度指标
        'completedQuestions': progress.totalCorrectCount,
        'totalQuestions': progress.totalCorrectCount + progress.totalWrongCount,
      });
      if (kDebugMode) {
        print('✅ CloudKit 模块进度存储成功: ${progress.moduleId}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ CloudKit 模块进度存储失败: $e');
      }
      return false;
    }
  }

  /// 获取模块进度
  static Future<List<ModuleProgress>> fetchModuleProgress() async {
    try {
      final result = await platform.invokeMethod('fetchModuleProgress');
      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
        result,
      );

      return data
          .map(
            (item) => ModuleProgress(
              moduleId: item['moduleId'] ?? '',
              totalCorrectCount: item['completedQuestions'] ?? 0,
              totalWrongCount:
                  (item['totalQuestions'] ?? 0) -
                  (item['completedQuestions'] ?? 0),
            ),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ CloudKit 获取模块进度失败: $e');
      }
      return [];
    }
  }

  /// 保存错题记录
  static Future<bool> saveWrongQuestion(WrongQuestionRecord record) async {
    try {
      await platform.invokeMethod('saveWrongQuestion', {
        'questionText': '${record.questionType}:${record.input}',
        'correctAnswer': record.correctAnswer,
        'userAnswer': record.userAnswer,
        'moduleId': record.questionType,
      });
      if (kDebugMode) {
        print('✅ CloudKit 错题记录存储成功');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ CloudKit 错题记录存储失败: $e');
      }
      return false;
    }
  }

  /// 获取错题记录
  static Future<List<WrongQuestionRecord>> fetchWrongQuestions() async {
    try {
      final result = await platform.invokeMethod('fetchWrongQuestions');
      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
        result,
      );

      return data.map((item) {
        final questionText = item['questionText'] ?? '';
        final parts = questionText.split(':');
        final questionType = parts.isNotEmpty ? parts[0] : '';
        final input = parts.length > 1 ? parts[1] : '';

        return WrongQuestionRecord(
          questionType: questionType,
          input: input,
          correctAnswer: item['correctAnswer'] ?? '',
          userAnswer: item['userAnswer'] ?? '',
          wrongCount: item['reviewCount'] ?? 0,
          lastWrongTime: DateTime.fromMillisecondsSinceEpoch(
            ((item['timestamp'] ?? 0) * 1000).toInt(),
          ),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ CloudKit 获取错题记录失败: $e');
      }
      return [];
    }
  }

  /// 检查 CloudKit 是否可用
  static Future<bool> isCloudKitAvailable() async {
    try {
      // 尝试执行一个简单的查询来检查 CloudKit 是否可用
      await platform.invokeMethod('fetchProgress');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('CloudKit 不可用: $e');
      }
      return false;
    }
  }
}
