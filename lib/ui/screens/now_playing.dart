// fatto da Vuoler21
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../services/library_service.dart';
import '../../services/player_service.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/loader.dart';
import 'fix_track.dart';
import 'lyrics_view.dart';

class NowPlaying extends StatefulWidget {
  const NowPlaying({super.key});
  @override
  State<NowPlaying> createState() => _NPState();
}

class _NPState extends State<NowPlaying> {
  bool lyrics = false;

  @override
  Widget build(BuildContext context) {
    final pl = context.watch<PlayerService>();
    final t = pl.current;
    if (t == null) return const Scaffold();
    final w = min(MediaQuery.sizeOf(context).width - 80, 360.0);
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Opacity(opacity: .5, child: Image(image: coverProvider(t), fit: BoxFit.cover))),
        Container(color: Colors.black.withValues(alpha: .35)),
        SafeArea(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(children: [
                          Row(children: [
                            IconButton(icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32), onPressed: () => Navigator.pop(context)),
                            const Spacer(),
                            IconButton(icon: Icon(Icons.lyrics_rounded, color: lyrics ? Colors.white : Colors.white54), onPressed: () => setState(() => lyrics = !lyrics)),
                            IconButton(icon: const Icon(Icons.auto_fix_high_rounded), tooltip: 'Correggi brano', onPressed: () => showFixSheet(context, t)),
                          ]),
                          Expanded(
                              child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: lyrics
                                      ? LyricsView(key: ValueKey('l${t.id}${t.lrc.hashCode}'), track: t)
                                      : GestureDetector(
                                          key: const ValueKey('cover'),
                                          onHorizontalDragEnd: (d) => (d.primaryVelocity ?? 0) < 0 ? pl.player.seekToNext() : pl.player.seekToPrevious(),
                                          child: Center(child: Glass(radius: 32, padding: const EdgeInsets.all(10), child: Cover(t, size: w)))))),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              Text(t.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60)),
                            ])),
                            IconButton(
                                icon: Icon(t.fav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: t.fav ? Colors.pinkAccent : null),
                                onPressed: () => context.read<LibraryService>().toggleFav(t)),
                          ]),
                          StreamBuilder<Duration>(
                              stream: pl.player.positionStream,
                              builder: (_, s) {
                                final pos = s.data ?? Duration.zero;
                                final dur = pl.player.duration ?? Duration(milliseconds: t.durationMs);
                                final mx = max(1, dur.inMilliseconds).toDouble();
                                return Row(children: [
                                  Text(fmt(pos), style: const TextStyle(fontSize: 12)),
                                  Expanded(child: Slider(value: pos.inMilliseconds.toDouble().clamp(0.0, mx), max: mx, onChanged: (v) => pl.player.seek(Duration(milliseconds: v.toInt())))),
                                  Text(fmt(dur), style: const TextStyle(fontSize: 12)),
                                ]);
                              }),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                            StreamBuilder<bool>(
                                stream: pl.player.shuffleModeEnabledStream,
                                builder: (_, s) => IconButton(icon: Icon(Icons.shuffle_rounded, color: s.data == true ? Colors.greenAccent : Colors.white54), onPressed: pl.toggleShuffle)),
                            IconButton(iconSize: 40, icon: const Icon(Icons.skip_previous_rounded), onPressed: pl.player.seekToPrevious),
                            StreamBuilder<PlayerState>(
                                stream: pl.player.playerStateStream,
                                builder: (_, s) {
                                  final playing = s.data?.playing == true;
                                  return IconButton.filled(
                                      iconSize: 44,
                                      icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                      onPressed: playing ? pl.player.pause : pl.player.play);
                                }),
                            IconButton(iconSize: 40, icon: const Icon(Icons.skip_next_rounded), onPressed: pl.player.seekToNext),
                            StreamBuilder<LoopMode>(
                                stream: pl.player.loopModeStream,
                                builder: (_, s) {
                                  final m = s.data ?? LoopMode.off;
                                  return IconButton(
                                      icon: Icon(m == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded, color: m == LoopMode.off ? Colors.white54 : Colors.greenAccent),
                                      onPressed: pl.cycleRepeat);
                                }),
                          ]),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                            IconButton(icon: const Icon(Icons.queue_music_rounded), onPressed: () => _queue(context)),
                            IconButton(icon: Icon(Icons.bedtime_rounded, color: pl.sleepAt != null ? Colors.amber : null), onPressed: () => _options(context)),
                          ]),
                        ]))))),
      ]),
    );
  }

  void _queue(BuildContext c) => showModalBottomSheet(
      context: c,
      builder: (_) => Consumer<PlayerService>(
          builder: (_, pl, __) => ReorderableListView.builder(
              itemCount: pl.queue.length,
              onReorder: pl.moveInQueue,
              itemBuilder: (_, i) => ListTile(
                  key: ValueKey('${pl.queue[i].id}_$i'),
                  selected: i == pl.player.currentIndex,
                  leading: Cover(pl.queue[i], size: 40),
                  title: Text(pl.queue[i].title, maxLines: 1),
                  onTap: () => pl.player.seek(Duration.zero, index: i)))));

  void _options(BuildContext c) => showModalBottomSheet(
      context: c,
      builder: (_) => Consumer<PlayerService>(
          builder: (_, pl, __) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Sleep timer'),
                Wrap(spacing: 8, children: [
                  for (final m in [null, 15, 30, 60])
                    ChoiceChip(
                        label: Text(m == null ? 'Off' : '$m min'),
                        selected: m == null && pl.sleepAt == null,
                        onSelected: (_) => pl.sleepIn(m == null ? null : Duration(minutes: m))),
                ]),
                const SizedBox(height: 16),
                Text('Crossfade: ${pl.crossfadeMs ~/ 1000}s'),
                Slider(value: pl.crossfadeMs / 1000, max: 12, divisions: 12, onChanged: (v) => pl.setCrossfade((v * 1000).round())),
                if (Theme.of(c).platform == TargetPlatform.android)
                  FilledButton.tonal(
                      onPressed: () {
                        Navigator.pop(c);
                        _eq(c);
                      },
                      child: const Text('Equalizzatore')),
              ]))));

  void _eq(BuildContext c) {
    final pl = c.read<PlayerService>();
    showModalBottomSheet(
        context: c,
        builder: (_) => FutureBuilder(
            future: pl.eq.parameters,
            builder: (_, s) {
              if (!s.hasData) return const Center(child: UiverseLoader());
              final p = s.data!;
              return ListView(padding: const EdgeInsets.all(16), children: [
                for (final b in p.bands)
                  StreamBuilder<double>(
                      stream: b.gainStream,
                      initialData: b.gain,
                      builder: (_, g) => Row(children: [
                            SizedBox(width: 64, child: Text('${b.centerFrequency ~/ 1000} Hz')),
                            Expanded(child: Slider(min: p.minDecibels, max: p.maxDecibels, value: g.data!.clamp(p.minDecibels, p.maxDecibels), onChanged: b.setGain)),
                          ])),
              ]);
            }));
  }
}
