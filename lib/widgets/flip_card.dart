import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/question.dart';
import '../theme/app_theme.dart';
import 'tactile.dart';

class FlipCard extends StatefulWidget {
  final Question question;
  final void Function(Duration elapsed)? onCorrectAnswer;
  final void Function(String userAnswer, Duration elapsed)? onWrongAnswer;

  /// 答错后点击「下一题」，由外部页面负责翻页
  final VoidCallback? onNext;

  /// 答错时附在正确答案下面的说明。
  final String? wrongHint;

  /// 答错讲解里的「查表」。外部压栈打开，返回时本卡状态不变。
  final VoidCallback? onLookup;

  const FlipCard({
    super.key,
    required this.question,
    this.onCorrectAnswer,
    this.onWrongAnswer,
    this.onNext,
    this.wrongHint,
    this.onLookup,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> {
  String? selectedOption;
  bool hasAnswered = false;
  bool isCorrect = false;
  bool hasRequestedNext = false;
  late final DateTime _shownAt;

  @override
  void initState() {
    super.initState();
    _shownAt = DateTime.now();
  }

  void _choose(String option) {
    final elapsed = DateTime.now().difference(_shownAt);
    setState(() {
      selectedOption = option;
      hasAnswered = true;
      isCorrect = option == widget.question.correctAnswer;
    });

    if (isCorrect) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    // 答对短暂停顿，让对错反馈留在屏幕上，再进入下一题。
    if (isCorrect && widget.onCorrectAnswer != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        widget.onCorrectAnswer!(elapsed);
      });
    } else if (!isCorrect && widget.onWrongAnswer != null) {
      widget.onWrongAnswer!(option, elapsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700 || size.width < 400;
    final questionFontSize = isSmallScreen ? 20.0 : 24.0;
    final verticalSpacing = isSmallScreen ? 16.0 : 24.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: TactileCard(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        shadowColor: AppColors.border,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: Text(
                widget.question.text,
                style: TextStyle(
                  fontSize: questionFontSize,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: verticalSpacing),
            for (final option in widget.question.options)
              Padding(
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 5 : 6),
                child: _OptionButton(
                  label: option,
                  compact: isSmallScreen,
                  state: !hasAnswered
                      ? _OptionState.idle
                      : option == widget.question.correctAnswer
                      ? _OptionState.correct
                      : option == selectedOption
                      ? _OptionState.wrong
                      : _OptionState.faded,
                  onPressed: hasAnswered ? null : () => _choose(option),
                ),
              ),
            if (hasAnswered) ...[
              SizedBox(height: isSmallScreen ? 12 : 16),
              _Feedback(
                correct: isCorrect,
                answer: widget.question.correctAnswer,
                hint: isCorrect ? null : widget.wrongHint,
                compact: isSmallScreen,
              ),
              if (!isCorrect && widget.onLookup != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: widget.onLookup,
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text('查表'),
                ),
              ],
              // 答错时由用户确认看清答案后再进入下一题
              if (!isCorrect && widget.onNext != null) ...[
                const SizedBox(height: 12),
                TactileButton(
                  label: '下一题',
                  trailingIcon: Icons.arrow_forward,
                  onPressed: hasRequestedNext
                      ? null
                      : () {
                          setState(() {
                            hasRequestedNext = true;
                          });
                          widget.onNext!();
                        },
                ),
              ],
            ],
            if (!hasAnswered)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '选出正确答案',
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(color: scheme.outline),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _OptionState { idle, correct, wrong, faded }

class _OptionButton extends StatelessWidget {
  final String label;
  final _OptionState state;
  final bool compact;
  final VoidCallback? onPressed;

  const _OptionButton({
    required this.label,
    required this.state,
    required this.compact,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (
      Color fill,
      Color border,
      Color shadow,
      Color text,
    ) = switch (state) {
      _OptionState.idle => (
        scheme.surfaceContainerLowest,
        AppColors.border,
        AppColors.border,
        scheme.primary,
      ),
      _OptionState.correct => (
        AppColors.masteredBg,
        AppColors.masteredBorder,
        AppColors.masteredShadow,
        AppColors.masteredText,
      ),
      _OptionState.wrong => (
        AppColors.wrongBg,
        AppColors.wrong,
        AppColors.wrongShadow,
        AppColors.wrong,
      ),
      _OptionState.faded => (
        scheme.surfaceContainer,
        scheme.outlineVariant,
        scheme.outlineVariant,
        scheme.outline,
      ),
    };
    final radius = BorderRadius.circular(18);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 3))],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: fill,
          foregroundColor: text,
          disabledBackgroundColor: fill,
          disabledForegroundColor: text,
          padding: EdgeInsets.symmetric(vertical: compact ? 12 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: border, width: 2),
          ),
          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: compact ? 16 : 18,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state == _OptionState.correct) ...[
              const Icon(Icons.check_circle, size: 20),
              const SizedBox(width: 6),
            ],
            if (state == _OptionState.wrong) ...[
              const Icon(Icons.cancel, size: 20),
              const SizedBox(width: 6),
            ],
            Flexible(child: Text(label, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  final bool correct;
  final String answer;
  final String? hint;
  final bool compact;

  const _Feedback({
    required this.correct,
    required this.answer,
    required this.hint,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = correct ? AppColors.correct : AppColors.wrong;
    final hint = this.hint;
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: correct ? AppColors.correctBg : AppColors.wrongBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: correct ? AppColors.masteredShadow : AppColors.wrongShadow,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                correct ? Icons.check_circle : Icons.cancel,
                color: accent,
                size: compact ? 26 : 30,
              ),
              const SizedBox(width: 8),
              Text(
                correct ? '正确！' : '错误',
                style: textTheme.headlineMedium?.copyWith(color: accent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '正确答案：$answer',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (hint != null && hint.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
