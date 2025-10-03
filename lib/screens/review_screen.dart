import 'package:flutter/material.dart';
import '../models/wrong_question_record.dart';
import '../models/question.dart';
import '../services/storage_service.dart';
import '../services/question_reconstructor.dart';
import '../widgets/flip_card.dart';

/// 错题复习页面
/// 设计思路：
/// 1. 从本地加载错题记录（只有参数）
/// 2. 通过 QuestionReconstructor 重建完整题目
/// 3. 用户答题后，答对多次可移除错题（可选）
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final PageController _pageController = PageController();
  List<WrongQuestionRecord> _wrongRecords = [];
  List<Question> _questions = [];
  int _currentPageIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWrongQuestions();
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

  /// 加载错题并重建题目
  Future<void> _loadWrongQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. 加载错题记录
      final records = await StorageService.loadWrongQuestions();

      if (records.isEmpty) {
        setState(() {
          _wrongRecords = [];
          _questions = [];
          _isLoading = false;
        });
        return;
      }

      // 2. 从错题记录重建题目
      final questions = <Question>[];
      for (final record in records) {
        try {
          final question = QuestionReconstructor.reconstructFromRecord(record);
          questions.add(question);
        } catch (e) {
          print('重建题目失败: ${record.uniqueId}, 错误: $e');
        }
      }

      setState(() {
        _wrongRecords = records;
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载错题失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 处理答对：可选择移除错题（答对多次后）
  Future<void> _handleCorrectAnswer(int index) async {
    // 这里可以实现更复杂的逻辑：
    // - 例如：答对3次才移除
    // - 或者：降低错题权重，但不删除
    // 目前简单实现：答对后不删除，保留历史记录

    // 先自动翻页
    if (index < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 最后一题，显示完成对话框
      _showCompletionDialog();
    }
  }

  /// 处理答错：增加错误次数
  Future<void> _handleWrongAnswer(int index, String userAnswer) async {
    try {
      final record = _wrongRecords[index];

      // 更新错题记录
      final updatedRecord = WrongQuestionRecord(
        questionType: record.questionType,
        input: record.input,
        correctAnswer: record.correctAnswer,
        userAnswer: userAnswer,
        wrongCount: record.wrongCount + 1,
        lastWrongTime: DateTime.now(),
      );

      await StorageService.recordWrongQuestion(updatedRecord);

      // 更新本地记录
      setState(() {
        _wrongRecords[index] = updatedRecord;
      });

      print('更新错题记录: ${record.uniqueId}, 错误次数: ${updatedRecord.wrongCount}');
    } catch (e) {
      print('更新错题失败: $e');
    }
  }

  /// 显示完成对话框
  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🎉 完成错题复习"),
        content: const Text("恭喜完成本轮错题复习！"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 只关闭对话框
              // 注意：ReviewScreen 是通过底部导航栏显示的，不是通过 push 打开的
              // 所以不需要再 pop 一次，用户可以通过底部导航栏切换到其他页面
            },
            child: const Text("知道了"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadWrongQuestions(); // 重新加载错题
            },
            child: const Text("再练一遍"),
          ),
        ],
      ),
    );
  }

  /// 显示清空错题确认对话框
  void _showClearConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("清空错题本"),
        content: const Text("确定要清空所有错题吗？此操作无法撤销。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.clearWrongQuestions();
              if (mounted) {
                Navigator.of(context).pop();
                _loadWrongQuestions();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("已清空错题本")));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("确定"),
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
            const Text(
              "错题复习",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (!_isLoading && _questions.isNotEmpty)
              Text(
                "共 ${_wrongRecords.length} 道错题",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          if (!_isLoading && _questions.isNotEmpty) ...[
            // 清空错题按钮
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showClearConfirmDialog,
              tooltip: "清空错题本",
            ),
            // 进度指示器
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                "${_currentPageIndex + 1}/${_questions.length}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWrongQuestions,
              child: const Text("重试"),
            ),
          ],
        ),
      );
    }

    if (_questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              "暂无错题",
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "答题过程中的错题会自动记录在这里",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          // 错题信息卡片
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "题型: ${_getQuestionTypeDisplay(_wrongRecords[_currentPageIndex].questionType)}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "错误 ${_wrongRecords[_currentPageIndex].wrongCount} 次",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 题目区域
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                return FlipCard(
                  question: _questions[index],
                  onCorrectAnswer: () => _handleCorrectAnswer(index),
                  onWrongAnswer: (userAnswer) =>
                      _handleWrongAnswer(index, userAnswer),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 获取题型显示名称
  String _getQuestionTypeDisplay(String questionType) {
    final typeMap = {
      'gan_wuxing': '天干五行',
      'zhi_wuxing': '地支五行',
      'gan_yinyang': '天干阴阳',
      'zhi_yinyang': '地支阴阳',
      'gan_direction': '天干方位',
      'zhi_direction': '地支方位',
      'zhi_liuhe': '六合',
      'zhi_liuchong': '六冲',
      'zhi_liuhai': '六害',
      'zhi_poxiang': '相破',
      'finger_forward': '地支指诀',
      'wuxing_sheng': '五行相生',
      'wuxing_ke': '五行相克',
    };
    return typeMap[questionType] ?? questionType;
  }
}
