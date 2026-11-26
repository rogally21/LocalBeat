// fatto da Vuoler21
import 'dart:io';
import 'package:audiotags/audiotags.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import '../models/track.dart';

class LibraryService extends ChangeNotifier {
  late Database db;
  List<Track> tracks = [];
  List<Map<String, Object?>> playlists = [];
  static const exts = {'.mp3', '.flac', '.m4a', '.aac', '.ogg', '.opus', '.wav'};

  List<Track> get recent =>
      (tracks.where((t) => t.last > 0).toList()..sort((a, b) => b.last.compareTo(a.last)));
  List<Track> get favs => tracks.where((t) => t.fav).toList();

  Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    await _open(p.join(dir.path, 'localbeat.db'));
  }

  Future<void> _open(String path) async {
    db = await openDatabase(path, version: 1, onCreate: (d, _) async {
      await d.execute('CREATE TABLE tracks(id INTEGER PRIMARY KEY, path TEXT UNIQUE, title TEXT, artist TEXT, album TEXT, duration INTEGER, cover TEXT, lrc TEXT, fav INTEGER DEFAULT 0, plays INTEGER DEFAULT 0, last INTEGER DEFAULT 0)');
      await d.execute('CREATE TABLE playlists(id INTEGER PRIMARY KEY, name TEXT)');
      await d.execute('CREATE TABLE pl_tracks(pl INTEGER, track INTEGER, pos INTEGER)');
    });
    await reload();
  }

  Future<void> reload() async {
    tracks = (await db.query('tracks', orderBy: 'title COLLATE NOCASE')).map(Track.fromMap).toList();
    playlists = await db.query('playlists', orderBy: 'name COLLATE NOCASE');
    notifyListeners();
  }

  // ---- Import: SOLO ciò che l'utente seleziona ----
  Future<int> importFolder() async {
    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir == null) return 0;
    if (Platform.isAndroid) await Permission.audio.request();
    final paths = <String>[];
    await for (final e in Directory(dir).list(recursive: true, followLinks: false)) {
      if (e is File && exts.contains(p.extension(e.path).toLowerCase())) paths.add(e.path);
    }
    return _addAll(paths);
  }

  Future<int> importFiles() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: true);
    if (r == null) return 0;
    final paths = <String>[];
    for (final f in r.files) {
      if (f.path != null) paths.add(await _persist(f.path!));
    }
    return _addAll(paths);
  }

  // Android: file_picker copia in cache → copio nella cartella dell'app per non perderli
  Future<String> _persist(String path) async {
    if (!Platform.isAndroid) return path;
    final d = Directory(p.join((await getApplicationSupportDirectory()).path, 'music'))
      ..createSync(recursive: true);
    final dst = p.join(d.path, p.basename(path));
    if (path != dst) await File(path).copy(dst);
    return dst;
  }

  Future<int> _addAll(List<String> paths) async {
    final cdir = Directory(p.join((await getApplicationSupportDirectory()).path, 'covers'))
      ..createSync(recursive: true);
    var n = 0;
    for (final path in paths) {
      try {
        final tag = await AudioTags.read(path);
        String? cover;
        if (tag != null && tag.pictures.isNotEmpty) {
          cover = p.join(cdir.path, '${path.hashCode}.jpg');
          File(cover).writeAsBytesSync(tag.pictures.first.bytes);
        }
        final id = await db.insert(
            'tracks',
            {
              'path': path,
              'title': (tag?.title?.trim().isNotEmpty ?? false) ? tag!.title : p.basenameWithoutExtension(path),
              'artist': tag?.trackArtist ?? 'Artista sconosciuto',
              'album': tag?.album ?? 'Album sconosciuto',
              'duration': (tag?.duration ?? 0) * 1000,
              'cover': cover,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore);
        if (id > 0) n++;
      } catch (_) {}
    }
    await reload();
    return n;
  }

  // ---- Brani ----
  Future<void> save(Track t) async {
    await db.update('tracks',
        {'title': t.title, 'artist': t.artist, 'album': t.album, 'duration': t.durationMs, 'cover': t.cover, 'lrc': t.lrc},
        where: 'id=?', whereArgs: [t.id]);
    await reload();
  }

  Future<void> saveLrc(Track t, String lrc) async {
    t.lrc = lrc;
    await save(t);
  }

  Future<void> toggleFav(Track t) async {
    t.fav = !t.fav;
    await db.update('tracks', {'fav': t.fav ? 1 : 0}, where: 'id=?', whereArgs: [t.id]);
    notifyListeners();
  }

  Future<void> markPlayed(Track t) async {
    t.plays++;
    t.last = DateTime.now().millisecondsSinceEpoch;
    await db.update('tracks', {'plays': t.plays, 'last': t.last}, where: 'id=?', whereArgs: [t.id]);
    notifyListeners();
  }

  // ---- Playlist ----
  Future<void> createPlaylist(String n) async { await db.insert('playlists', {'name': n}); await reload(); }
  Future<void> renamePlaylist(int id, String n) async { await db.update('playlists', {'name': n}, where: 'id=?', whereArgs: [id]); await reload(); }
  Future<void> deletePlaylist(int id) async {
    await db.delete('playlists', where: 'id=?', whereArgs: [id]);
    await db.delete('pl_tracks', where: 'pl=?', whereArgs: [id]);
    await reload();
  }

  Future<List<Track>> playlistTracks(int pl) async => (await db.rawQuery(
          'SELECT t.* FROM tracks t JOIN pl_tracks p ON p.track=t.id WHERE p.pl=? ORDER BY p.pos', [pl]))
      .map(Track.fromMap).toList();

  Future<void> addToPlaylist(int pl, int tr) async {
    final c = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pl_tracks WHERE pl=?', [pl]))!;
    await db.insert('pl_tracks', {'pl': pl, 'track': tr, 'pos': c});
  }

  Future<void> removeFromPlaylist(int pl, int tr) =>
      db.delete('pl_tracks', where: 'pl=? AND track=?', whereArgs: [pl, tr]);

  Future<void> reorderPlaylist(int pl, List<Track> ordered) async {
    final b = db.batch();
    for (var i = 0; i < ordered.length; i++) {
      b.update('pl_tracks', {'pos': i}, where: 'pl=? AND track=?', whereArgs: [pl, ordered[i].id]);
    }
    await b.commit(noResult: true);
  }

  // ---- Backup / ripristino ----
  Future<String?> backup() async {
    final d = await FilePicker.platform.getDirectoryPath();
    if (d == null) return null;
    final dst = p.join(d, 'localbeat_backup_${DateTime.now().millisecondsSinceEpoch}.db');
    await File(db.path).copy(dst);
    return dst;
  }

  Future<void> restore() async {
    final r = await FilePicker.platform.pickFiles();
    if (r?.files.single.path == null) return;
    final path = db.path;
    await db.close();
    await File(r!.files.single.path!).copy(path);
    await _open(path);
  }
}
