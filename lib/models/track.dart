// fatto da Vuoler21
class Track {
  final int id;
  final String path;
  String title, artist, album;
  int durationMs, plays, last;
  String? cover, lrc;
  bool fav;
  Track({required this.id, required this.path, required this.title, required this.artist,
      required this.album, required this.durationMs, this.cover, this.lrc,
      this.fav = false, this.plays = 0, this.last = 0});

  factory Track.fromMap(Map<String, Object?> m) => Track(
        id: m['id'] as int,
        path: m['path'] as String,
        title: m['title'] as String,
        artist: m['artist'] as String,
        album: m['album'] as String,
        durationMs: m['duration'] as int,
        cover: m['cover'] as String?,
        lrc: m['lrc'] as String?,
        fav: (m['fav'] as int) == 1,
        plays: m['plays'] as int,
        last: m['last'] as int,
      );
}
