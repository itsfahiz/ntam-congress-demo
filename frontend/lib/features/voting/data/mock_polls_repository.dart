import 'polls_repository.dart';

class MockPollsRepository implements PollsRepository {
  MockPollsRepository();

  static const pollId = '7a1c0001-0000-4000-8000-000000000001';
  static const aiId = '7a1c0001-0000-4000-8000-000000000011';
  static const nutritionId = '7a1c0001-0000-4000-8000-000000000012';
  static const digitalId = '7a1c0001-0000-4000-8000-000000000013';

  static const poll2Id = '7a1c0001-0000-4000-8000-000000000002';
  static const pediatricId = '7a1c0001-0000-4000-8000-000000000021';
  static const researchId = '7a1c0001-0000-4000-8000-000000000022';
  static const preventiveId = '7a1c0001-0000-4000-8000-000000000023';

  static const poll3Id = '7a1c0001-0000-4000-8000-000000000003';
  static const panelId = '7a1c0001-0000-4000-8000-000000000031';
  static const casesId = '7a1c0001-0000-4000-8000-000000000032';
  static const workshopsId = '7a1c0001-0000-4000-8000-000000000033';

  final Map<String, Map<String, int>> _counts = {
    pollId: {aiId: 0, nutritionId: 0, digitalId: 0},
    poll2Id: {pediatricId: 0, researchId: 0, preventiveId: 0},
    poll3Id: {panelId: 0, casesId: 0, workshopsId: 0},
  };
  final Map<String, String> _myOptionIds = {};

  List<LivePoll> _all() {
    return [
      _snapshot(
        pollId,
        'Which innovation will have the greatest impact on healthcare?',
        'Healthcare innovation',
        [
          ('Artificial Intelligence', aiId),
          ('Personalized Nutrition', nutritionId),
          ('Digital Health', digitalId),
        ],
      ),
      _snapshot(
        poll2Id,
        'Which topic would you most like to explore at a future medical congress?',
        'Future congress',
        [
          ('Pediatric Nutrition', pediatricId),
          ('Clinical Research', researchId),
          ('Preventive Healthcare', preventiveId),
        ],
      ),
      _snapshot(
        poll3Id,
        'Which session format helps you learn most effectively?',
        'Learning format',
        [
          ('Expert Panel Discussions', panelId),
          ('Clinical Case Studies', casesId),
          ('Interactive Workshops', workshopsId),
        ],
      ),
    ];
  }

  LivePoll _snapshot(
    String id,
    String question,
    String topicLabel,
    List<(String, String)> options,
  ) {
    final counts = _counts[id] ?? {};
    final total = counts.values.fold<int>(0, (sum, count) => sum + count);
    return LivePoll(
      id: id,
      question: question,
      topicLabel: topicLabel,
      totalVotes: total,
      myOptionId: _myOptionIds[id],
      options: [
        for (final option in options)
          LivePollOption(
            id: option.$2,
            label: option.$1,
            voteCount: counts[option.$2] ?? 0,
            percent: total == 0
                ? 0
                : (((counts[option.$2] ?? 0) / total) * 100).round(),
          ),
      ],
    );
  }

  @override
  Future<List<LivePoll>> list() async => _all();

  @override
  Future<LivePoll> getActive() async => _all().first;

  @override
  Future<LivePoll> vote({
    required String pollId,
    required String optionId,
  }) async {
    final counts = _counts[pollId];
    if (counts == null) {
      throw const PollsException('Poll not found.');
    }
    if (!counts.containsKey(optionId)) {
      throw const PollsException('That option is not part of this poll.');
    }
    if (_myOptionIds.containsKey(pollId)) {
      throw const PollsException(
        'You already voted in this poll.',
        alreadyVoted: true,
      );
    }
    _myOptionIds[pollId] = optionId;
    counts[optionId] = (counts[optionId] ?? 0) + 1;
    return _all().firstWhere((poll) => poll.id == pollId);
  }
}
