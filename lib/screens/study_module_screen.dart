import 'package:flutter/material.dart';
import '../widgets/flip_card.dart';
import '../models/question.dart';
import '../services/question_factory.dart';

class StudyModuleScreen extends StatefulWidget {
  final String moduleType;

  const StudyModuleScreen({super.key, required this.moduleType});

  @override
  State<StudyModuleScreen> createState() => _StudyModuleScreenState();
}

class _StudyModuleScreenState extends State<StudyModuleScreen> {
  final PageController _pageController = PageController();
  late List<Question> questions;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
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

  void _loadQuestions() {
    // 根据 moduleType 生成不同的题目
    switch (widget.moduleType) {
      case 'tiangandizhi':
        questions = List.generate(
          5,
          (_) => QuestionFactory.generateTianGanDizhiQuestion(),
        );
        break;
      case 'wuxing':
        questions = List.generate(
          5,
          (_) => QuestionFactory.generateFingerJointQuestion(),
        );
        break;
      case 'hechong':
        questions = List.generate(
          5,
          (_) => QuestionFactory.generateXingChongHeChongQuestion(),
        );
        break;
      case 'comprehensive':
        questions = List.generate(
          5,
          (_) => QuestionFactory.generateGanWuXingQuestion(),
        );
        break;
      case 'shierchangsheng':
        questions = List.generate(
          5,
          (_) => QuestionFactory.generateChangShengQuestion(),
        );
        break;
      // 新的天干地支子模块
      case 'tiangandizhi_wuxing':
        questions = List.generate(
          5,
          (_) => QuestionFactory.generateTianGanDizhiQuestion(),
        );
        break;
      case 'tiangandizhi_comprehensive':
        questions = List.generate(
          5,
          (_) => QuestionFactory.generateTianGanDizhiQuestion(),
        );
        break;
      case 'tiangandizhi_yinyang':
        questions = List.generate(
          5,
          (_) => QuestionFactory.generateTianGanDizhiYinYangQuestion(),
        );
        break;
      case 'tiangandizhi_direction':
        questions = List.generate(
          5,
          (_) => QuestionFactory.generateDirectionQuestion(),
        );
        break;
      case 'tiangandizhi_time':
        questions = List.generate(
          5,
          (_) => QuestionFactory.generateTimeQuestion(),
        );
        break;
      case 'tiangandizhi_shengke':
        questions = List.generate(
          5,
          (_) => QuestionFactory.generateTianGanDizhiQuestion(),
        );
        break;
      default:
        questions = List.generate(
          5,
          (_) => QuestionFactory.generateGanWuXingQuestion(),
        );
    }
    setState(() {});
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getModuleTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
      body: questions.isEmpty
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
                    onCorrectAnswer: () {
                      // 自动翻到下一张卡片
                      if (index < questions.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 3000),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  );
                },
              ),
            ),
    );
  }
}
