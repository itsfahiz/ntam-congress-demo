import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../app/api_config.dart';
import '../domain/attendee.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    String? apiBaseUrl,
    this.timeout = const Duration(seconds: 20),
  }) : _apiBaseUrl = _trimBase(apiBaseUrl ?? ApiConfig.baseUrl);

  final String _apiBaseUrl;
  final Duration timeout;

  supabase.GoTrueClient get _auth => supabase.Supabase.instance.client.auth;

  static String _trimBase(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  @override
  String? get accessToken => _auth.currentSession?.accessToken;

  @override
  Future<Attendee?> restoreSession() async {
    final session = _auth.currentSession;
    if (session == null) return null;
    try {
      final json = await _api('GET', '/api/me', token: session.accessToken);
      return _attendeeFromProfile(json, session.user);
    } on AuthException {
      // Never overwrite existing PostgreSQL data during session restore.
      return _attendeeFromSession(session.user, fallbackName: 'Attendee');
    }
  }

  @override
  Future<Attendee> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final session = response.session;
      final user = response.user;
      if (session == null || user == null) {
        throw const AuthException(
          'Check your email to confirm the account before signing in.',
        );
      }
      return _loadOrCreateProfile(session);
    } on AuthException {
      rethrow;
    } on supabase.AuthException catch (error) {
      throw AuthException(_mapAuthError(error.message));
    } on SocketException {
      throw const AuthException(
        'Cannot reach authentication. Check Wi-Fi and try again.',
      );
    } catch (error) {
      throw AuthException(_mapAuthError(error.toString()));
    }
  }

  @override
  Future<Attendee> register(RegistrationDraft draft) async {
    try {
      final response = await _auth.signUp(
        email: draft.email.trim().toLowerCase(),
        password: draft.password,
        data: {
          'full_name': draft.fullName.trim(),
          'organization': draft.organization.trim(),
        },
      );
      final session = response.session;
      final user = response.user;
      if (user == null) {
        throw const AuthException('Could not create that attendee profile.');
      }
      if (session == null) {
        throw EmailConfirmationRequiredException(
          email: user.email ?? draft.email.trim().toLowerCase(),
        );
      }
      return _createProfile(session,
        fullName: draft.fullName.trim(),
        organization: draft.organization.trim(),
      );
    } on AuthException {
      rethrow;
    } on supabase.AuthException catch (error) {
      throw AuthException(_mapAuthError(error.message));
    } on SocketException {
      throw const AuthException(
        'Cannot reach authentication. Check Wi-Fi and try again.',
      );
    } catch (error) {
      throw AuthException(_mapAuthError(error.toString()));
    }
  }

  @override
  Future<void> signOut() {
    return _auth.signOut();
  }

  @override
  Future<Attendee> updateProfile({
    required String fullName,
    required String organization,
    required String phone,
  }) async {
    final session = _auth.currentSession;
    if (session == null) {
      throw const AuthException('Sign in to edit your profile.');
    }
    final json = await _api(
      'POST',
      '/api/me',
      token: session.accessToken,
      body: {
        'fullName': fullName.trim(),
        'organization': organization.trim(),
        'phone': phone.trim(),
      },
    );
    return _attendeeFromProfile(json, session.user);
  }

  Future<Attendee> _loadOrCreateProfile(supabase.Session session) async {
    try {
      final json = await _api('GET', '/api/me', token: session.accessToken);
      return _attendeeFromProfile(json, session.user);
    } on AuthException catch (error) {
      if (error.statusCode == 404) {
        return _createProfile(
          session,
          fullName: _metaName(session.user),
          organization: _metaOrg(session.user),
        );
      }
      // Existing session stays usable on temporary profile API failure.
      return _attendeeFromSession(
        session.user,
        fallbackName: 'Attendee',
      );
    }
  }

  Future<Attendee> _createProfile(
    supabase.Session session, {
    required String fullName,
    required String organization,
  }) async {
    try {
      final json = await _api(
        'POST',
        '/api/me',
        token: session.accessToken,
        body: {
          'fullName': fullName.isEmpty ? _metaName(session.user) : fullName,
          'organization': organization,
        },
      );
      return _attendeeFromProfile(json, session.user);
    } on AuthException {
      return _attendeeFromSession(session.user, fallbackName: fullName);
    }
  }

  Attendee _attendeeFromProfile(
    Map<String, dynamic> json,
    supabase.User user,
  ) {
    final profile = json['profile'];
    if (profile is! Map) {
      return _attendeeFromSession(user, fallbackName: 'Attendee');
    }
    final map = Map<String, dynamic>.from(profile);
    return Attendee(
      id: (map['badgeId'] as String?) ?? _badgeIdFor(user.id),
      fullName: (map['fullName'] as String?) ?? _metaName(user),
      email: (map['email'] as String?) ?? user.email ?? '',
      role: 'Medical Congress Attendee',
      organization: (map['organization'] as String?) ?? _metaOrg(user),
      phone: ((map['phone'] as String?) ?? '').isEmpty
          ? 'Not provided'
          : map['phone'] as String,
      location: 'Dubai, UAE',
    );
  }

  Attendee _attendeeFromSession(
    supabase.User user, {
    required String fallbackName,
  }) {
    final name = _metaName(user);
    return Attendee(
      id: _badgeIdFor(user.id),
      fullName: name.isEmpty ? fallbackName : name,
      email: user.email ?? '',
      role: 'Medical Congress Attendee',
      organization: _metaOrg(user),
      phone: 'Not provided',
      location: 'Dubai, UAE',
    );
  }

  static String _metaName(supabase.User user) {
    final metadata = user.userMetadata ?? {};
    return '${metadata['full_name'] ?? metadata['fullName'] ?? ''}'.trim();
  }

  static String _metaOrg(supabase.User user) {
    final metadata = user.userMetadata ?? {};
    return '${metadata['organization'] ?? ''}'.trim();
  }

  static String _badgeIdFor(String userId) {
    final compact = userId.replaceAll('-', '').toUpperCase();
    final slice = compact.padRight(8, '0').substring(0, 8);
    return 'NMC-$slice';
  }

  String _mapAuthError(String raw) {
    final message = raw.toLowerCase();
    if (message.contains('email not confirmed') ||
        message.contains('not confirmed')) {
      return 'Check your email to confirm the account before signing in.';
    }
    if (message.contains('invalid login') ||
        message.contains('invalid credentials')) {
      return 'Incorrect email or password.';
    }
    if (message.contains('already registered') ||
        message.contains('already been registered') ||
        message.contains('user already')) {
      return 'An attendee profile already exists for that email.';
    }
    if (message.contains('password')) {
      return 'Use a stronger password (at least 6 characters).';
    }
    if (message.contains('network') || message.contains('socket')) {
      return 'Cannot reach authentication. Check Wi-Fi and try again.';
    }
    return 'Unable to continue. Please try again.';
  }

  Future<Map<String, dynamic>> _api(
    String method,
    String path, {
    required String token,
    Map<String, dynamic>? body,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$_apiBaseUrl$path');
      final request = method == 'GET'
          ? await client.getUrl(uri).timeout(timeout)
          : await client.postUrl(uri).timeout(timeout);
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Accept', 'application/json');
      if (body != null) {
        request.headers.set('Content-Type', 'application/json');
        request.add(utf8.encode(jsonEncode(body)));
      }
      final response = await request.close().timeout(timeout);
      final raw = await utf8.decodeStream(response).timeout(timeout);
      Map<String, dynamic> json = const {};
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) json = Map<String, dynamic>.from(decoded);
      } on FormatException {
        json = const {};
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json;
      }
      throw AuthException(
        (json['error'] as String?) ??
            'Unable to load the attendee profile. Try again.',
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      throw const AuthException(
        'Cannot reach the congress API. Check Wi-Fi and that the backend is running.',
      );
    } on SocketException {
      throw const AuthException(
        'Cannot reach the congress API. Check Wi-Fi and that the backend is running.',
      );
    } finally {
      client.close(force: true);
    }
  }
}
