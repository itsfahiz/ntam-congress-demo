import 'assistant_models.dart';

abstract interface class AssistantRepository {
  Future<AssistantReply> ask(String question);
}
