class MasteryItem {
  MasteryItem({
    required this.conceptId,
    required this.conceptName,
    required this.confidence,
    required this.correctCount,
    required this.incorrectCount,
  });

  final String conceptId;
  final String conceptName;
  final double confidence;
  final int correctCount;
  final int incorrectCount;

  factory MasteryItem.fromJson(Map<String, dynamic> j) => MasteryItem(
        conceptId: j['concept_id'] as String,
        conceptName: j['concept_name'] as String,
        confidence: (j['confidence'] as num).toDouble(),
        correctCount: j['correct_count'] as int,
        incorrectCount: j['incorrect_count'] as int,
      );
}

class MemorySnapshot {
  MemorySnapshot({required this.items, required this.weak, required this.preferredStyle});

  final List<MasteryItem> items;
  final List<String> weak;
  final String preferredStyle;

  factory MemorySnapshot.fromJson(Map<String, dynamic> j) => MemorySnapshot(
        items: (j['items'] as List)
            .map((e) => MasteryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        weak: (j['weak'] as List).cast<String>(),
        preferredStyle: j['preferred_style'] as String,
      );
}
