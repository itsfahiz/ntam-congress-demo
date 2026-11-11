import 'package:flutter/widgets.dart';

class PollsException implements Exception {
  const PollsException(this.message, {this.alreadyVoted = false});

  final String message;
  final bool alreadyVoted;

  @override
  String toString() => message;
}

class LivePollOption {
  const LivePollOption({
    required this.id,
    required this.label,
    required this.voteCount,
    required this.percent,
  });

  final String id;
  final String label;
  final int voteCount;
  final int percent;
}

class LivePoll {
  const LivePoll({
    required this.id,
    required this.question,
    required this.topicLabel,
    required this.totalVotes,
    required this.options,
    this.myOptionId,
  });

  final String id;
  final String question;
  final String topicLabel;
  final int totalVotes;
  final String? myOptionId;
  final List<LivePollOption> options;

  bool get hasVoted => myOptionId != null;

  static LivePoll? fromMap(Map<dynamic, dynamic> poll) {
    final map = Map<String, dynamic>.from(poll);
    final rawOptions = map['options'];
    final options = <LivePollOption>[
      if (rawOptions is List)
        for (final item in rawOptions)
          if (item is Map)
            LivePollOption(
              id: item['id'] as String? ?? '',
              label: item['label'] as String? ?? '',
              voteCount: (item['voteCount'] as num?)?.toInt() ?? 0,
              percent: (item['percent'] as num?)?.toInt() ?? 0,
            ),
    ];
    if (map['id'] is! String || options.isEmpty) return null;
    return LivePoll(
      id: map['id'] as String,
      question: map['question'] as String? ?? '',
      topicLabel: map['topicLabel'] as String? ?? 'Live poll',
      totalVotes: (map['totalVotes'] as num?)?.toInt() ?? 0,
      myOptionId: map['myOptionId'] as String?,
      options: options,
    );
  }

  static LivePoll? fromJson(Map<String, dynamic> json) {
    final poll = json['poll'];
    if (poll is Map) return fromMap(poll);
    return fromMap(json);
  }

  static List<LivePoll> listFromJson(Map<String, dynamic> json) {
    final raw = json['polls'];
    if (raw is! List) return const [];
    final polls = <LivePoll>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final poll = fromMap(item);
      if (poll != null) polls.add(poll);
    }
    return polls;
  }
}

abstract interface class PollsRepository {
  Future<List<LivePoll>> list();

  Future<LivePoll> getActive();

  Future<LivePoll> vote({required String pollId, required String optionId});
}

class PollsScope extends InheritedWidget {
  const PollsScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final PollsRepository repository;

  static PollsRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PollsScope>();
    assert(scope != null, 'PollsScope not found in the widget tree.');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(PollsScope oldWidget) {
    return repository != oldWidget.repository;
  }
}
