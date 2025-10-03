/// 错题记录模型
/// 设计思路：只保存题目参数和答案信息，不保存完整题目对象
/// 这样可以：
/// 1. 节省存储空间
/// 2. 通过规则函数动态重建题目
/// 3. 避免题库数据冗余
class WrongQuestionRecord {
  /// 题目类型（对应题目生成函数）
  /// 例如："gan_wuxing"（天干五行）、"zhi_liuhe"（地支六合）等
  final String questionType;

  /// 题目输入参数（用于重建题目）
  /// 例如："甲"、"子"、"木" 等
  final String input;

  /// 正确答案
  final String correctAnswer;

  /// 用户最后一次的错误答案
  String userAnswer;

  /// 累计答错次数
  int wrongCount;

  /// 最后一次答错的时间
  DateTime lastWrongTime;

  WrongQuestionRecord({
    required this.questionType,
    required this.input,
    required this.correctAnswer,
    required this.userAnswer,
    this.wrongCount = 1,
    DateTime? lastWrongTime,
  }) : lastWrongTime = lastWrongTime ?? DateTime.now();

  /// 生成唯一标识符（用于存储和查重）
  /// 格式：questionType + input
  String get uniqueId => '${questionType}_$input';

  /// 增加错误次数
  void incrementWrongCount(String newUserAnswer) {
    wrongCount++;
    userAnswer = newUserAnswer;
    lastWrongTime = DateTime.now();
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'questionType': questionType,
      'input': input,
      'correctAnswer': correctAnswer,
      'userAnswer': userAnswer,
      'wrongCount': wrongCount,
      'lastWrongTime': lastWrongTime.toIso8601String(),
    };
  }

  /// 从 JSON 反序列化
  factory WrongQuestionRecord.fromJson(Map<String, dynamic> json) {
    return WrongQuestionRecord(
      questionType: json['questionType'] as String,
      input: json['input'] as String,
      correctAnswer: json['correctAnswer'] as String,
      userAnswer: json['userAnswer'] as String,
      wrongCount: json['wrongCount'] as int,
      lastWrongTime: DateTime.parse(json['lastWrongTime'] as String),
    );
  }

  @override
  String toString() {
    return 'WrongQuestionRecord(type: $questionType, input: $input, '
        'wrongCount: $wrongCount, lastWrong: $lastWrongTime)';
  }
}

