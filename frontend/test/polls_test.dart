import 'package:flutter_test/flutter_test.dart';
import 'package:ntam_congress_demo/features/voting/data/http_polls_repository.dart';
import 'package:ntam_congress_demo/features/voting/data/mock_polls_repository.dart';
import 'package:ntam_congress_demo/features/voting/data/polls_repository.dart';

void main() {
  const payload = '''
{
  "poll": {
    "id": "7a1c0001-0000-4000-8000-000000000001",
    "question": "Which innovation will have the greatest impact on healthcare?",
    "topicLabel": "Healthcare innovation",
    "totalVotes": 2,
    "myOptionId": "7a1c0001-0000-4000-8000-000000000011",
    "options": [
      {"id": "7a1c0001-0000-4000-8000-000000000011", "label": "Artificial Intelligence", "voteCount": 2, "percent": 100},
      {"id": "7a1c0001-0000-4000-8000-000000000012", "label": "Personalized Nutrition", "voteCount": 0, "percent": 0},
      {"id": "7a1c0001-0000-4000-8000-000000000013", "label": "Digital Health", "voteCount": 0, "percent": 0}
    ]
  }
}
''';

  test('HttpPollsRepository parses an active poll', () async {
    final repository = HttpPollsRepository(
      tokenProvider: () => 'test-token',
      baseUrl: 'https://ntam-congress-api.onrender.com',
      send:
          ({
            required method,
            required uri,
            required headers,
            body,
            required timeout,
          }) async {
            expect(method, 'GET');
            expect(uri.path, '/api/polls/active');
            expect(headers['Authorization'], 'Bearer test-token');
            return const PollsHttpResponse(statusCode: 200, body: payload);
          },
    );

    final poll = await repository.getActive();
    expect(poll.question, contains('greatest impact on healthcare'));
    expect(poll.myOptionId, MockPollsRepository.aiId);
    expect(poll.totalVotes, 2);
    expect(poll.options, hasLength(3));
  });

  test('HttpPollsRepository maps 409 to an already-voted error', () async {
    final repository = HttpPollsRepository(
      tokenProvider: () => 'test-token',
      send:
          ({
            required method,
            required uri,
            required headers,
            body,
            required timeout,
          }) async {
            expect(method, 'POST');
            expect(uri.path, contains('/vote'));
            return const PollsHttpResponse(
              statusCode: 409,
              body:
                  '{"error":"You already voted in this poll.","code":"already_voted"}',
            );
          },
    );

    expect(
      () => repository.vote(
        pollId: MockPollsRepository.pollId,
        optionId: MockPollsRepository.digitalId,
      ),
      throwsA(
        isA<PollsException>().having(
          (error) => error.alreadyVoted,
          'alreadyVoted',
          isTrue,
        ),
      ),
    );
  });

  test('HttpPollsRepository parses the full poll list', () async {
    final repository = HttpPollsRepository(
      tokenProvider: () => 'test-token',
      send:
          ({
            required method,
            required uri,
            required headers,
            body,
            required timeout,
          }) async {
            expect(method, 'GET');
            expect(uri.path, '/api/polls');
            return const PollsHttpResponse(
              statusCode: 200,
              body:
                  '{"polls":[{"id":"7a1c0001-0000-4000-8000-000000000001","question":"Which innovation will have the greatest impact on healthcare?","topicLabel":"Healthcare innovation","totalVotes":0,"myOptionId":null,"options":[{"id":"7a1c0001-0000-4000-8000-000000000011","label":"Artificial Intelligence","voteCount":0,"percent":0}]},{"id":"7a1c0001-0000-4000-8000-000000000002","question":"Which topic would you most like to explore at a future medical congress?","topicLabel":"Future congress","totalVotes":0,"myOptionId":null,"options":[{"id":"7a1c0001-0000-4000-8000-000000000021","label":"Pediatric Nutrition","voteCount":0,"percent":0}]},{"id":"7a1c0001-0000-4000-8000-000000000003","question":"Which session format helps you learn most effectively?","topicLabel":"Learning format","totalVotes":0,"myOptionId":null,"options":[{"id":"7a1c0001-0000-4000-8000-000000000031","label":"Expert Panel Discussions","voteCount":0,"percent":0}]}]}',
            );
          },
    );

    final polls = await repository.list();
    expect(polls, hasLength(3));
    expect(polls.first.id, MockPollsRepository.pollId);
    expect(polls[1].id, MockPollsRepository.poll2Id);
    expect(polls[2].question, contains('session format'));
  });

  test('LivePoll.fromJson ignores a payload without options', () {
    expect(LivePoll.fromJson({'poll': {'id': 'x', 'question': 'Q'}}), isNull);
  });
}
