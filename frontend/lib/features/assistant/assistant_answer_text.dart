import 'package:flutter/material.dart';

final _boldPattern = RegExp(r'\*\*([^*]+)\*\*');

/// Turns `**bold**` markers into bold [TextSpan]s and keeps other text,
/// including newlines, as-is.
List<TextSpan> assistantAnswerSpans(String answer) {
  if (answer.isEmpty) {
    return const [TextSpan(text: '')];
  }

  final spans = <TextSpan>[];
  var start = 0;
  for (final match in _boldPattern.allMatches(answer)) {
    if (match.start > start) {
      spans.add(TextSpan(text: answer.substring(start, match.start)));
    }
    spans.add(
      TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
    start = match.end;
  }
  if (start < answer.length) {
    spans.add(TextSpan(text: answer.substring(start)));
  }
  if (spans.isEmpty) {
    spans.add(TextSpan(text: answer));
  }
  return spans;
}

class AssistantAnswerText extends StatelessWidget {
  const AssistantAnswerText(this.answer, {super.key, this.style});

  final String answer;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(style: style, children: assistantAnswerSpans(answer)),
    );
  }
}
