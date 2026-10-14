import 'dart:async';
import 'dart:math';
import '../models/question.dart';
import '../models/module_progress.dart';
import 'storage_service.dart';
import 'sync/sync_engine.dart';
import '../data/gua_data.dart';
import '../data/knowledge_catalog.dart';
import '../data/zhi_relations.dart';

/// 题表管理器
/// 核心职责：
/// 1. 判断用户是首次学习还是复习模式
/// 2. 首次学习：生成全覆盖题表（确保每个知识点至少出现一次）
/// 3. 复习模式：根据熟练度和随机策略生成题目
/// 4. 管理学习进度的持久化
class RoundManager {
  /// 综合类模块每轮题数
  static const int comprehensiveRoundSize = 20;

  /// 综合练习的出题来源模块
  static List<String> get comprehensiveSourceModules =>
      KnowledgeCatalog.module('comprehensive')!.sourceModuleIds;

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
      KnowledgeCatalog.module(moduleId)?.partSize != null &&
      !_progress.firstRoundCompleted;

  /// 当前分组题数
  int get partSize => usesFirstRoundParts
      ? KnowledgeCatalog.module(moduleId)!.partSize!
      : questions.length;

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

  /// 生成全覆盖题表（首次学习）。
  /// 普通模块每个知识点一题；六十四卦、十二长生、综合练习走各自的覆盖规则。
  List<Question> _generateFullCoverageRound() {
    final module = KnowledgeCatalog.module(moduleId);
    if (module == null) {
      return List.generate(
        10,
        (_) => KnowledgeCatalog.randomQuestionOfType('gan_wuxing', _rnd),
      );
    }

    switch (module.firstRound) {
      case FirstRoundKind.eachItem:
        final pool = KnowledgeCatalog.itemsForTypes(module.questionTypes)
          ..shuffle(_rnd);
        return [
          for (final item in pool)
            KnowledgeCatalog.generateQuestion(
              item.questionType,
              item.input,
              random: _rnd,
            ),
        ];
      case FirstRoundKind.guaAlternating:
        return _generateGuaRound();
      case FirstRoundKind.changshengCoverage:
        final questions = _generateChangShengCoverage()..shuffle(_rnd);
        return questions;
      case FirstRoundKind.mixed:
        return _generateMixedRound(comprehensiveRoundSize);
    }
  }

  /// 六十四卦首轮：每个卦一题，卦名→卦象与卦象→卦名交错。
  List<Question> _generateGuaRound() {
    final guaNames = getAllGuaNames()..shuffle(_rnd);
    final questions = <Question>[];
    for (var i = 0; i < guaNames.length; i++) {
      final guaName = guaNames[i];
      if (i.isEven) {
        questions.add(
          KnowledgeCatalog.generateQuestion(
            'gua_to_xiang',
            guaName,
            random: _rnd,
          ),
        );
      } else {
        final xiang = getGuaXiang(guaName)!;
        questions.add(
          KnowledgeCatalog.generateQuestion(
            'xiang_to_gua',
            xiang,
            random: _rnd,
          ),
        );
      }
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

    // 生成薄弱知识点题目
    for (int i = 0; i < weakCount && weakItems.isNotEmpty; i++) {
      final item = weakItems[_rnd.nextInt(weakItems.length)];
      questions.add(_createQuestionForItem(item));
    }

    // 生成随机题目，没有薄弱知识点时也补足题量
    while (questions.length < totalQuestions) {
      questions.add(_generateRandomQuestionForModule());
    }

    // 打乱顺序
    questions.shuffle(_rnd);
    return questions;
  }

  /// 为特定知识点生成题目。
  /// itemKey 格式为 questionType:input，例如 gan_wuxing:甲。
  Question _createQuestionForItem(String itemKey) {
    final separator = itemKey.indexOf(':');
    if (separator <= 0 || separator >= itemKey.length - 1) {
      return _generateRandomQuestionForModule();
    }
    final type = itemKey.substring(0, separator);
    final input = itemKey.substring(separator + 1);
    if (KnowledgeCatalog.find(type, input) == null) {
      return _generateRandomQuestionForModule();
    }
    return KnowledgeCatalog.generateQuestion(type, input, random: _rnd);
  }

  /// 为当前模块生成随机题目
  Question _generateRandomQuestionForModule() {
    return KnowledgeCatalog.randomQuestionForModule(moduleId, _rnd);
  }

  /// 生成混合随机题表，同一轮内按知识点去重
  List<Question> _generateMixedRound(int count) {
    final questions = <Question>[];
    final seen = <String>{};
    var attempts = 0;
    while (questions.length < count && attempts < count * 20) {
      attempts++;
      final question = _generateRandomQuestionForModule();
      if (seen.add(question.itemKey)) {
        questions.add(question);
      }
    }
    return questions;
  }

  /// 十二长生覆盖题表
  /// 每一遍把12个日支与12个阶段一一配对，两遍的配对互不重复
  List<Question> _generateChangShengCoverage() {
    final riZhis = List<String>.from(diZhiCycle)..shuffle(_rnd);
    final stages = List<int>.generate(changShengCycle.length, (i) => i)
      ..shuffle(_rnd);
    final questions = <Question>[];
    for (final pass in [0, 6]) {
      for (int i = 0; i < riZhis.length; i++) {
        final riZhi = riZhis[i];
        final stage = (stages[i] + pass) % changShengCycle.length;
        final startZhi = wuXingChangShengStart[zhiWuXing[riZhi]]!;
        final yaoZhi =
            diZhiCycle[(diZhiCycle.indexOf(startZhi) + stage) %
                diZhiCycle.length];
        questions.add(
          KnowledgeCatalog.generateQuestion(
            'changsheng',
            '${riZhi}_$yaoZhi',
            random: _rnd,
          ),
        );
      }
    }
    return questions;
  }

  /// 提交答案并更新进度
  /// @param questionIndex 题目索引
  /// @param isCorrect 是否答对
  /// 只接受当前题的提交，避免跳题
  Future<void> submitAnswer(int questionIndex, bool isCorrect) async {
    if (questionIndex != _progress.currentQuestionIndex) {
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

    // 用题目上的知识点键更新熟练度，并记入已学列表
    if (questionIndex >= 0 && questionIndex < _currentRound.length) {
      final question = _currentRound[questionIndex];
      if (question.questionType.isNotEmpty && question.input.isNotEmpty) {
        _progress.updateProficiency(question.itemKey, isCorrect);
        _progress.markItemAsLearned(question.itemKey);
      }
    }

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

    // 答完一轮后尝试同步。失败不能挡住界面。
    unawaited(SyncEngine.instance.sync());
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
