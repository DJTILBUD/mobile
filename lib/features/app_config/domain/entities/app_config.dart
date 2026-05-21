/// Singleton row from the Supabase `AppConfig` table that drives
/// mobile-side force-update gating. All fields are nullable — admins
/// populate them via the admin tool. While a value is null, the mobile
/// app treats the corresponding gate as inactive.
class AppConfig {
  const AppConfig({
    this.iosMinVersion,
    this.androidMinVersion,
    this.iosLatestVersion,
    this.androidLatestVersion,
    this.iosAppStoreUrl,
    this.androidPlayStoreUrl,
    this.forceUpdateTitle,
    this.forceUpdateMessage,
    this.optionalUpdateTitle,
    this.optionalUpdateMessage,
  });

  final String? iosMinVersion;
  final String? androidMinVersion;
  final String? iosLatestVersion;
  final String? androidLatestVersion;
  final String? iosAppStoreUrl;
  final String? androidPlayStoreUrl;
  final String? forceUpdateTitle;
  final String? forceUpdateMessage;
  final String? optionalUpdateTitle;
  final String? optionalUpdateMessage;
}
