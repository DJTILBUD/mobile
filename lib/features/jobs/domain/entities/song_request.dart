class SongRequest {
  const SongRequest({
    required this.id,
    required this.jobId,
    required this.guestEmail,
    required this.song1,
    this.song2,
    this.song3,
    required this.createdAt,
  });

  final int id;
  final int jobId;
  final String guestEmail;
  final String song1;
  final String? song2;
  final String? song3;
  final DateTime createdAt;

  List<String> get songs => [song1, if (song2 != null) song2!, if (song3 != null) song3!];
}
