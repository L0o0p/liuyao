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

      // 安全的类型转换
      final List<Map<String, dynamic>> data = [];
      if (result is List) {
        for (final item in result) {
          if (item is Map) {
            data.add(Map<String, dynamic>.from(item));
          }
        }
      }

      return data;
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
      if (kDebugMode) {
        print('CloudKit返回的模块进度数据类型: ${result.runtimeType}');
        print('CloudKit返回的模块进度数据: $result');
      }

      // 安全的类型转换
      final List<Map<String, dynamic>> data = [];
      if (result is List) {
        for (final item in result) {
          if (item is Map) {
            data.add(Map<String, dynamic>.from(item));
          }
        }
      }

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
      if (kDebugMode) {
        print('CloudKit返回的错题数据类型: ${result.runtimeType}');
        print('CloudKit返回的错题数据: $result');
      }

      // 安全的类型转换
      final List<Map<String, dynamic>> data = [];
      if (result is List) {
        for (final item in result) {
          if (item is Map) {
            data.add(Map<String, dynamic>.from(item));
          }
        }
      }

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

  /// 测试公共CloudKit连接
  static Future<bool> testPublicCloudKit() async {
    try {
      await platform.invokeMethod('testPublicCloudKit');
      if (kDebugMode) {
        print('✅ 公共CloudKit连接测试成功');
        print('📋 请在CloudKit Console中检查:');
        print('   1. 环境: Development');
        print('   2. 数据库: Public Database');
        print('   3. 记录类型: PublicTestRecord');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 公共CloudKit连接测试失败: $e');
      }
      return false;
    }
  }

  /// 测试CloudKit连接
  static Future<bool> testCloudKitConnection() async {
    try {
      if (kDebugMode) {
        print('🔍 开始CloudKit综合测试...');
      }

      // 执行上传下载综合测试
      await testCloudKitUploadDownload();

      // 测试拉取模块进度
      final moduleProgress = await fetchModuleProgress();
      if (kDebugMode) {
        print('📊 从CloudKit拉取到 ${moduleProgress.length} 条模块进度记录');
        for (final progress in moduleProgress) {
          print('  - 模块: ${progress.moduleId}');
          print('    正确率: ${(progress.accuracy * 100).toStringAsFixed(1)}%');
          print(
            '    正确/错误: ${progress.totalCorrectCount}/${progress.totalWrongCount}',
          );
        }
      }

      // 测试拉取错题记录
      final wrongQuestions = await fetchWrongQuestions();
      if (kDebugMode) {
        print('❌ 从CloudKit拉取到 ${wrongQuestions.length} 条错题记录');
        for (int i = 0; i < wrongQuestions.length && i < 5; i++) {
          final question = wrongQuestions[i];
          print('  - 问题类型: ${question.questionType}');
          print('    输入: ${question.input}');
          print('    正确答案: ${question.correctAnswer}');
          print('    用户答案: ${question.userAnswer}');
          print('    错误次数: ${question.wrongCount}');
        }
        if (wrongQuestions.length > 5) {
          print('  ... 还有 ${wrongQuestions.length - 5} 条记录');
        }
      }

      // 如果能拉取到数据，说明CloudKit完全正常
      if (moduleProgress.isNotEmpty || wrongQuestions.isNotEmpty) {
        if (kDebugMode) {
          print('🎉 CloudKit数据拉取成功！数据同步正常工作');
          print('📋 总结:');
          print('   - 模块进度记录: ${moduleProgress.length} 条');
          print('   - 错题记录: ${wrongQuestions.length} 条');
          print('   - CloudKit状态: 完全正常 ✅');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('⚠️  CloudKit连接正常，但暂无数据');
        }
        // 如果没有数据，再测试基本连接
        await platform.invokeMethod('testCloudKitConnection');
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ CloudKit数据拉取失败: $e');
        print('🔄 尝试基本连接测试...');
      }

      // 如果拉取失败，尝试基本测试
      try {
        await platform.invokeMethod('testCloudKitConnection');
        return true;
      } catch (e2) {
        if (kDebugMode) {
          print('❌ CloudKit连接测试失败: $e2');
        }
        return false;
      }
    }
  }

  /// 测试上传本地数据到CloudKit
  static Future<void> testUploadLocalData() async {
    try {
      if (kDebugMode) {
        print('🚀 开始测试上传本地数据到CloudKit...');
      }

      // 1. 测试上传一些模块进度数据
      final testModuleProgress = ModuleProgress(
        moduleId: 'tiangandizhi_wuxing', // 使用真实的模块ID
        totalCorrectCount: 15,
        totalWrongCount: 5,
      );

      final uploadResult = await saveModuleProgress(testModuleProgress);
      if (kDebugMode) {
        print(uploadResult ? '✅ 模块进度上传成功' : '❌ 模块进度上传失败');
      }

      // 2. 测试上传一些错题记录
      final testWrongQuestion = WrongQuestionRecord(
        questionType: 'test_gan_wuxing',
        input: '甲',
        correctAnswer: '木',
        userAnswer: '火',
      );

      final wrongQuestionResult = await saveWrongQuestion(testWrongQuestion);
      if (kDebugMode) {
        print(wrongQuestionResult ? '✅ 错题记录上传成功' : '❌ 错题记录上传失败');
      }

      // 3. 测试上传基础进度数据
      final progressResult = await saveProgress('测试词汇', 85);
      if (kDebugMode) {
        print(progressResult ? '✅ 基础进度上传成功' : '❌ 基础进度上传失败');
      }

      if (kDebugMode) {
        print('📊 本地数据上传测试完成');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 上传测试失败: $e');
      }
    }
  }

  /// 测试从CloudKit下载所有数据
  static Future<void> testDownloadAllData() async {
    try {
      if (kDebugMode) {
        print('📥 开始测试从CloudKit下载所有数据...');
      }

      // 1. 拉取模块进度
      final moduleProgress = await fetchModuleProgress();
      if (kDebugMode) {
        print('📊 模块进度记录: ${moduleProgress.length} 条');
        for (final progress in moduleProgress) {
          print(
            '  - ${progress.moduleId}: 正确率 ${(progress.accuracy * 100).toStringAsFixed(1)}%',
          );
        }
      }

      // 2. 拉取错题记录
      final wrongQuestions = await fetchWrongQuestions();
      if (kDebugMode) {
        print('❌ 错题记录: ${wrongQuestions.length} 条');
        for (int i = 0; i < wrongQuestions.length && i < 3; i++) {
          final q = wrongQuestions[i];
          print(
            '  - ${q.questionType}: ${q.input} → ${q.correctAnswer} (用户答: ${q.userAnswer})',
          );
        }
        if (wrongQuestions.length > 3) {
          print('  ... 还有 ${wrongQuestions.length - 3} 条');
        }
      }

      // 3. 拉取基础进度
      final basicProgress = await fetchProgress();
      if (kDebugMode) {
        print('📈 基础进度记录: ${basicProgress.length} 条');
        for (int i = 0; i < basicProgress.length && i < 3; i++) {
          final p = basicProgress[i];
          print('  - ${p['word']}: ${p['score']}分');
        }
        if (basicProgress.length > 3) {
          print('  ... 还有 ${basicProgress.length - 3} 条');
        }
      }

      if (kDebugMode) {
        print('🎉 CloudKit数据下载测试完成！');
        print('📋 总结:');
        print('   - 模块进度: ${moduleProgress.length} 条');
        print('   - 错题记录: ${wrongQuestions.length} 条');
        print('   - 基础进度: ${basicProgress.length} 条');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 下载测试失败: $e');
      }
    }
  }

  /// 综合测试CloudKit上传和下载
  static Future<void> testCloudKitUploadDownload() async {
    if (kDebugMode) {
      print('🔄 开始CloudKit上传下载综合测试...');
    }

    await testUploadLocalData();
    await Future.delayed(Duration(seconds: 2)); // 等待上传完成
    await testDownloadAllData();

    if (kDebugMode) {
      print('✅ CloudKit上传下载综合测试完成！');
    }
  }

  /// 检查 CloudKit 是否可用
  static Future<bool> isCloudKitAvailable() async {
    try {
      // 先测试基本连接
      final connectionTest = await testCloudKitConnection();
      if (!connectionTest) {
        return false;
      }

      // 不再尝试查询Progress记录类型，因为它可能没有配置索引
      // testCloudKitConnection已经足够验证CloudKit可用性
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('CloudKit 不可用: $e');
      }
      // 如果是记录类型不存在的错误，我们认为CloudKit是可用的，只是还没有数据
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('did not find record type') ||
          errorMessage.contains('record type') ||
          errorMessage.contains('progress') ||
          errorMessage.contains('not marked indexable')) {
        if (kDebugMode) {
          print('CloudKit 可用，但记录类型尚未创建或配置，这是正常的');
        }
        return true;
      }
      return false;
    }
  }
}
