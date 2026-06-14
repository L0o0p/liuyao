import 'dart:math';
import '../models/question.dart';
import '../models/module_progress.dart';
import 'storage_service.dart';
import 'questions.dart';
import '../data/tian_gan.dart';
import '../data/di_zhi.dart';
import '../data/gua_data.dart';

/// 题表管理器
/// 核心职责：
/// 1. 判断用户是首次学习还是复习模式
/// 2. 首次学习：生成全覆盖题表（确保每个知识点至少出现一次）
/// 3. 复习模式：根据熟练度和随机策略生成题目
/// 4. 管理学习进度的持久化
class RoundManager {
  static const int guaFirstRoundPartSize = 16;

  final String moduleId;
  late ModuleProgress _progress;
  List<Question> _currentRound = [];
  final _rnd = Random();

  RoundManager(this.moduleId);

  /// 初始化：加载进度并生成题目
  /// 必须在使用 RoundManager 前调用
  Future<void> initialize() async {
    _progress = await StorageService.loadProgress(moduleId);

    if (_progress.currentRoundQuestions.isNotEmpty) {
      _currentRound = _progress.currentRoundQuestions;
      if (_progress.currentQuestionIndex >= _currentRound.length) {
        await completeRound();
      }
    } else {
      await _generateQuestions();
      await _saveCurrentRound();
    }
  }

  /// 获取当前轮次的所有题目
  List<Question> get questions => _currentRound;

  /// 获取当前题目索引
  int get currentIndex => _progress.currentQuestionIndex;

  /// 是否完成首轮学习
  bool get isFirstRoundCompleted => _progress.firstRoundCompleted;

  /// 获取进度对象（用于展示统计信息）
  ModuleProgress get progress => _progress;

  /// 当前模块首轮是否需要按组学习
  bool get usesFirstRoundParts =>
      moduleId == '64gua' && !_progress.firstRoundCompleted;

  /// 当前分组题数
  int get partSize =>
      usesFirstRoundParts ? guaFirstRoundPartSize : questions.length;

  /// 当前首轮总分组数
  int get totalParts =>
      usesFirstRoundParts ? (_currentRound.length / partSize).ceil() : 1;

  /// 当前分组序号（从1开始）
  int get currentPartNumber {
    if (!usesFirstRoundParts || _currentRound.isEmpty) return 1;
    final index = _progress.currentQuestionIndex.clamp(
      0,
      _currentRound.length - 1,
    );
    return (index ~/ partSize) + 1;
  }

  /// 当前分组内题号（从1开始）
  int get currentPartQuestionNumber {
    if (!usesFirstRoundParts || _currentRound.isEmpty) {
      return _progress.currentQuestionIndex + 1;
    }
    return (_progress.currentQuestionIndex % partSize) + 1;
  }

  /// 当前分组内已答题数
  int get currentPartAnsweredCount {
    if (!usesFirstRoundParts) return _progress.currentQuestionIndex;
    return _progress.currentQuestionIndex % partSize;
  }

  /// 当前分组是否刚好完成
  bool get isAtPartBreak {
    if (!usesFirstRoundParts || _currentRound.isEmpty) return false;
    final index = _progress.currentQuestionIndex;
    return index > 0 && index < _currentRound.length && index % partSize == 0;
  }

  /// 是否已经答完整个当前轮次
  bool get isCurrentRoundAnswered =>
      _currentRound.isNotEmpty &&
      _progress.currentQuestionIndex >= _currentRound.length;

  /// 当前分组答对数
  int get currentPartCorrectCount => _progress.currentPartCorrectCount;

  /// 当前分组答错数
  int get currentPartWrongCount => _progress.currentPartWrongCount;

  /// 生成题目列表
  /// 根据是否首次学习，采用不同策略
  Future<void> _generateQuestions() async {
    if (!_progress.firstRoundCompleted) {
      // 首次学习：生成全覆盖题表
      _currentRound = _generateFullCoverageRound();
    } else {
      // 复习模式：根据熟练度生成题目
      _currentRound = _generateReviewRound();
    }
  }

  /// 生成全覆盖题表（首次学习）
  /// 确保模块中的每个知识点至少出现一次
  List<Question> _generateFullCoverageRound() {
    final List<Question> questions = [];

    switch (moduleId) {
      // ========== 天干相关模块 ==========
      case 'tiangandizhi_wuxing':
        // 天干五行：10个天干各出一题
        final gans = tianGan.map((g) => g["name"]!).toList();
        gans.shuffle(_rnd);
        for (final gan in gans) {
          questions.add(_createGanWuXingQuestion(gan));
        }
        // 地支五行：12个地支各出一题
        final zhis = diZhi.map((z) => z["name"]!).toList();
        zhis.shuffle(_rnd);
        for (final zhi in zhis) {
          questions.add(_createZhiWuXingQuestion(zhi));
        }
        break;

      case 'tiangandizhi_yinyang':
        // 天干阴阳：10个天干各出一题
        final gans = tianGan.map((g) => g["name"]!).toList();
        gans.shuffle(_rnd);
        for (final gan in gans) {
          questions.add(_createGanYinYangQuestion(gan));
        }
        // 地支阴阳：12个地支各出一题
        final zhis = diZhi.map((z) => z["name"]!).toList();
        zhis.shuffle(_rnd);
        for (final zhi in zhis) {
          questions.add(_createZhiYinYangQuestion(zhi));
        }
        break;

      case 'tiangandizhi_direction':
        // 方位：天干10题 + 地支12题
        final gans = tianGan.map((g) => g["name"]!).toList();
        gans.shuffle(_rnd);
        for (final gan in gans) {
          questions.add(_createGanDirectionQuestion(gan));
        }
        final zhis = diZhi.map((z) => z["name"]!).toList();
        zhis.shuffle(_rnd);
        for (final zhi in zhis) {
          questions.add(_createZhiDirectionQuestion(zhi));
        }
        break;

      case 'tiangandizhi_time':
        // 时间：地支12题（时辰）
        final zhis = diZhi.map((z) => z["name"]!).toList();
        zhis.shuffle(_rnd);
        for (final zhi in zhis) {
          questions.add(_createZhiTimeQuestion(zhi));
        }
        break;

      case 'hechong':
        // 刑冲合害：各类型各5题
        for (int i = 0; i < 5; i++) {
          questions.add(Questions.generateLiuHeQuestion());
        }
        for (int i = 0; i < 5; i++) {
          questions.add(Questions.generateSanHeQuestion());
        }
        for (int i = 0; i < 5; i++) {
          questions.add(Questions.generateSanXingQuestion());
        }
        for (int i = 0; i < 5; i++) {
          questions.add(Questions.generateZiXingQuestion());
        }
        questions.shuffle(_rnd);
        break;

      case 'wuxing':
        // 地支指诀：12个地支各出一题
        final zhis = diZhi.map((z) => z["name"]!).toList();
        zhis.shuffle(_rnd);
        for (final zhi in zhis) {
          questions.add(_createFingerJointQuestion(zhi));
        }
        break;

      case 'shierchangsheng':
        // 十二长生：生成20题全覆盖
        questions.addAll(
          List.generate(20, (_) => Questions.generateChangShengQuestion()),
        );
        break;

      case '64gua':
        // 六十四卦：每个卦各出一题，共64题，题型交错分布
        final guaNames = getAllGuaNames()..shuffle(_rnd);
        for (int i = 0; i < guaNames.length; i++) {
          final guaName = guaNames[i];
          questions.add(
            i.isEven
                ? Questions.generateGuaToXiangQuestionFor(guaName)
                : Questions.generateXiangToGuaQuestionFor(guaName),
          );
        }
        break;

      default:
        // 其他模块：生成10题
        questions.addAll(
          List.generate(10, (_) => Questions.generateGanWuXingQuestion()),
        );
    }

    return questions;
  }

  /// 生成复习模式题表
  /// 根据熟练度决定题目分布：
  /// - 60%的题目来自薄弱知识点（熟练度<60）
  /// - 40%的题目随机生成（保持多样性）
  List<Question> _generateReviewRound() {
    final List<Question> questions = [];
    final weakItems = _progress.getWeakItems();

    final int totalQuestions = 20; // 复习模式默认20题
    final int weakCount = (totalQuestions * 0.6).round();
    final int randomCount = totalQuestions - weakCount;

    // 生成薄弱知识点题目
    for (int i = 0; i < weakCount && weakItems.isNotEmpty; i++) {
      final item = weakItems[_rnd.nextInt(weakItems.length)];
      questions.add(_createQuestionForItem(item));
    }

    // 生成随机题目
    for (int i = 0; i < randomCount; i++) {
      questions.add(_generateRandomQuestionForModule());
    }

    // 打乱顺序
    questions.shuffle(_rnd);
    return questions;
  }

  /// 为特定知识点生成题目
  Question _createQuestionForItem(String item) {
    // 根据知识点ID生成对应题目
    // 判断是天干还是地支
    final isGan = tianGan.any((g) => g["name"] == item);

    if (isGan) {
      // 随机选择天干相关题型
      final types = [
        () => _createGanWuXingQuestion(item),
        () => _createGanYinYangQuestion(item),
        () => _createGanDirectionQuestion(item),
      ];
      return types[_rnd.nextInt(types.length)]();
    } else {
      // 随机选择地支相关题型
      final types = [
        () => _createZhiWuXingQuestion(item),
        () => _createZhiYinYangQuestion(item),
        () => _createZhiDirectionQuestion(item),
        () => _createZhiTimeQuestion(item),
      ];
      return types[_rnd.nextInt(types.length)]();
    }
  }

  /// 为当前模块生成随机题目
  Question _generateRandomQuestionForModule() {
    switch (moduleId) {
      case 'tiangandizhi_wuxing':
        return _rnd.nextBool()
            ? Questions.generateGanWuXingQuestion()
            : Questions.generateZhiWuXingQuestion();
      case 'tiangandizhi_yinyang':
        return _rnd.nextBool()
            ? Questions.generateGanYinYangQuestion()
            : Questions.generateZhiYinYangQuestion();
      case 'tiangandizhi_direction':
        return _rnd.nextBool()
            ? Questions.generateGanDirectionQuestion()
            : Questions.generateZhiDirectionQuestion();
      case 'tiangandizhi_time':
        return Questions.generateZhiTimeQuestion();
      case 'hechong':
        final generators = [
          Questions.generateLiuHeQuestion,
          Questions.generateSanHeQuestion,
          Questions.generateSanXingQuestion,
          Questions.generateZiXingQuestion,
        ];
        return generators[_rnd.nextInt(generators.length)]();
      case 'wuxing':
        return Questions.generateFingerJointForwardQuestion();
      case 'shierchangsheng':
        return Questions.generateChangShengQuestion();
      case '64gua':
        return Questions.generate64GuaQuestion();
      default:
        return Questions.generateGanWuXingQuestion();
    }
  }

  // ========== 针对特定知识点的题目生成器 ==========

  Question _createGanWuXingQuestion(String gan) {
    // 复用 Questions 类的逻辑，但指定特定天干
    return Questions.generateGanWuXingQuestion(); // TODO: 需要修改 Questions 支持指定参数
  }

  Question _createZhiWuXingQuestion(String zhi) {
    return Questions.generateZhiWuXingQuestion();
  }

  Question _createGanYinYangQuestion(String gan) {
    return Questions.generateGanYinYangQuestion();
  }

  Question _createZhiYinYangQuestion(String zhi) {
    return Questions.generateZhiYinYangQuestion();
  }

  Question _createGanDirectionQuestion(String gan) {
    return Questions.generateGanDirectionQuestion();
  }

  Question _createZhiDirectionQuestion(String zhi) {
    return Questions.generateZhiDirectionQuestion();
  }

  Question _createZhiTimeQuestion(String zhi) {
    return Questions.generateZhiTimeQuestion();
  }

  Question _createFingerJointQuestion(String zhi) {
    return Questions.generateFingerJointForwardQuestion();
  }

  /// 提交答案并更新进度
  /// @param questionIndex 题目索引
  /// @param isCorrect 是否答对
  Future<void> submitAnswer(int questionIndex, bool isCorrect) async {
    if (questionIndex < _progress.currentQuestionIndex) {
      return;
    }

    // 更新统计
    if (isCorrect) {
      _progress.totalCorrectCount++;
      _progress.currentPartCorrectCount++;
    } else {
      _progress.totalWrongCount++;
      _progress.currentPartWrongCount++;
    }

    _progress.currentQuestionIndex = (questionIndex + 1).clamp(
      0,
      _currentRound.length,
    );

    // 提取知识点ID并更新熟练度
    // TODO: 需要从题目中提取知识点ID，这里暂时跳过
    // final itemId = _extractItemIdFromQuestion(_currentRound[questionIndex]);
    // _progress.updateProficiency(itemId, isCorrect);

    // 保存进度
    await StorageService.saveProgress(_progress);
  }

  /// 从分组休息点继续下一组
  Future<void> continueAfterPartBreak() async {
    _progress.resetCurrentPartStats();
    await StorageService.saveProgress(_progress);
  }

  /// 完成当前轮次
  /// 如果是首轮，标记为已完成；否则开始新一轮
  Future<void> completeRound() async {
    if (!_progress.firstRoundCompleted) {
      _progress.firstRoundCompleted = true;
    }

    _progress.resetRound();
    await StorageService.saveProgress(_progress);

    // 生成下一轮题目
    await _generateQuestions();
    await _saveCurrentRound();
  }

  /// 获取下一题
  /// @return 下一题的Question对象，如果没有更多题目则返回null
  Question? getNextQuestion() {
    if (_progress.currentQuestionIndex >= _currentRound.length) {
      return null; // 本轮已完成
    }

    final question = _currentRound[_progress.currentQuestionIndex];
    _progress.currentQuestionIndex++;
    return question;
  }

  /// 重置模块进度（重新开始）
  Future<void> reset() async {
    await StorageService.clearProgress(moduleId);
    _progress = ModuleProgress(moduleId: moduleId);
    await _generateQuestions();
    await _saveCurrentRound();
  }

  Future<void> _saveCurrentRound() async {
    _progress.currentRoundQuestions = List<Question>.from(_currentRound);
    await StorageService.saveProgress(_progress);
  }
}
