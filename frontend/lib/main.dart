import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/congress_app.dart';
import 'app/supabase_config.dart';
import 'app/theme/app_colors.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/supabase_auth_repository.dart';
import 'features/auth/data/unconfigured_auth_repository.dart';
import 'features/auth/state/auth_controller.dart';
import 'features/name_tag/data/http_badge_qr_repository.dart';
import 'features/name_tag/data/mock_badge_qr_repository.dart';
import 'features/qa/data/http_questions_repository.dart';
import 'features/qa/data/mock_questions_repository.dart';
import 'features/saved/data/http_saved_items_repository.dart';
import 'features/saved/data/mock_saved_items_repository.dart';
import 'features/voting/data/http_polls_repository.dart';
import 'features/voting/data/mock_polls_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.navyDeep,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final authRepository = await _createAuthRepository();
  final authController = AuthController(authRepository);

  runApp(
    CongressApp(
      authController: authController,
      questionsRepository: authRepository is UnconfiguredAuthRepository
          ? MockQuestionsRepository()
          : HttpQuestionsRepository(
              tokenProvider: () => authController.accessToken ?? '',
            ),
      badgeQrRepository: authRepository is UnconfiguredAuthRepository
          ? MockBadgeQrRepository(
              badgeIdProvider: () => authController.attendee?.id ?? '',
            )
          : HttpBadgeQrRepository(
              tokenProvider: () => authController.accessToken ?? '',
            ),
      savedItemsRepository: authRepository is UnconfiguredAuthRepository
          ? MockSavedItemsRepository()
          : HttpSavedItemsRepository(
              tokenProvider: () => authController.accessToken ?? '',
            ),
      pollsRepository: authRepository is UnconfiguredAuthRepository
          ? MockPollsRepository()
          : HttpPollsRepository(
              tokenProvider: () => authController.accessToken ?? '',
            ),
    ),
  );
}

Future<AuthRepository> _createAuthRepository() async {
  if (!SupabaseConfig.isConfigured) {
    assert(() {
      debugPrint(
        'SUPABASE_URL / SUPABASE_ANON_KEY were not provided. '
        'Auth will not sign anyone in.',
      );
      return true;
    }());
    return UnconfiguredAuthRepository();
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );
  return SupabaseAuthRepository();
}
