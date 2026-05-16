class ChatMessage {
  ChatMessage({required this.role, required this.content});

  // 'user' | 'assistant'
  final String role;
  final String content;

  Map<String, String> toJson() => {'role': role, 'content': content};
}
