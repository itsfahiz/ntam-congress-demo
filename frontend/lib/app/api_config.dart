/// Backend origin used by Congress AI, profile sync, Q&A, badge QR, and live polls.
///
/// Release builds default to the hosted Render API. Override at build/run time:
/// `flutter run --dart-define=API_BASE_URL=https://ntam-congress-api.onrender.com`
abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: bool.fromEnvironment('dart.vm.product')
        ? 'https://ntam-congress-api.onrender.com'
        : 'http://10.0.2.2:3000',
  );
}
