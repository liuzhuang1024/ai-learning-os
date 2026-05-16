import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/assessment.dart';
import '../providers.dart';
import '../services/auth.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  final _backgroundCtrl = TextEditingController();
  String _style = 'mixed';
  final Map<String, int> _answers = {};
  List<AssessmentQuestion>? _questions;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _backgroundCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = await ref.read(apiProvider.future);
      final data = await api.getAssessment();
      final qs = (data['questions'] as List)
          .map((e) => AssessmentQuestion.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _questions = qs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = await ref.read(apiProvider.future);
      await api.submitAssessment(
        answers: _answers,
        backgroundSummary: _backgroundCtrl.text.trim(),
        preferredStyle: _style,
      );
      await Auth.markOnboarded();
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('诊断 · 第 ${_step + 1} 步 / 3'), centerTitle: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (_step) {
            0 => _StepBackground(
                controller: _backgroundCtrl,
                onNext: () => setState(() => _step = 1),
              ),
            1 => _StepStyle(
                value: _style,
                onChanged: (v) => setState(() => _style = v),
                onNext: () {
                  setState(() => _step = 2);
                  _loadQuestions();
                },
              ),
            _ => _StepAssessment(
                loading: _loading,
                error: _error,
                questions: _questions,
                answers: _answers,
                onAnswer: (id, idx) => setState(() => _answers[id] = idx),
                onSubmit: _answers.length == (_questions?.length ?? 0) ? _submit : null,
                onRetry: _loadQuestions,
              ),
          },
        ),
      ),
    );
  }
}

class _StepBackground extends StatelessWidget {
  const _StepBackground({required this.controller, required this.onNext});
  final TextEditingController controller;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('简单介绍一下你的背景', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          '比如：后端工程师 5 年，懂 Python，没系统学过 ML。\n这会帮助导师用你能听懂的方式解释。',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '说说你的技术背景和学习目标…',
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: controller,
          builder: (_, __) => FilledButton(
            onPressed: controller.text.trim().length < 5 ? null : onNext,
            child: const Text('下一步'),
          ),
        ),
      ],
    );
  }
}

class _StepStyle extends StatelessWidget {
  const _StepStyle({required this.value, required this.onChanged, required this.onNext});
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  static const _options = [
    ('analogy', '类比解释', '用生活/工程类比讲抽象概念'),
    ('code', '代码示例', '看代码片段比看公式更容易理解'),
    ('formula', '公式推导', '数学背景扎实，喜欢看推导'),
    ('mixed', '混合', '看情况切换风格'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('你偏好的解释风格', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('随时可以在设置里改', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
        const SizedBox(height: 24),
        ..._options.map((o) {
          final selected = o.$1 == value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => onChanged(o.$1),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.$2, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(o.$3, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                        ],
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        FilledButton(onPressed: onNext, child: const Text('开始测试')),
      ],
    );
  }
}

class _StepAssessment extends StatelessWidget {
  const _StepAssessment({
    required this.loading,
    required this.error,
    required this.questions,
    required this.answers,
    required this.onAnswer,
    required this.onSubmit,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final List<AssessmentQuestion>? questions;
  final Map<String, int> answers;
  final void Function(String id, int idx) onAnswer;
  final VoidCallback? onSubmit;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading && questions == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('加载失败：$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      );
    }
    final qs = questions!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('能力快照', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          '不会的就猜，目的是给你一个起点，不是打分。',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: qs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) => _QuestionCard(
              q: qs[i],
              selected: answers[qs[i].id],
              onSelected: (idx) => onAnswer(qs[i].id, idx),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: loading ? null : onSubmit,
          child: loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('提交'),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.q, required this.selected, required this.onSelected});
  final AssessmentQuestion q;
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.question, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...List.generate(q.options.length, (i) {
              final picked = selected == i;
              return RadioListTile<int>(
                value: i,
                groupValue: selected,
                onChanged: (v) => onSelected(v!),
                title: Text(q.options[i]),
                contentPadding: EdgeInsets.zero,
                dense: true,
                selected: picked,
              );
            }),
          ],
        ),
      ),
    );
  }
}
