import '../../app/app_routes.dart';
import '../auth/domain/attendee.dart';
import '../congress/data/congress_catalog.dart';
import '../saved/state/saved_items_controller.dart';
import 'data/assistant_models.dart';

const viewMyBadge = AssistantAction(
  label: 'View My Badge',
  route: AppRoutes.nameTag,
);
const viewAgenda = AssistantAction(
  label: 'View Agenda',
  route: AppRoutes.agenda,
);
const viewProfile = AssistantAction(
  label: 'View My Profile',
  route: AppRoutes.profile,
);
const viewSaved = AssistantAction(
  label: 'View Saved Items',
  route: AppRoutes.saved,
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
AssistantReply? localAssistantReply(
  String question,
  Attendee? attendee, {
  SavedItemsController? savedItems,
}) {
  final q = _norm(question);
  if (q.length < 2) return null;

  final name = attendee?.fullName.trim() ?? '';
  final email = attendee?.email.trim() ?? '';
  final badgeId = _badgeId(attendee);
  final phone = attendee?.phone.trim() ?? '';
  final storedPhone = phone.isEmpty || phone.toLowerCase() == 'not provided'
      ? null
      : phone;

  if (_isPhone(q)) {
    return _reply(
      attendee == null
          ? 'Sign in to view your saved phone number.'
          : storedPhone == null
              ? 'No phone number is saved in your profile yet. You can add one in Profile.'
              : 'Your saved mobile number is $storedPhone.',
      const [viewProfile],
    );
  }

  if (_isSaved(q) && savedItems != null) {
    if (savedItems.isLoading) {
      return _reply('Your saved items are still loading. Try again in a moment.', const [viewSaved]);
    }
    if (savedItems.error != null) {
      return _reply('I could not load your saved items. Open Saved Items to retry.', const [viewSaved]);
    }
    final sessions = CongressCatalog.sessions
        .where((session) => savedItems.isSaved('session', session.id))
        .map((session) => session.title)
        .toList();
    final resources = CongressCatalog.resources
        .where((resource) => savedItems.isSaved('resource', resource.id))
        .map((resource) => resource.title)
        .toList();
    final lines = <String>[
      'You have ${sessions.length} saved session(s) and ${resources.length} saved resource(s).',
      if (sessions.isNotEmpty) 'Sessions: ${sessions.join(', ')}.',
      if (resources.isNotEmpty) 'Resources: ${resources.join(', ')}.',
    ];
    return _reply(lines.join('\n'), const [viewSaved]);
  }

  if (_isOrganization(q)) {
    final organization = attendee?.organization.trim() ?? '';
    return _reply(
      organization.isEmpty
          ? 'No organization is saved in your profile.'
          : 'Your organization is $organization.',
      const [viewProfile],
    );
  }

  if (_isMyLocation(q)) {
    final location = attendee?.location.trim() ?? '';
    return _reply(
      location.isEmpty
          ? 'Your location is not available in your profile.'
          : 'Your profile location is $location.',
      const [viewProfile],
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
        ? 'For your attendee ID, open View My Badge.'
        : 'Your attendee ID is $badgeId.';
    final phoneLine = storedPhone == null
        ? 'No phone number is saved in your profile yet.'
        : 'Your saved mobile number is $storedPhone.';
    return _reply('$idLine $phoneLine', const [viewMyBadge, viewProfile]);
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
  final talksAboutPhone = q.contains('phone') || q.contains('mobile');
  if (!talksAboutPhone) return false;
  // Do not intercept general congress questions about mobile devices.
  return q.contains('my ') ||
      q.contains('mine') ||
      q.contains('profile') ||
      q.contains('contact number') ||
      q.contains('your phone');
}

bool _isSaved(String q) {
  return q.contains('my saved') ||
      q.contains('my bookmark') ||
      q.contains('i saved') ||
      q.contains('i bookmarked') ||
      q.contains('have i saved') ||
      q.contains('have i bookmarked') ||
      q.contains('saved items');
}

bool _isOrganization(String q) {
  return q.contains('my organization') ||
      q.contains('my organisation') ||
      q.contains('my hospital') ||
      q.contains('my workplace') ||
      q.contains('where do i work');
}

bool _isMyLocation(String q) {
  return q.contains('my location') ||
      q.contains('where am i based');
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
