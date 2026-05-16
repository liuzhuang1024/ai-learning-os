class AssessmentQuestion {
  AssessmentQuestion({required this.id, required this.question, required this.options});

  final String id;
  final String question;
  final List<String> options;

  factory AssessmentQuestion.fromJson(Map<String, dynamic> j) => AssessmentQuestion(
        id: j['id'] as String,
        question: j['question'] as String,
        options: (j['options'] as List).cast<String>(),
      );
}
