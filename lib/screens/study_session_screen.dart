import 'dart:async';

import 'package:flutter/material.dart';

import '../data/chapters.dart';
import '../data/knowledge_catalog.dart';
import '../data/study_groups.dart';
import '../data/teaching_notes.dart';
import '../models/question.dart';
import '../models/srs_card.dart';
import '../services/srs_scheduler.dart';
import '../services/storage_service.dart';
import '../services/sync/sync_engine.dart';
import '../widgets/flip_card.dart';
import '../widgets/group_intro_card.dart';
import '../widgets/teaching_card.dart';
import 'chapter_tables_screen.dart';

/// 消费一份已经排好的知识点队列。
/// 答错，或有失误后连续答对还没到 2 次，都会把同一条再放到本次队列末尾。
class StudySessionScreen extends StatefulWidget {
  final String title;
  final Future<List<String>> Function() loadItemKeys;

  /// 每答完这么多题提示休息。只影响界面，不写进度。
  final int? restEvery;

  /// 本次引入的新组。练到这组第一个知识点前先看小组引入页，
  /// 组内知识点不再逐条显示教学卡。
  final StudyGroup? group;

  const StudySessionScreen({
    super.key,
    required this.title,
    required this.loadItemKeys,
    this.restEvery,
    this.group,
  });

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  final Map<String, SrsCard> _cards = {};
  final Set<String> _missedKeys = {};
  List<Question> _questions = [];
  int _index = 0;
  int _answered = 0;
  bool _loading = true;
  bool _prepared = false;
  bool _showTeaching = false;
  bool _showGroupIntro = false;
  bool _groupIntroSeen = false;
  String? _error;
  Future<void>? _ready;
  Future<void>? _pendingGrade;

  /// 当前这道题作答前在查表页停留的总时长，评分时从答题用时里扣掉。
  Duration _lookupTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    unawaited(SyncEngine.instance.sync());
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final keys = await widget.loadItemKeys();
      final questions = <Question>[];
      for (final key in keys) {
        final question = _questionFor(key);
        if (question != null) questions.add(question);
      }
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _index = 0;
        _answered = 0;
        _loading = false;
      });
      _schedulePrepare();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '题目加载失败：$error';
        _loading = false;
      });
    }
  }

  void _schedulePrepare() {
    if (_index < 0 || _index >= _questions.length) return;
    _prepared = false;
    _showTeaching = false;
    _showGroupIntro = false;
    _lookupTime = Duration.zero;
    _ready = _prepareCurrent();
  }

  Future<void> _prepareCurrent() async {
    final key = _questions[_index].itemKey;
    if (!_cards.containsKey(key)) {
      final existing = await StorageService.loadCard(key);
      if (existing != null) {
        _cards[key] = existing;
      } else {
        final created = SrsScheduler.introduce(key, DateTime.now());
        await StorageService.saveCard(created);
        _cards[key] = created;
      }
    }
    if (!mounted || _questions[_index].itemKey != key) return;
    final card = _cards[key]!;
    final inGroup = widget.group?.itemKeys.contains(key) ?? false;
    setState(() {
      _prepared = true;
      _showGroupIntro = inGroup && !_groupIntroSeen;
      _showTeaching = !inGroup && card.reps == 0 && card.lastReviewedAt == null;
    });
  }

  /// 返回这次作答后是否还要把当前知识点再放回队列末尾。
  Future<bool> _grade(bool correct, Duration elapsed) async {
    await _ready;
    if (_index < 0 || _index >= _questions.length) return false;
    final question = _questions[_index];
    final now = DateTime.now();
    final current =
        _cards[question.itemKey] ?? SrsScheduler.introduce(question.itemKey, now);
    final missedInSession = _missedKeys.contains(question.itemKey);
    final replay = SrsScheduler.replaysInSession(
      card: current,
      correct: correct,
      missedInSession: missedInSession,
    );
    final thinking = elapsed - _lookupTime;
    final updated = SrsScheduler.grade(
      card: current,
      correct: correct,
      elapsed: thinking.isNegative ? Duration.zero : thinking,
      now: now,
      missedInSession: missedInSession,
    );
    if (!correct) _missedKeys.add(question.itemKey);
    _cards[question.itemKey] = updated;
    await StorageService.saveCard(updated);
    return replay;
  }

  void _appendCurrentAgain() {
    if (_index < 0 || _index >= _questions.length) return;
    final again = _questionFor(_questions[_index].itemKey);
    if (again == null) return;
    _questions.add(again);
  }

  Future<void> _handleCorrect(Duration elapsed) async {
    final replay = await _grade(true, elapsed);
    if (!mounted) return;
    if (replay) {
      setState(_appendCurrentAgain);
    }
    await _advance();
  }

  Future<void> _handleWrong(Duration elapsed) async {
    final replay = await _grade(false, elapsed);
    if (!mounted || _index >= _questions.length) return;
    if (replay) {
      setState(_appendCurrentAgain);
    }
  }

  Future<void> _advance() async {
    final nextAnswered = _answered + 1;
    final hasMore = _index < _questions.length - 1;
    final restEvery = widget.restEvery;
    if (restEvery != null &&
        restEvery > 0 &&
        hasMore &&
        nextAnswered % restEvery == 0) {
      final keepGoing = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('休息一下'),
          content: Text('已完成 $nextAnswered 题。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('暂时退出'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('继续'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (keepGoing != true) {
        Navigator.of(context).pop();
        return;
      }
    }
    if (!mounted) return;
    if (!hasMore) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('本次练完了'),
          content: const Text('这批知识点已经过了一遍。'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('返回'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _answered = nextAnswered;
      _index += 1;
    });
    _schedulePrepare();
  }

  Chapter? get _currentChapter {
    if (_loading || _error != null) return null;
    if (_index < 0 || _index >= _questions.length) return null;
    return Chapters.forQuestionType(_questions[_index].questionType);
  }

  /// 压栈打开，不动本页状态，返回时还在原题。
  Future<void> _openTables(Chapter chapter) async {
    final countsTowardAnswer = !_showTeaching && !_showGroupIntro;
    final index = _index;
    final openedAt = DateTime.now();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChapterTablesScreen(chapter: chapter),
      ),
    );
    if (countsTowardAnswer && index == _index) {
      _lookupTime += DateTime.now().difference(openedAt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapter = _currentChapter;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (chapter != null)
            TextButton.icon(
              onPressed: () => _openTables(chapter),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
              ),
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text('查表'),
            ),
          if (!_loading && _error == null && _questions.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_index + 1}/${_questions.length}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: const Text('重试')),
          ],
        ),
      );
    }
    if (_questions.isEmpty) {
      return const Center(child: Text('没有要练习的内容'));
    }
    final question = _questions[_index];
    if (!_prepared) {
      return const Center(child: CircularProgressIndicator());
    }
    final group = widget.group;
    if (_showGroupIntro && group != null) {
      return GroupIntroCard(
        group: group,
        onContinue: () {
          setState(() {
            _showGroupIntro = false;
            _groupIntroSeen = true;
          });
        },
      );
    }
    final note = TeachingNotes.forQuestion(question);
    final chapter = Chapters.forQuestionType(question.questionType);
    final intro = TeachingNotes.forKey(question.itemKey);
    if (_showTeaching && intro != null) {
      return TeachingCard(
        note: intro,
        onContinue: () {
          setState(() {
            _showTeaching = false;
          });
        },
      );
    }
    return SafeArea(
      child: FlipCard(
        key: ValueKey('$_index:${question.itemKey}:${question.text}'),
        question: question,
        wrongHint: note == null ? null : '${note.fact}。${note.hint}',
        onLookup: chapter == null ? null : () => _openTables(chapter),
        onCorrectAnswer: (elapsed) {
          _pendingGrade = _handleCorrect(elapsed);
        },
        onWrongAnswer: (_, elapsed) {
          _pendingGrade = _handleWrong(elapsed);
        },
        onNext: () async {
          await _pendingGrade;
          if (!mounted) return;
          await _advance();
        },
      ),
    );
  }
}

Question? _questionFor(String itemKey) {
  final separator = itemKey.indexOf(':');
  if (separator <= 0 || separator >= itemKey.length - 1) return null;
  final type = itemKey.substring(0, separator);
  final input = itemKey.substring(separator + 1);
  if (KnowledgeCatalog.find(type, input) == null) return null;
  return KnowledgeCatalog.generateQuestion(type, input);
}
