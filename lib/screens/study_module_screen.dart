import 'package:flutter/material.dart';
import '../widgets/flip_card.dart';
import '../models/question.dart';
import '../services/round_manager.dart';

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

    setState(() {
      questions = _roundManager.questions;
      _isLoading = false;
    });
  }

  String _getModuleTitle() {
    switch (widget.moduleType) {
      case 'tiangandizhi':
        return "天干地支基础";
      case 'wuxing':
        return "十二支指诀";
      case 'hechong':
        return "六合三合六冲";
      case 'comprehensive':
        return "综合练习";
      case 'shierchangsheng':
        return "十二长生";
      case 'directiontime':
        return "方位时间";
      // 新的天干地支子模块标题
      case 'tiangandizhi_wuxing':
        return "天干地支五行";
      case 'tiangandizhi_yinyang':
        return "天干地支阴阳";
      case 'tiangandizhi_direction':
        return "方位对应";
      case 'tiangandizhi_time':
        return "时间对应";
      case 'tiangandizhi_shengke':
        return "五行生克";
      default:
        return "学习";
    }
  }

  /// 获取学习模式提示文字
  String _getModeHint() {
    if (_isLoading) return "";
    return _roundManager.isFirstRoundCompleted ? "复习模式" : "首轮学习";
  }

  /// 处理完成本轮学习
  Future<void> _onRoundComplete() async {
    await _roundManager.completeRound();

    if (!mounted) return;

    // 显示完成提示
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🎉 完成本轮学习"),
        content: Text(
          _roundManager.isFirstRoundCompleted
              ? "恭喜完成本轮复习！\n正确率：${(_roundManager.progress.accuracy * 100).toStringAsFixed(1)}%"
              : "恭喜完成首轮学习！\n已解锁复习模式",
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
                  color: Colors.white.withOpacity(0.8),
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
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
              // 添加SafeArea确保内容不被状态栏遮挡
              child: PageView.builder(
                controller: _pageController,
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final q = questions[index];
                  return FlipCard(
                    question: q,
                    onCorrectAnswer: () async {
                      // 记录答题结果
                      await _roundManager.submitAnswer(index, true);

                      // 自动翻到下一张卡片
                      if (index < questions.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        // 完成本轮
                        await _onRoundComplete();
                      }
                    },
                  );
                },
              ),
            ),
    );
  }
}
