enum MessageRole {
  user,
  assistant,
}

class AiMessageModel {
  final String text;
  final MessageRole role;
  final DateTime timestamp;

  AiMessageModel({
    required this.text,
    required this.role,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
