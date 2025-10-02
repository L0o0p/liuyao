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
    // 获取屏幕尺寸以进行响应式设计
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // 根据屏幕尺寸调整边距和字体大小
    final isSmallScreen = screenHeight < 700 || screenWidth < 400;
    final cardMargin = isSmallScreen ? 12.0 : 24.0;
    final cardPadding = isSmallScreen ? 16.0 : 24.0;
    final questionFontSize = isSmallScreen ? 20.0 : 24.0;
    final buttonFontSize = isSmallScreen ? 16.0 : 18.0;
    final feedbackFontSize = isSmallScreen ? 20.0 : 24.0;
    final iconSize = isSmallScreen ? 40.0 : 48.0;
    final verticalSpacing = isSmallScreen ? 16.0 : 32.0;
    final buttonSpacing = isSmallScreen ? 6.0 : 8.0;

    return Card(
      margin: EdgeInsets.all(cardMargin),
      elevation: 4,
      child: Container(
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          // 添加滚动支持，防止内容溢出
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 问题文本
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.question.text,
                  style: TextStyle(
                    fontSize: questionFontSize,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: verticalSpacing),

              // 选项列表
              ...widget.question.options.map((option) {
                final isSelected = selectedOption == option;
                final isCorrectOption = option == widget.question.correctAnswer;

                Color buttonColor = Theme.of(
                  context,
                ).primaryColor.withOpacity(0.6);
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
                  margin: EdgeInsets.symmetric(vertical: buttonSpacing),
                  child: ElevatedButton(
                    onPressed: hasAnswered
                        ? null
                        : () {
                            setState(() {
                              selectedOption = option;
                              hasAnswered = true;
                              isCorrect =
                                  option == widget.question.correctAnswer;
                            });

                            // 如果答案正确，延迟一下显示反馈，然后自动翻页
                            if (isCorrect && widget.onCorrectAnswer != null) {
                              Future.delayed(
                                const Duration(milliseconds: 300),
                                () {
                                  widget.onCorrectAnswer!();
                                },
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasAnswered
                          ? buttonColor
                          : Theme.of(context).primaryColor.withOpacity(0.1),
                      foregroundColor: hasAnswered
                          ? Colors.white
                          : Theme.of(context).primaryColor,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 12.0 : 16.0, // 根据屏幕大小调整按钮高度
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: hasAnswered ? 2 : 0,
                      shadowColor: hasAnswered
                          ? buttonColor.withOpacity(0.3)
                          : Colors.transparent,
                    ),
                    child: Text(
                      option,
                      style: TextStyle(fontSize: buttonFontSize),
                    ),
                  ),
                );
              }).toList(),

              // 选择后的反馈显示
              if (hasAnswered) ...[
                SizedBox(height: isSmallScreen ? 16.0 : 24.0),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCorrect
                          ? [Colors.green.shade50, Colors.green.shade100]
                          : [Colors.red.shade50, Colors.red.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCorrect ? Colors.green : Colors.red,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isCorrect ? Colors.green : Colors.red)
                            .withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? Colors.green : Colors.red,
                        size: iconSize,
                      ),
                      SizedBox(height: isSmallScreen ? 12.0 : 16.0),
                      Text(
                        isCorrect ? '正确！' : '错误',
                        style: TextStyle(
                          fontSize: feedbackFontSize,
                          fontWeight: FontWeight.bold,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 12.0 : 16.0),
                      Text(
                        '正确答案：${widget.question.correctAnswer}',
                        style: TextStyle(fontSize: buttonFontSize),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
