import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/user_file.dart';
import 'package:dj_tilbud_app/features/profile/domain/sort_user_files.dart';

/// Mirror of web-app `src/helpers/sortUserFiles.test.ts` — keep the cases in sync.
UserFile file(int id, int? sortOrder) => UserFile(
  id: id,
  url: 'https://example.com/$id.jpg',
  type: UserFileType.common,
  createdAt: DateTime(2026, 1, 1),
  sortOrder: sortOrder,
);

void main() {
  group('sortUserFiles', () {
    test('orders by sortOrder ascending', () {
      final sorted = sortUserFiles([file(10, 3), file(11, 1), file(12, 2)]);
      expect(sorted.map((f) => f.id), [11, 12, 10]);
    });

    test('legacy rows with no sortOrder keep insert (id) order', () {
      final sorted = sortUserFiles([
        file(30, null),
        file(10, null),
        file(20, null),
      ]);
      expect(sorted.map((f) => f.id), [10, 20, 30]);
    });

    // The load-bearing rule: a new upload leaves sortOrder null and must APPEND to an already
    // ordered gallery. Treating null as 0 would put it first instead.
    test(
      'a newly uploaded (null) file sorts after explicitly ordered ones',
      () {
        final sorted = sortUserFiles([
          file(99, null),
          file(10, 2),
          file(11, 1),
        ]);
        expect(sorted.map((f) => f.id), [11, 10, 99]);
      },
    );

    test(
      'equal sortOrder falls back to id so the order is stable, never arbitrary',
      () {
        final sorted = sortUserFiles([file(20, 1), file(10, 1)]);
        expect(sorted.map((f) => f.id), [10, 20]);
      },
    );

    test('does not mutate the input list', () {
      final input = [file(10, 2), file(11, 1)];
      sortUserFiles(input);
      expect(input.map((f) => f.id), [10, 11]);
    });
  });
}
