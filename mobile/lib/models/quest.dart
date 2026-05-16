class QuizQuestion {
  QuizQuestion({required this.question, required this.options});

  final String question;
  final List<String> options;

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        question: j['question'] as String,
        options: (j['options'] as List).cast<String>(),
      );
}

class Practice {
  Practice({required this.type, required this.prompt});

  final String type;
  final String prompt;

  factory Practice.fromJson(Map<String, dynamic> j) => Practice(
        type: j['type'] as String? ?? 'thought',
        prompt: j['prompt'] as String? ?? '',
      );
}

class Quest {
  Quest({
    required this.id,
    required this.date,
    required this.conceptId,
    required this.explanation,
    required this.quiz,
    required this.practice,
    required this.status,
  });

  final String id;
  final DateTime date;
  final String conceptId;
  final String explanation;
  final List<QuizQuestion> quiz;
  final Practice practice;
  final String status;

  factory Quest.fromJson(Map<String, dynamic> j) => Quest(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        conceptId: j['concept_id'] as String,
        explanation: j['explanation'] as String? ?? '',
        quiz: (j['quiz'] as List)
            .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
        practice: Practice.fromJson(j['practice'] as Map<String, dynamic>),
        status: j['status'] as String,
      );
}

class AnswerResult {
  AnswerResult({required this.isCorrect, required this.correctIndex, required this.explanation});

  final bool isCorrect;
  final int correctIndex;
  final String explanation;

  factory AnswerResult.fromJson(Map<String, dynamic> j) => AnswerResult(
        isCorrect: j['is_correct'] as bool,
        correctIndex: j['correct_index'] as int,
        explanation: j['explanation'] as String? ?? '',
      );
}
