import 'dart:async';

import 'package:flutter/material.dart';

import '../data/knowledge_catalog.dart';
import '../models/question.dart';
import '../models/srs_card.dart';
import '../services/srs_scheduler.dart';
import '../services/storage_service.dart';
import '../services/sync/sync_engine.dart';
import '../widgets/flip_card.dart';

/// 消费一份已经排好的知识点队列。答错会把同一条再放到本次队列末尾。
class StudySessionScreen extends StatefulWidget {
  final String title;
  final Future<List<String>> Function() loadItemKeys;

  /// 每答完这么多题提示休息。只影响界面，不写进度。
  final int? restEvery;

  const StudySessionScreen({
    super.key,
    required this.title,
    required this.loadItemKeys,
    this.restEvery,
  });

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  final Map<String, SrsCard> _cards = {};
  List<Question> _questions = [];
  int _index = 0;
  int _answered = 0;
  bool _loading = true;
  String? _error;
  Future<void>? _ready;
  Future<void>? _pendingGrade;

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
    _ready = _prepareCurrent();
  }

  Future<void> _prepareCurrent() async {
    final key = _questions[_index].itemKey;
    if (_cards.containsKey(key)) return;
    final existing = await StorageService.loadCard(key);
    if (existing != null) {
      _cards[key] = existing;
      return;
    }
    final created = SrsScheduler.introduce(key, DateTime.now());
    await StorageService.saveCard(created);
    _cards[key] = created;
  }

  Future<void> _grade(bool correct, Duration elapsed) async {
    await _ready;
    if (_index < 0 || _index >= _questions.length) return;
    final question = _questions[_index];
    final now = DateTime.now();
    final current =
        _cards[question.itemKey] ?? SrsScheduler.introduce(question.itemKey, now);
    final updated = SrsScheduler.grade(
      card: current,
      correct: correct,
      elapsed: elapsed,
      now: now,
    );
    _cards[question.itemKey] = updated;
    await StorageService.saveCard(updated);
  }

  Future<void> _handleCorrect(Duration elapsed) async {
    await _grade(true, elapsed);
    if (!mounted) return;
    await _advance();
  }

  Future<void> _handleWrong(Duration elapsed) async {
    await _grade(false, elapsed);
    if (!mounted || _index >= _questions.length) return;
    final question = _questions[_index];
    final again = _questionFor(question.itemKey);
    if (again == null) return;
    setState(() {
      _questions.add(again);
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
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
    return SafeArea(
      child: FlipCard(
        key: ValueKey('$_index:${question.itemKey}:${question.text}'),
        question: question,
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
