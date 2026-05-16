import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/memory.dart';
import '../providers.dart';
import '../widgets/confidence_bar.dart';

class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  Future<MemorySnapshot>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<MemorySnapshot> _load() async {
    final api = await ref.read(apiProvider.future);
    final data = await api.getMemory();
    return MemorySnapshot.fromJson(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的记忆')),
      body: FutureBuilder<MemorySnapshot>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('加载失败：${snap.error}'));
          }
          final m = snap.data!;
          if (m.items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('还没有学习记录。完成今日任务后会出现在这里。',
                    textAlign: TextAlign.center),
              ),
            );
          }
          final sorted = [...m.items]..sort((a, b) => b.confidence.compareTo(a.confidence));
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _MasteryRow(item: sorted[i]),
          );
        },
      ),
    );
  }
}

class _MasteryRow extends StatelessWidget {
  const _MasteryRow({required this.item});
  final MasteryItem item;

  @override
  Widget build(BuildContext context) {
    final pct = (item.confidence * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.conceptName, style: Theme.of(context).textTheme.titleMedium),
                ),
                Text('$pct%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.black54,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )),
              ],
            ),
            const SizedBox(height: 8),
            ConfidenceBar(value: item.confidence),
            const SizedBox(height: 6),
            Text(
              '答对 ${item.correctCount} · 答错 ${item.incorrectCount}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
