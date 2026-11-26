// fatto da Vuoler21
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:audiotags/audiotags.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/track.dart';
import 'library_service.dart';

class Candidate {
  final String title, artist, album;
  final int durationMs;
  final String? releaseId;
  Candidate(this.title, this.artist, this.album, this.durationMs, this.releaseId);
  String? get thumb => releaseId == null ? null : 'https://coverartarchive.org/release/$releaseId/front-250';
}

class MetadataService {
  static const _h = {'User-Agent': 'LocalBeat/1.0 (https://github.com/vuoler21)'};

  Future<List<Candidate>> search(String q) async {
    final r = await http.get(
        Uri.https('musicbrainz.org', '/ws/2/recording', {'query': q, 'fmt': 'json', 'limit': '15'}),
        headers: _h);
    if (r.statusCode != 200) throw Exception('MusicBrainz ${r.statusCode}');
    final j = jsonDecode(r.body);
    return [
      for (final x in j['recordings'] as List)
        () {
          final rel = ((x['releases'] as List?) ?? []).firstOrNull as Map?;
          return Candidate(
              x['title'] as String,
              ((x['artist-credit'] as List?) ?? []).map((a) => a['name']).join(', '),
              (rel?['title'] as String?) ?? '',
              (x['length'] as int?) ?? 0,
              rel?['id'] as String?);
        }()
    ];
  }

  Future<String?> lyrics(Candidate c) async {
    final q = {
      'track_name': c.title,
      'artist_name': c.artist.split(',').first.trim(),
      'album_name': c.album,
      if (c.durationMs > 0) 'duration': '${c.durationMs ~/ 1000}',
    };
    final r = await http.get(Uri.https('lrclib.net', '/api/get', q), headers: _h);
    if (r.statusCode == 200) {
      final s = jsonDecode(r.body)['syncedLyrics'];
      if (s is String && s.isNotEmpty) return s;
    }
    final r2 = await http.get(Uri.https('lrclib.net', '/api/search', {'q': '${c.title} ${c.artist}'}), headers: _h);
    if (r2.statusCode == 200) {
      for (final x in jsonDecode(r2.body)) {
        final s = x['syncedLyrics'];
        if (s is String && s.isNotEmpty) return s;
      }
    }
    return null;
  }

  Future<void> apply(Track t, Candidate c, LibraryService lib) async {
    Uint8List? img;
    if (c.releaseId != null) {
      final r = await http.get(Uri.parse('https://coverartarchive.org/release/${c.releaseId}/front-1200'), headers: _h);
      if (r.statusCode == 200) img = r.bodyBytes;
    }
    final lrc = await lyrics(c);
    t
      ..title = c.title
      ..artist = c.artist
      ..album = c.album
      ..lrc = lrc ?? t.lrc;
    if (c.durationMs > 0) t.durationMs = c.durationMs;
    if (img != null) {
      final f = File(p.join((await getApplicationSupportDirectory()).path, 'covers',
          '${t.id}_${DateTime.now().millisecondsSinceEpoch}.jpg'));
      await f.create(recursive: true);
      await f.writeAsBytes(img);
      t.cover = f.path;
    }
    try {
      await AudioTags.write(
          t.path,
          Tag(
              title: c.title,
              trackArtist: c.artist,
              album: c.album,
              pictures: img == null
                  ? []
                  : [Picture(bytes: img, mimeType: MimeType.jpeg, pictureType: PictureType.coverFront)]));
    } catch (_) {} // scrittura nel file può fallire (permessi): il DB resta comunque corretto
    await lib.save(t);
  }
}
