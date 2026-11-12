class AssistantSource {
  const AssistantSource({required this.type, required this.id});

  final String type;
  final String id;

  factory AssistantSource.fromJson(Map<String, dynamic> json) {
    return AssistantSource(
      type: json['type'] as String? ?? '',
      id: json['id'] as String? ?? '',
    );
  }

  bool get isSession => type == 'session';
  bool get isSpeaker => type == 'speaker';
  bool get isDay => type == 'day';
}

class AssistantAction {
  const AssistantAction({required this.label, required this.route});

  final String label;
  final String route;
}

class AssistantReply {
  const AssistantReply({
    required this.answer,
    required this.grounded,
    required this.sources,
    this.actions = const [],
  });

  final String answer;
  final bool grounded;
  final List<AssistantSource> sources;
  final List<AssistantAction> actions;

  factory AssistantReply.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'];
    final sources = <AssistantSource>[];
    if (rawSources is List) {
      for (final item in rawSources) {
        if (item is! Map) continue;
        final source = AssistantSource.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (source.type.isEmpty || source.id.isEmpty) continue;
        sources.add(source);
      }
    }
    return AssistantReply(
      answer: json['answer'] as String? ?? '',
      grounded: json['grounded'] == true,
      sources: sources,
    );
  }
}

enum AssistantFailureKind { offline, timeout, busy, unavailable, invalid }

class AssistantException implements Exception {
  const AssistantException(this.message, {this.kind = AssistantFailureKind.unavailable});

  final String message;
  final AssistantFailureKind kind;

  @override
  String toString() => message;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.question,
    this.reply,
    this.error,
    this.loading = false,
  });

  final String id;
  final String question;
  final AssistantReply? reply;
  final AssistantException? error;
  final bool loading;

  ChatMessage copyWith({
    AssistantReply? reply,
    AssistantException? error,
    bool? loading,
    bool clearError = false,
  }) {
    return ChatMessage(
      id: id,
      question: question,
      reply: reply ?? this.reply,
      error: clearError ? null : (error ?? this.error),
      loading: loading ?? this.loading,
    );
  }
}
