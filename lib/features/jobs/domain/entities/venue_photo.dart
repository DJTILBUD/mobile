/// A venue photo on a partner (recurring customer) account, as served to a
/// performer by `GET /api/internal-dj/ext-jobs` (`venue_photos` per job).
///
/// Mirror of the web-app `VenuePhoto` type (`web-app/src/types/venuePhoto.ts`):
/// the image and the team's comment on it, nothing else leaves the server.
class VenuePhoto {
  const VenuePhoto({required this.id, required this.url, this.comment});

  final int id;
  final String url;

  /// What the DJ should know about this photo (where to stand, where the
  /// power is, ...). Null when the team wrote nothing.
  final String? comment;

  bool get hasComment => comment != null && comment!.trim().isNotEmpty;

  static VenuePhoto? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final url = json['url'];
    if (id is! int || url is! String || url.isEmpty) return null;
    final rawComment = json['comment'];
    return VenuePhoto(
      id: id,
      url: url,
      comment:
          rawComment is String && rawComment.trim().isNotEmpty
              ? rawComment
              : null,
    );
  }
}
