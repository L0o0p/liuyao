import 'package:flutter/material.dart';
import '../widgets/flip_card.dart';
import '../services/question_factory.dart';
import '../models/question.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final PageController _pageController = PageController();

  late List<Question> questions;

  @override
  void initState() {
    super.initState();
    questions = List.generate(
      5,
      (_) => QuestionFactory.generateGanWuXingQuestion(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("学习")),
      body: PageView.builder(
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
    );
  }
}
