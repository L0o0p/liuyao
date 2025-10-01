import 'package:flutter/material.dart';
import '../models/question.dart';

class FlipCard extends StatefulWidget {
  final Question question;
  final VoidCallback? onCorrectAnswer;

  const FlipCard({super.key, required this.question, this.onCorrectAnswer});

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> {
  String? selectedOption;
  bool hasAnswered = false;
  bool isCorrect = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(24),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 问题文本
            Text(
              widget.question.text,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // 选项列表
            ...widget.question.options.map((option) {
              final isSelected = selectedOption == option;
              final isCorrectOption = option == widget.question.correctAnswer;

              Color buttonColor = Colors.blue;
              if (hasAnswered) {
                // 确保正确答案总是绿色
                if (isCorrectOption) {
                  buttonColor = Colors.green;
                }
                // 如果选择了错误答案，显示红色
                else if (isSelected && !isCorrectOption) {
                  buttonColor = Colors.red;
                }
                // 其他未选择的选项显示灰色
                else {
                  buttonColor = Colors.grey;
                }
              }

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton(
                  onPressed: hasAnswered
                      ? null
                      : () {
                          setState(() {
                            selectedOption = option;
                            hasAnswered = true;
                            isCorrect = option == widget.question.correctAnswer;
                          });

                          // 如果答案正确，延迟一下显示反馈，然后自动翻页
                          if (isCorrect && widget.onCorrectAnswer != null) {
                            Future.delayed(
                              const Duration(milliseconds: 1500),
                              () {
                                widget.onCorrectAnswer!();
                              },
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(option, style: const TextStyle(fontSize: 18)),
                ),
              );
            }).toList(),

            // 选择后的反馈显示
            if (hasAnswered) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCorrect ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green : Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isCorrect ? '正确！' : '错误',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '正确答案：${widget.question.correctAnswer}',
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
