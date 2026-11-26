// fatto da Vuoler21
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/track.dart';
import '../../services/library_service.dart';
import '../../services/player_service.dart';
import '../widgets/common.dart';
import 'library.dart' show TrackTile;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _row(BuildContext c, String title, List<Track> l) {
    if (l.isEmpty) return const SizedBox.shrink();
    final pl = c.read<PlayerService>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(0, 20, 0, 10), child: Text(title, style: Theme.of(c).textTheme.titleLarge)),
      SizedBox(
          height: 176,
          child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: l.length.clamp(0, 15),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => GestureDetector(
                  onTap: () => pl.playQueue(l, i),
                  child: SizedBox(
                      width: 128,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Cover(l[i], size: 128),
                        const SizedBox(height: 6),
                        Text(l[i].title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(l[i].artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ]))))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryService>();
    final recent = lib.recent;
    return SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Image.asset('assets/logo.png', width: 36),
        const SizedBox(width: 10),
        Text('LocalBeat', style: Theme.of(context).textTheme.headlineSmall),
        const Spacer(),
        IconButton(tooltip: 'Importa cartella', icon: const Icon(Icons.create_new_folder_rounded), onPressed: () => runImport(context, lib.importFolder)),
        IconButton(tooltip: 'Importa file', icon: const Icon(Icons.library_add_rounded), onPressed: () => runImport(context, lib.importFiles)),
        PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'b') {
                final p = await lib.backup();
                if (context.mounted && p != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup: $p')));
              } else {
                await lib.restore();
              }
            },
            itemBuilder: (_) => const [
                  PopupMenuItem(value: 'b', child: Text('Backup libreria')),
                  PopupMenuItem(value: 'r', child: Text('Ripristina libreria')),
                ]),
      ]),
      if (lib.tracks.isEmpty)
        const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(child: Text('Importa una cartella o dei file per iniziare.\nLocalBeat legge solo ciò che scegli tu.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)))),
      _row(context, 'Ascoltati di recente', recent),
      _row(context, 'Preferiti', lib.favs),
      if (recent.isNotEmpty) ...[
        Padding(padding: const EdgeInsets.fromLTRB(0, 20, 0, 6), child: Text('Cronologia', style: Theme.of(context).textTheme.titleLarge)),
        for (var i = 0; i < recent.length.clamp(0, 20); i++) TrackTile(t: recent[i], ctx: recent, i: i),
      ],
    ]));
  }
}
