class Attendee {
  const Attendee({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.organization,
    required this.phone,
    required this.location,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final String organization;
  final String phone;
  final String location;

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    if (parts.isEmpty) return 'NA';
    final letters = parts.take(2).map((part) => part[0].toUpperCase());
    return letters.join();
  }
}
