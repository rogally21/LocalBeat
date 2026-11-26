// fatto da Vuoler21
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/track.dart';
import 'library_service.dart';

class PlayerService extends ChangeNotifier {
  PlayerService(this.lib) {
    if (Platform.isAndroid) eq.setEnabled(true);
    player.currentIndexStream.listen((_) {
      final t = current;
      if (t != null) lib.markPlayed(t);
      notifyListeners();
    });
    player.playerStateStream.listen((_) => notifyListeners());
    player.positionStream.listen(_fade);
  }

  final LibraryService lib;
  final eq = AndroidEqualizer();
  late final player = AudioPlayer(
      audioPipeline: AudioPipeline(androidAudioEffects: [if (Platform.isAndroid) eq]));
  List<Track> queue = [];
  int crossfadeMs = 0;
  DateTime? sleepAt;
  Timer? _sleep;

  Track? get current {
    final i = player.currentIndex;
    return (i != null && i < queue.length) ? queue[i] : null;
  }

  AudioSource _src(Track t) => AudioSource.file(t.path,
      tag: MediaItem(
          id: '${t.id}',
          title: t.title,
          artist: t.artist,
          album: t.album,
          duration: Duration(milliseconds: t.durationMs),
          artUri: t.cover != null ? Uri.file(t.cover!) : null));

  Future<void> playQueue(List<Track> tracks, int index) async {
    queue = List.of(tracks);
    await player.setAudioSource(ConcatenatingAudioSource(children: [for (final t in tracks) _src(t)]),
        initialIndex: index);
    player.play();
    notifyListeners();
  }

  Future<void> addNext(Track t) async {
    if (queue.isEmpty) return playQueue([t], 0);
    final i = (player.currentIndex ?? -1) + 1;
    queue.insert(i, t);
    await (player.audioSource as ConcatenatingAudioSource).insert(i, _src(t));
    notifyListeners();
  }

  Future<void> enqueue(Track t) async {
    if (queue.isEmpty) return playQueue([t], 0);
    queue.add(t);
    await (player.audioSource as ConcatenatingAudioSource).add(_src(t));
    notifyListeners();
  }

  Future<void> moveInQueue(int o, int n) async {
    if (n > o) n--;
    await (player.audioSource as ConcatenatingAudioSource).move(o, n);
    queue.insert(n, queue.removeAt(o));
    notifyListeners();
  }

  Future<void> toggleShuffle() async =>
      player.setShuffleModeEnabled(!player.shuffleModeEnabled);

  Future<void> cycleRepeat() => player.setLoopMode(switch (player.loopMode) {
        LoopMode.off => LoopMode.all,
        LoopMode.all => LoopMode.one,
        LoopMode.one => LoopMode.off,
      });

  void sleepIn(Duration? d) {
    _sleep?.cancel();
    sleepAt = d == null ? null : DateTime.now().add(d);
    if (d != null) {
      _sleep = Timer(d, () {
        player.pause();
        sleepAt = null;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  // Crossfade: dissolvenza in uscita/ingresso del volume (gapless, singolo player)
  void _fade(Duration pos) {
    if (crossfadeMs <= 0) {
      if (player.volume != 1) player.setVolume(1);
      return;
    }
    final d = player.duration;
    if (d == null) return;
    final rem = (d - pos).inMilliseconds, x = pos.inMilliseconds;
    double v = 1;
    if (rem < crossfadeMs) {
      v = rem / crossfadeMs;
    } else if (x < crossfadeMs) {
      v = x / crossfadeMs;
    }
    player.setVolume(v.clamp(0.0, 1.0));
  }

  void setCrossfade(int ms) {
    crossfadeMs = ms;
    notifyListeners();
  }
}
