/// Represents a single chat message in the AI assistant conversation.
class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
    this.timestamp,
    this.metadata,
  });

  /// Who sent this message.
  final ChatRole role;

  /// The text content of the message.
  final String content;

  /// When the message was created.
  final DateTime? timestamp;

  /// Optional structured metadata (e.g., stock query results).
  final Map<String, dynamic>? metadata;
}

/// Roles in a chat conversation.
enum ChatRole {
  /// Message from the user.
  user,

  /// Response from the AI assistant.
  assistant,

  /// System prompt or internal instruction.
  system,
}
