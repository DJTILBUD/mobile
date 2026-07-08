import 'package:supabase_flutter/supabase_flutter.dart';

/// Mirrors the web-app's `chatRateLimit.ts`. The chat system enforces a
/// 100-messages-per-hour-per-user limit via a Postgres BEFORE INSERT trigger
/// (`check_message_rate_limit`) that raises an exception surfaced as a
/// PostgrestException with code "P0001". Detect it and show one shared friendly
/// Danish message instead of a raw error.
const String chatRateLimitMessage =
    'Du har sendt for mange beskeder på kort tid. Vent et øjeblik, og prøv igen.';

bool isChatRateLimitError(Object error) {
  if (error is PostgrestException) {
    if (error.code == 'P0001') return true;
    return error.message.toLowerCase().contains('rate limit');
  }
  return error.toString().toLowerCase().contains('rate limit');
}
