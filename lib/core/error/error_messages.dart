import 'package:dj_tilbud_app/core/error/app_exception.dart';

/// The catch-all message shown when we have nothing more specific to say.
const String kGenericErrorMessage = 'Noget gik galt. Prøv igen senere.';

/// Converts any thrown error into a simple, non-technical Danish message that is
/// safe to show a DJ or saxophonist. It never exposes raw exceptions, status
/// codes, stack traces or server/database details.
///
/// Use this everywhere an error is shown to the user (toasts, error views).
/// For the few flows that want to surface a specific server reason (e.g. why a
/// bid was rejected), read `AppException.message` directly instead — those
/// messages are authored in Danish on the server.
String friendlyErrorMessage(Object? error, {String? fallback}) {
  final generic = fallback ?? kGenericErrorMessage;

  if (error is AgentLimitException) {
    return error.limitType == 'daily'
        ? 'Du har brugt dagens AI-forslag. Prøv igen i morgen.'
        : 'Du har brugt månedens AI-forslag.';
  }
  if (error is NoMusicianProfileException) {
    return error.message;
  }
  if (error is NetworkException) {
    return 'Der er problemer med forbindelsen. Tjek dit internet, og prøv igen.';
  }
  if (error is DatabaseException) {
    // The inner message may be raw server/database text — never surface it here.
    return fallback ?? 'Kunne ikke hente data. Prøv igen.';
  }
  if (error is AuthException) {
    // Auth messages are authored in Danish (see auth_repository_impl).
    return error.message.isNotEmpty ? error.message : generic;
  }
  if (error is AppException) {
    return error.message.isNotEmpty ? error.message : generic;
  }

  return generic;
}
