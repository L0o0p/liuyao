import 'package:flutter/material.dart';
import '../widgets/flip_card.dart';
import '../models/question.dart';
import '../models/wrong_question_record.dart';
import '../data/knowledge_catalog.dart';
import '../services/round_manager.dart';
import '../services/storage_service.dart';
import '../services/question_reconstructor.dart';

class StudyModuleScreen extends StatefulWidget {
  final String moduleType;

  const StudyModuleScreen({super.key, required this.moduleType});

  @override
  State<StudyModuleScreen> createState() => _StudyModuleScreenState();
}

class _StudyModuleScreenState extends State<StudyModuleScreen> {
  final PageController _pageController = PageController();
  late RoundManager _roundManager;
  List<Question> questions = [];
  int _currentPageIndex = 0;
  bool _isLoading = true;

  /// 答错后尚未完成的提交，点「下一题」前需要等它落盘
  Future<void>? _pendingSubmission;

  @override
  void initState() {
    super.initState();
    _initializeRoundManager();
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    if (_pageController.page != null) {
      setState(() {
        _currentPageIndex = _pageController.page!.round();
      });
    }
  }

  /// 初始化题表管理器
  /// 加载用户进度并生成题目
  Future<void> _initializeRoundManager() async {
    setState(() {
      _isLoading = true;
    });

    _roundManager = RoundManager(widget.moduleType);
    await _roundManager.initialize();

    final initialIndex = _roundManager.currentIndex.clamp(
      0,
      _roundManager.questions.isEmpty ? 0 : _roundManager.questions.length - 1,
    );

    setState(() {
      questions = _roundManager.questions;
      _currentPageIndex = initialIndex;
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients || questions.isEmpty) return;
      _pageController.jumpToPage(initialIndex);
    });
  }

  String _getModuleTitle() {
    return KnowledgeCatalog.module(widget.moduleType)?.name ?? '学习';
  }

  /// 获取学习模式提示文字
  String _getModeHint() {
    if (_isLoading) return "";
    if (_roundManager.usesFirstRoundParts) {
      return "首轮学习 · 第 ${_roundManager.currentPartNumber}/${_roundManager.totalParts} 组";
    }
    return _roundManager.isFirstRoundCompleted ? "复习模式" : "首轮学习";
  }

  /// 记录错题
  /// 题目自带题型和输入时直接使用；旧题表没有这两个字段时，再从题干反推。
  Future<void> _recordWrongQuestion(
    Question question,
    String userAnswer,
  ) async {
    try {
      var questionType = question.questionType;
      var input = question.input;
      if (questionType.isEmpty || input.isEmpty) {
        final info = QuestionReconstructor.inferQuestionTypeAndInput(question);
        if (info == null) {
          print('⚠ 无法识别题目类型，未记录错题: ${question.text}');
          return;
        }
        questionType = info['questionType']!;
        input = info['input']!;
      }

      final record = WrongQuestionRecord(
        questionType: questionType,
        input: input,
        correctAnswer: question.correctAnswer,
        userAnswer: userAnswer,
      );

      await StorageService.recordWrongQuestion(record);
      print('✓ 已记录错题: ${record.questionType} - ${record.input}');
    } catch (e) {
      print('✗ 记录错题失败: $e');
    }
  }

  /// 处理完成本轮学习
  Future<void> _onRoundComplete() async {
    final wasFirstRound = !_roundManager.isFirstRoundCompleted;
    await _roundManager.completeRound();

    if (!mounted) return;

    // 显示完成提示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("🎉 完成本轮学习"),
        content: Text(
          wasFirstRound
              ? "恭喜完成首轮学习！\n已解锁复习模式"
              : "恭喜完成本轮复习！\n正确率：${(_roundManager.progress.accuracy * 100).toStringAsFixed(1)}%",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // 返回上一页
            },
            child: const Text("返回"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeRoundManager(); // 开始新一轮
            },
            child: const Text("继续练习"),
          ),
        ],
      ),
    );
  }

  Future<void> _onAnswerSubmitted(
    int index,
    Question question,
    bool isCorrect, {
    String? userAnswer,
  }) async {
    if (index != _roundManager.currentIndex) return;
    await _roundManager.submitAnswer(index, isCorrect);

    if (!isCorrect && userAnswer != null) {
      await _recordWrongQuestion(question, userAnswer);
    }

    if (!mounted) return;
    setState(() {});

    // 答错时等用户点「下一题」再推进
    if (isCorrect) {
      await _advance();
    }
  }

  /// 推进到下一题：本轮完成、分组休息或翻页
  Future<void> _advance() async {
    await _pendingSubmission;
    if (!mounted) return;

    if (_roundManager.isCurrentRoundAnswered) {
      await _onRoundComplete();
      return;
    }

    if (_roundManager.isAtPartBreak) {
      await _showPartCompleteDialog();
      return;
    }

    if (_pageController.hasClients &&
        _currentPageIndex < _roundManager.currentIndex) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _showPartCompleteDialog() async {
    final completedPart = _roundManager.currentIndex ~/ _roundManager.partSize;
    final correctCount = _roundManager.currentPartCorrectCount;
    final wrongCount = _roundManager.currentPartWrongCount;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("完成第 $completedPart/${_roundManager.totalParts} 组"),
        content: Text(
          "本组 ${_roundManager.partSize} 题\n"
          "答对 $correctCount 题\n"
          "答错 $wrongCount 题",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _roundManager.continueAfterPartBreak();
              if (!context.mounted) return;
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text("暂时退出"),
          ),
          FilledButton(
            onPressed: () async {
              await _roundManager.continueAfterPartBreak();
              if (!context.mounted) return;
              Navigator.of(context).pop();
              if (_pageController.hasClients) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                );
              }
              if (mounted) {
                setState(() {});
              }
            },
            child: const Text("继续下一组"),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    if (!_roundManager.usesFirstRoundParts) {
      return const SizedBox.shrink();
    }

    final total = questions.length;
    final answered = _roundManager.currentIndex.clamp(0, total);
    final partAnswered = _roundManager.currentPartAnsweredCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "本组 $partAnswered/${_roundManager.partSize}",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                "总进度 $answered/$total",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : answered / total,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _getModuleTitle(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (!_isLoading)
              Text(
                _getModeHint(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              "${questions.isEmpty ? 0 : _currentPageIndex + 1}/${questions.length}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  _buildProgressHeader(),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      // 单向推进，只能答完后由程序翻到下一题
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final q = questions[index];
                        return FlipCard(
                          question: q,
                          onCorrectAnswer: () async {
                            await _onAnswerSubmitted(index, q, true);
                          },
                          onWrongAnswer: (userAnswer) {
                            _pendingSubmission = _onAnswerSubmitted(
                              index,
                              q,
                              false,
                              userAnswer: userAnswer,
                            );
                          },
                          onNext: _advance,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
