import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/core/notifications/notifications_service.dart';

/// `extractReferenceId` used to feed analytics only, where a null was a lost row in a
/// funnel. It now also picks the `UserNotifications` row a tapped push marks read
/// (`NotificationsDatasource.markReadForPush` matches on type + reference_id), so a type
/// missing from its switch means the red badge survives the tap — the exact bug this
/// guards. Keep a case here for every type the sender writes a feed row for.
void main() {
  group('extractReferenceId', () {
    test('job-scoped types resolve to job_id', () {
      for (final type in [
        'new_job',
        'another_round',
        'ready_reminder',
        'extra_hours_reminder',
        'contact_customer_reminder',
        'send_invoice_reminder',
        'content_record_reminder',
        'content_upload_reminder',
        'content_accepted',
        'content_rejected',
      ]) {
        expect(
          NotificationsService.extractReferenceId({
            'type': type,
            'job_id': '41',
          }),
          '41',
          reason: '$type must resolve to its job id',
        );
      }
    });

    test('ext-job, quote, offer, chat and admin types resolve', () {
      expect(
        NotificationsService.extractReferenceId({
          'type': 'new_ext_job',
          'ext_job_id': '7',
        }),
        '7',
      );
      expect(
        NotificationsService.extractReferenceId({
          'type': 'ext_job_assigned',
          'ext_job_id': '7',
        }),
        '7',
      );
      expect(
        NotificationsService.extractReferenceId({
          'type': 'quote_won',
          'quote_id': '12',
        }),
        '12',
      );
      expect(
        NotificationsService.extractReferenceId({
          'type': 'offer_lost',
          'offer_id': '13',
        }),
        '13',
      );
      expect(
        NotificationsService.extractReferenceId({
          'type': 'chat_message',
          'conversation_id': '99',
        }),
        '99',
      );
      expect(
        NotificationsService.extractReferenceId({
          'type': 'admin_message',
          'message_id': '5',
        }),
        '5',
      );
    });

    test('song_request falls back from ext_job_id to job_id', () {
      expect(
        NotificationsService.extractReferenceId({
          'type': 'song_request',
          'ext_job_id': '7',
          'job_id': '41',
        }),
        '7',
      );
      expect(
        NotificationsService.extractReferenceId({
          'type': 'song_request',
          'job_id': '41',
        }),
        '41',
      );
    });

    test('a broadcast type has no reference — markReadForPush then clears only '
        'the newest row rather than the whole backlog', () {
      expect(
        NotificationsService.extractReferenceId({
          'type': 'custom_notification',
        }),
        isNull,
      );
    });
  });
}
