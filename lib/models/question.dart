class Question {
  final String text;
  final List<String> options;
  final String correctAnswer;

  /// 题型，与 QuestionReconstructor.reconstructFromRecord 的分支一致。
  /// 旧题表没有这个字段时为空字符串。
  final String questionType;

  /// 生成这道题所用的输入，例如天干「甲」、地支「子」。
  /// 旧题表没有这个字段时为空字符串。
  final String input;

  Question({
    required this.text,
    required this.options,
    required this.correctAnswer,
    this.questionType = '',
    this.input = '',
  });

  /// 知识点唯一键，例如 `gan_wuxing:甲`。
  String get itemKey => '$questionType:$input';

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      text: json['text'] as String,
      options: (json['options'] as List<dynamic>)
          .map((option) => option as String)
          .toList(),
      correctAnswer: json['correctAnswer'] as String,
      questionType: json['questionType'] as String? ?? '',
      input: json['input'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'options': options,
      'correctAnswer': correctAnswer,
      'questionType': questionType,
      'input': input,
    };
  }
}
