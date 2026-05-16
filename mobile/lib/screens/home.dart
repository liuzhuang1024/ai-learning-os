import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateFormat('M月d日 EEEE', 'zh_CN').format(DateTime.now());
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(today,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.black54)),
              const SizedBox(height: 4),
              Text('今天的学习', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 32),
              _TodayCard(onTap: () => context.push('/quest')),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _NavTile(label: '导师', icon: Icons.forum_outlined, onTap: () => context.push('/tutor'))),
                  const SizedBox(width: 12),
                  Expanded(child: _NavTile(label: '我的记忆', icon: Icons.psychology_outlined, onTap: () => context.push('/memory'))),
                ],
              ),
              const Spacer(),
              Text(
                'D7 留存验证中 · v0.1',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.black38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Material(
      color: c.primary,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('今日任务',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70)),
              const SizedBox(height: 8),
              Text(
                '15 分钟',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text('一个概念 · 一组 Quiz · 一个动手',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 4),
                  Text('开始',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
