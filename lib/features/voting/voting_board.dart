import '../congress/domain/congress_models.dart';

/// In-memory votes for the current Live Voting screen instance.
/// Leaving the screen disposes this board. Use [reset] to clear without leaving.
class VotingBoard {
  VotingBoard(this.polls) : assert(polls.isNotEmpty, 'Poll catalog is empty.');

  final List<CongressPoll> polls;
  var index = 0;
  final Map<String, String> _votes = {};
  final Map<String, String> _pending = {};

  CongressPoll get current => polls[index];

  bool get hasVotedCurrent => _votes.containsKey(current.id);

  String? get selectedOptionId => _votes[current.id] ?? _pending[current.id];

  bool get hasMultiplePolls => polls.length > 1;

  void select(String optionId) {
    if (hasVotedCurrent) return;
    _pending[current.id] = optionId;
  }

  VoteCastResult submit() {
    if (hasVotedCurrent) return VoteCastResult.alreadyVoted;
    final optionId = _pending[current.id];
    if (optionId == null) return VoteCastResult.missingSelection;
    _votes[current.id] = optionId;
    _pending.remove(current.id);
    return VoteCastResult.recorded;
  }

  void nextPoll() {
    if (!hasMultiplePolls) return;
    index = (index + 1) % polls.length;
  }

  void previousPoll() {
    if (!hasMultiplePolls) return;
    index = (index - 1 + polls.length) % polls.length;
  }

  void reset() {
    _votes.clear();
    _pending.clear();
    index = 0;
  }

  int simulatedCount(CongressPoll poll, PollOption option) {
    var count = option.simulatedVotes;
    if (_votes[poll.id] == option.id) count += 1;
    return count;
  }

  int simulatedTotal(CongressPoll poll) {
    var total = 0;
    for (final option in poll.options) {
      total += simulatedCount(poll, option);
    }
    return total;
  }

  int simulatedPercent(CongressPoll poll, PollOption option) {
    final total = simulatedTotal(poll);
    if (total == 0) return 0;
    return ((simulatedCount(poll, option) / total) * 100).round();
  }
}
