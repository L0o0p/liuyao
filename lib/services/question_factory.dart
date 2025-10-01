import '../data/tian_gan.dart';
import 'rule_functions.dart';
import '../models/question.dart';
import 'dart:math';

class QuestionFactory {
  static final _rnd = Random();

  static Question generateGanWuXingQuestion() {
    final gan = tianGan[_rnd.nextInt(tianGan.length)]["name"]!;
    final correct = getGanWuXing(gan);

    final options = ["木", "火", "土", "金", "水"];
    return Question(
      text: "$gan 属于什么五行？",
      options: options,
      correctAnswer: correct,
    );
  }
}
