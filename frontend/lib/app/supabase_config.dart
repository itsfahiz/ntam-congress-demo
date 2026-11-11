abstract final class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hmlvjvemelgmselcagxe.supabase.co',
  );
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
