import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quest.dart';
import '../providers.dart';

class QuestScreen extends ConsumerStatefulWidget {
  const QuestScreen({super.key});

  @override
  ConsumerState<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends ConsumerState<QuestScreen> {
  Future<Quest>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Quest> _load() async {
    final api = await ref.read(apiProvider.future);
    final data = await api.getTodayQuest();
    return Quest.fromJson(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('今日学习')),
      body: FutureBuilder<Quest>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorView(
              error: snap.error!,
              onRetry: () => setState(() => _future = _load()),
            );
          }
          return _QuestBody(quest: snap.data!);
        },
      ),
    );
  }
}

class _QuestBody extends ConsumerStatefulWidget {
  const _QuestBody({required this.quest});
  final Quest quest;

  @override
  ConsumerState<_QuestBody> createState() => _QuestBodyState();
}

class _QuestBodyState extends ConsumerState<_QuestBody> {
  final Map<int, AnswerResult> _results = {};
  int _submitting = -1;

  Future<void> _submit(int questionIndex, int choice) async {
    setState(() => _submitting = questionIndex);
    try {
      final api = await ref.read(apiProvider.future);
      final res = await api.submitAnswer(
        widget.quest.id,
        questionIndex: questionIndex,
        choiceIndex: choice,
      );
      setState(() => _results[questionIndex] = AnswerResult.fromJson(res));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提交失败：$e')));
    } finally {
      if (mounted) setState(() => _submitting = -1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quest;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('今日概念',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.black54)),
                const SizedBox(height: 4),
                Text(q.conceptId, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Text(q.explanation, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Quiz', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...List.generate(q.quiz.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _QuizCard(
              index: i,
              question: q.quiz[i],
              result: _results[i],
              submitting: _submitting == i,
              onPick: (choice) => _submit(i, choice),
            ),
          );
        }),
        if (q.practice.prompt.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('动手环节', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                q.practice.prompt,
                style: const TextStyle(fontFamily: 'monospace', height: 1.5),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.index,
    required this.question,
    required this.result,
    required this.submitting,
    required this.onPick,
  });
  final int index;
  final QuizQuestion question;
  final AnswerResult? result;
  final bool submitting;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final done = result != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('第 ${index + 1} 题',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.black54)),
            const SizedBox(height: 6),
            Text(question.question, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...List.generate(question.options.length, (i) {
              Color? bg;
              if (done) {
                if (i == result!.correctIndex) bg = Colors.green.withValues(alpha: 0.10);
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                child: InkWell(
                  onTap: (done || submitting) ? null : () => onPick(i),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(String.fromCharCode(65 + i),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(question.options[i])),
                        if (done && i == result!.correctIndex)
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (done && result!.explanation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: result!.isCorrect ? Colors.green.withValues(alpha: 0.08) : Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(result!.explanation,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.black38),
            const SizedBox(height: 12),
            Text('加载失败', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
