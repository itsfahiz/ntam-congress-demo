import 'package:flutter/material.dart';

enum SessionTrack { keynote, nutrition, research }

enum CongressDay { day1, day2 }

enum QuickAccessCategory { event, interactive, tools }

enum SessionGlyph { ceremony, talk, nutrition, research }

enum SpeakerFocus { nutrition, research, pediatrics }

class FeaturedEvent {
  const FeaturedEvent({
    required this.title,
    required this.dateLabel,
    required this.location,
  });

  final String title;
  final String dateLabel;
  final String location;
}

class CongressDayInfo {
  const CongressDayInfo({
    required this.day,
    required this.shortLabel,
    required this.dateShort,
    required this.headline,
    required this.dateLong,
  });

  final CongressDay day;
  final String shortLabel;
  final String dateShort;
  final String headline;
  final String dateLong;
}

class QuickAccessItem {
  const QuickAccessItem({
    required this.label,
    required this.description,
    required this.category,
    required this.icon,
    required this.route,
  });

  final String label;
  final String description;
  final QuickAccessCategory category;
  final IconData icon;
  final String route;

  String get categoryLabel => switch (category) {
    QuickAccessCategory.event => 'Event',
    QuickAccessCategory.interactive => 'Interactive',
    QuickAccessCategory.tools => 'Tools',
  };
}

class CongressSpeaker {
  const CongressSpeaker({
    required this.id,
    required this.fullName,
    required this.title,
    required this.country,
    required this.focuses,
    required this.bio,
    this.featured = false,
    this.listed = true,
  });

  final String id;
  final String fullName;
  final String title;
  final String country;
  final List<SpeakerFocus> focuses;
  final String bio;
  final bool featured;
  final bool listed;

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .where(
          (part) => !RegExp(r'^dr\.?$', caseSensitive: false).hasMatch(part),
        );
    if (parts.isEmpty) return 'NA';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  String get focusLabel => focuses
      .map(
        (focus) => switch (focus) {
          SpeakerFocus.nutrition => 'Nutrition',
          SpeakerFocus.research => 'Research',
          SpeakerFocus.pediatrics => 'Pediatrics',
        },
      )
      .join(' · ');
}

class VenueFacility {
  const VenueFacility({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class CongressVenue {
  const CongressVenue({
    required this.name,
    required this.dateLabel,
    required this.address,
    required this.addressDisclaimer,
    required this.facilities,
  });

  final String name;
  final String dateLabel;
  final String address;
  final String addressDisclaimer;
  final List<VenueFacility> facilities;
}

class CongressSession {
  const CongressSession({
    required this.id,
    required this.day,
    required this.title,
    required this.speakerId,
    required this.location,
    required this.timeLabel,
    required this.hour,
    required this.minute,
    required this.track,
    required this.glyph,
    required this.summary,
    this.highlighted = false,
  });

  final String id;
  final CongressDay day;
  final String title;
  final String speakerId;
  final String location;
  final String timeLabel;
  final int hour;
  final int minute;
  final SessionTrack track;
  final SessionGlyph glyph;
  final String summary;
  final bool highlighted;

  String get trackLabel => switch (track) {
    SessionTrack.keynote => 'Keynote',
    SessionTrack.nutrition => 'Nutrition',
    SessionTrack.research => 'Research',
  };

  String get period => hour >= 12 ? 'PM' : 'AM';

  String get clockLabel {
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  IconData get glyphIcon => switch (glyph) {
    SessionGlyph.ceremony => Icons.calendar_month_rounded,
    SessionGlyph.talk => Icons.mic_none_rounded,
    SessionGlyph.nutrition => Icons.eco_rounded,
    SessionGlyph.research => Icons.biotech_outlined,
  };
}

enum QuestionTopic { general, nutrition, research, clinical }

enum QuestionSort { popular, recent, answered }

enum ResourceKind { pdf, slides, video }

enum VoteCastResult { recorded, missingSelection, alreadyVoted }

class PollOption {
  const PollOption({
    required this.id,
    required this.label,
    required this.simulatedVotes,
  });

  final String id;
  final String label;
  final int simulatedVotes;
}

class CongressPoll {
  const CongressPoll({
    required this.id,
    required this.topicLabel,
    required this.question,
    required this.options,
  });

  final String id;
  final String topicLabel;
  final String question;
  final List<PollOption> options;
}

class CongressQuestion {
  const CongressQuestion({
    required this.id,
    required this.body,
    required this.topic,
    required this.authorName,
    required this.seedLikes,
    this.speakerId,
    this.answered = false,
    this.localSubmission = false,
  });

  final String id;
  final String body;
  final QuestionTopic topic;
  final String authorName;
  final int seedLikes;
  final String? speakerId;
  final bool answered;
  final bool localSubmission;

  String get topicLabel => switch (topic) {
    QuestionTopic.general => 'General',
    QuestionTopic.nutrition => 'Nutrition',
    QuestionTopic.research => 'Research',
    QuestionTopic.clinical => 'Clinical',
  };
}

class CongressResource {
  const CongressResource({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.body,
  });

  final String id;
  final String title;
  final String subtitle;
  final ResourceKind kind;
  final String body;

  String get kindLabel => switch (kind) {
    ResourceKind.pdf => 'PDF',
    ResourceKind.slides => 'SLIDES',
    ResourceKind.video => 'VIDEO',
  };

  String get availabilityLabel => switch (kind) {
    ResourceKind.video => 'Video is not bundled · demo outline',
    ResourceKind.pdf => 'Demo summary · not a downloadable file',
    ResourceKind.slides => 'Demo outline · not a slide deck file',
  };
}

class CongressExhibitor {
  const CongressExhibitor({
    required this.id,
    required this.name,
    required this.hall,
    required this.focus,
    required this.summary,
  });

  final String id;
  final String name;
  final String hall;
  final String focus;
  final String summary;
}
