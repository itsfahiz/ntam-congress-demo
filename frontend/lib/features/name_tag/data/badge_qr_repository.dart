import 'package:flutter/widgets.dart';

class BadgeQrException implements Exception {
  const BadgeQrException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class BadgeQrRepository {
  Future<String> issueVerifyUrl();
}

class BadgeQrScope extends InheritedWidget {
  const BadgeQrScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final BadgeQrRepository repository;

  static BadgeQrRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BadgeQrScope>();
    assert(scope != null, 'BadgeQrScope not found in the widget tree.');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(BadgeQrScope oldWidget) {
    return repository != oldWidget.repository;
  }
}
