// fatto da Vuoler21
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../services/player_service.dart';
import '../screens/now_player_route.dart';
import 'common.dart';
import 'glass.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});
  @override
  Widget build(BuildContext context) {
    final pl = context.watch<PlayerService>();
    final t = pl.current;
    if (t == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => openNowPlaying(context),
      onHorizontalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) < 0) {
          pl.player.seekToNext();
        } else {
          pl.player.seekToPrevious();
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Glass(
          radius: 22,
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Cover(t, size: 44),
            const SizedBox(width: 10),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(t.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ])),
            StreamBuilder<PlayerState>(
                stream: pl.player.playerStateStream,
                builder: (_, s) {
                  final playing = s.data?.playing == true;
                  return IconButton(
                      iconSize: 32,
                      icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      onPressed: playing ? pl.player.pause : pl.player.play);
                }),
            IconButton(icon: const Icon(Icons.skip_next_rounded), onPressed: pl.player.seekToNext),
          ]),
        ),
      ),
    );
  }
}
