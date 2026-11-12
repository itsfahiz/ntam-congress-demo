import '../../app/app_routes.dart';
import '../auth/domain/attendee.dart';
import 'data/assistant_models.dart';

const viewMyBadge = AssistantAction(
  label: 'View My Badge',
  route: AppRoutes.nameTag,
);
const viewAgenda = AssistantAction(
  label: 'View Agenda',
  route: AppRoutes.agenda,
);
const viewVenue = AssistantAction(
  label: 'Venue/Directions',
  route: AppRoutes.venue,
);

String _norm(String question) {
  return question
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll(RegExp(r'[?!.,]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _badgeId(Attendee? attendee) {
  final id = attendee?.id.trim() ?? '';
  if (id.isEmpty) return '';
  if (!RegExp(r'^NMC-[A-Z0-9-]+$', caseSensitive: false).hasMatch(id)) {
    return '';
  }
  return id;
}

AssistantReply _reply(String answer, List<AssistantAction> actions) {
  return AssistantReply(
    answer: answer,
    grounded: false,
    sources: const [],
    actions: actions,
  );
}

/// Profile/navigation answers handled on-device. Null means use Gemini/RAG.
AssistantReply? localAssistantReply(String question, Attendee? attendee) {
  final q = _norm(question);
  if (q.length < 2) return null;

  final name = attendee?.fullName.trim() ?? '';
  final email = attendee?.email.trim() ?? '';
  final badgeId = _badgeId(attendee);

  if (_isPhone(q)) {
    return _reply(
      'A personal phone number is not stored on this attendee profile.',
      const [],
    );
  }

  if (_isBadge(q)) {
    final idLine = badgeId.isEmpty
        ? 'Open View My Badge for your signed QR. An attendee ID is shown there only when it is already issued.'
        : 'Your attendee ID is $badgeId. Open View My Badge for your signed QR.';
    return _reply(idLine, const [viewMyBadge]);
  }

  if (_isAmbiguousNumber(q)) {
    final idLine = badgeId.isEmpty
        ? 'If you mean your attendee ID, open View My Badge. A personal phone number is not stored on this profile.'
        : 'If you mean your attendee ID, it is $badgeId. A personal phone number is not stored on this profile.';
    return _reply(idLine, const [viewMyBadge]);
  }

  if (_isIdentity(q)) {
    final wantsName = q.contains('name') || q.contains('who am i');
    final wantsEmail = q.contains('email');
    final lines = <String>[];
    if (wantsName) {
      lines.add(
        name.isEmpty
            ? 'Your name is not available on this session.'
            : 'Your name is $name.',
      );
    }
    if (wantsEmail || !wantsName) {
      lines.add(
        email.isEmpty
            ? 'Your email is not available on this session.'
            : 'Your email is $email.',
      );
    }
    return _reply(lines.join('\n'), const []);
  }

  if (_isSchedule(q)) {
    return _reply(
      'Your congress programme is on the Agenda screen.',
      const [viewAgenda],
    );
  }

  if (_isAttend(q)) {
    return _reply(
      'Use the Agenda for sessions, My Badge for check-in, and Venue for directions.',
      const [viewAgenda, viewMyBadge, viewVenue],
    );
  }

  if (_isVenue(q)) {
    return _reply(
      'Open Venue for the location and directions. Get Directions is on that screen.',
      const [viewVenue],
    );
  }

  return null;
}

bool _isPhone(String q) {
  return q.contains('phone') || q.contains('mobile');
}

bool _isBadge(String q) {
  return q.contains('name tag') ||
      q.contains('attendee id') ||
      q.contains('badge') ||
      q.contains('qr') ||
      q.contains('ticket');
}

bool _isAmbiguousNumber(String q) {
  if (_isPhone(q) || _isBadge(q)) return false;
  return q.contains('my number') ||
      q.contains('whats my number') ||
      q.contains("what's my number");
}

bool _isIdentity(String q) {
  if (q.contains('name tag')) return false;
  final name = q.contains('my name') || q.contains('who am i');
  final email = q.contains('my email') || q.contains('email address');
  return name || email;
}

bool _isSchedule(String q) {
  return q.contains('my schedule') ||
      q.contains('my agenda') ||
      q.contains('show my schedule') ||
      q.contains('show the schedule') && q.contains('my');
}

bool _isAttend(String q) {
  return q.contains('how do i attend') ||
      q.contains('how to attend') ||
      q.contains('how can i attend') ||
      q.contains('how do i check in');
}

bool _isVenue(String q) {
  if (q.contains('facilit')) return false;
  return q.contains('where is the venue') ||
      q.contains('wheres the venue') ||
      q.contains('show the venue') ||
      q.contains('show me the venue') ||
      (q.contains('venue') && q.contains('directions'));
}
