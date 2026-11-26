// fatto da Vuoler21
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/track.dart';
import '../../services/library_service.dart';
import '../../services/player_service.dart';
import '../widgets/common.dart';
import 'fix_track.dart';

class TrackTile extends StatelessWidget {
  final Track t;
  final List<Track> ctx;
  final int i;
  const TrackTile({super.key, required this.t, required this.ctx, required this.i});

  @override
  Widget build(BuildContext context) {
    final pl = context.read<PlayerService>();
    final lib = context.read<LibraryService>();
    return ListTile(
      leading: Cover(t),
      title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${t.artist} · ${t.album}', maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => pl.playQueue(ctx, i),
      onLongPress: () { // long-press → riproduci dopo
        pl.addNext(t);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aggiunto in coda'), duration: Duration(seconds: 1)));
      },
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          switch (v) {
            case 'fav':
              lib.toggleFav(t);
            case 'q':
              pl.enqueue(t);
            case 'pl':
              pickPlaylist(context, t);
            case 'fix':
              showFixSheet(context, t);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'fav', child: Text(t.fav ? 'Rimuovi dai preferiti' : 'Aggiungi ai preferiti')),
          const PopupMenuItem(value: 'q', child: Text('Aggiungi in fondo alla coda')),
          const PopupMenuItem(value: 'pl', child: Text('Aggiungi a playlist')),
          const PopupMenuItem(value: 'fix', child: Text('Correggi brano')),
        ],
      ),
    );
  }
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryService>();
    return SafeArea(
        child: DefaultTabController(
            length: 3,
            child: Column(children: [
              const TabBar(tabs: [Tab(text: 'Brani'), Tab(text: 'Album'), Tab(text: 'Artisti')]),
              Expanded(
                  child: TabBarView(children: [
                ListView.builder(
                    itemCount: lib.tracks.length,
                    itemBuilder: (_, i) => TrackTile(t: lib.tracks[i], ctx: lib.tracks, i: i)),
                _Grouped(lib.tracks, (t) => t.album),
                _Grouped(lib.tracks, (t) => t.artist),
              ])),
            ])));
  }
}

class _Grouped extends StatelessWidget {
  final List<Track> tracks;
  final String Function(Track) by;
  const _Grouped(this.tracks, this.by);
  @override
  Widget build(BuildContext context) {
    final g = <String, List<Track>>{};
    for (final t in tracks) {
      (g[by(t)] ??= []).add(t);
    }
    final keys = g.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ListView.builder(
        itemCount: keys.length,
        itemBuilder: (_, i) {
          final l = g[keys[i]]!;
          return ListTile(
              leading: Cover(l.first),
              title: Text(keys[i]),
              subtitle: Text('${l.length} brani'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => Scaffold(
                          appBar: AppBar(title: Text(keys[i])),
                          body: ListView.builder(
                              itemCount: l.length,
                              itemBuilder: (_, k) => TrackTile(t: l[k], ctx: l, i: k))))));
        });
  }
}
