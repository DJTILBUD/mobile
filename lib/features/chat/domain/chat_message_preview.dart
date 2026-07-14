/// One-line text representing a chat message in a NON-message context — the
/// conversation-list preview (and, server-side, the push body).
///
/// An image-only message has empty text + a non-null `attachmentUrl`, which used
/// to render as a blank preview. Fall back to a Danish "sent an image" label.
///
/// Mirror of web-app `src/helpers/chatMessagePreview.ts` (byte-identical label) —
/// change all copies together.
const String kImageMessagePreview = '📷 Har sendt et billede';

String chatMessagePreview(String? message, String? attachmentUrl) {
  final text = (message ?? '').trim();
  if (text.isNotEmpty) return text;
  if (attachmentUrl != null && attachmentUrl.isNotEmpty) {
    return kImageMessagePreview;
  }
  return '';
}
