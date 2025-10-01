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

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _loadQuestions() {
    // 根据 moduleType 生成不同的题目
    switch (widget.moduleType) {
      case 'tianganzhizhi':
        questions = List.generate(
          5,
          (_) => QuestionFactory.generateGanWuXingQuestion(),
        );
        break;
      case 'wuxing':
        questions = List.generate(
          5,
          (_) => QuestionFactory.generateGanWuXingQuestion(),
        );
        break;
      case 'hechong':
        questions = List.generate(
          5,
          (_) => QuestionFactory.generateGanWuXingQuestion(),
        );
        break;
      case 'comprehensive':
        questions = List.generate(
          5,
          (_) => QuestionFactory.generateGanWuXingQuestion(),
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
      case 'tianganzhizhi':
        return "天干地支基础";
      case 'wuxing':
        return "五行相生相克";
      case 'hechong':
        return "六合三合六冲";
      case 'comprehensive':
        return "综合练习";
      default:
        return "学习";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getModuleTitle()),
        actions: [
          TextButton(
            onPressed: () {
              // 显示进度信息
            },
            child: Text("${questions.isEmpty ? 0 : 1}/${questions.length}"),
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
                          duration: const Duration(milliseconds: 300),
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
