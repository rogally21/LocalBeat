// fatto da Vuoler21
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/track.dart';
import '../../services/library_service.dart';
import '../../services/player_service.dart';
import '../widgets/common.dart';

Future<String?> _ask(BuildContext c, String title, [String init = '']) {
  final ctl = TextEditingController(text: init);
  return showDialog<String>(
      context: c,
      builder: (_) => AlertDialog(
              title: Text(title),
              content: TextField(controller: ctl, autofocus: true),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annulla')),
                FilledButton(onPressed: () => Navigator.pop(c, ctl.text.trim()), child: const Text('OK')),
              ]));
}

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryService>();
    return SafeArea(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final n = await _ask(context, 'Nuova playlist');
            if (n != null && n.isNotEmpty) lib.createPlaylist(n);
          },
          child: const Icon(Icons.add)),
      body: ListView(children: [
        for (final p in lib.playlists)
          ListTile(
              leading: const Icon(Icons.queue_music_rounded),
              title: Text(p['name'] as String),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistDetail(id: p['id'] as int, name: p['name'] as String)))),
      ]),
    ));
  }
}

class PlaylistDetail extends StatefulWidget {
  final int id;
  final String name;
  const PlaylistDetail({super.key, required this.id, required this.name});
  @override
  State<PlaylistDetail> createState() => _PDState();
}

class _PDState extends State<PlaylistDetail> {
  List<Track> l = [];
  late String name = widget.name;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    l = await context.read<LibraryService>().playlistTracks(widget.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lib = context.read<LibraryService>();
    return Scaffold(
      appBar: AppBar(title: Text(name), actions: [
        IconButton(icon: const Icon(Icons.play_arrow_rounded), onPressed: () { if (l.isNotEmpty) context.read<PlayerService>().playQueue(l, 0); }),
        IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final n = await _ask(context, 'Rinomina', name);
              if (n != null && n.isNotEmpty) {
                await lib.renamePlaylist(widget.id, n);
                setState(() => name = n);
              }
            }),
        IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await lib.deletePlaylist(widget.id);
              if (context.mounted) Navigator.pop(context);
            }),
      ]),
      body: ReorderableListView.builder(
          itemCount: l.length,
          onReorder: (o, n) {
            if (n > o) n--;
            setState(() => l.insert(n, l.removeAt(o)));
            lib.reorderPlaylist(widget.id, l);
          },
          itemBuilder: (_, i) => Dismissible(
              key: ValueKey(l[i].id),
              onDismissed: (_) {
                lib.removeFromPlaylist(widget.id, l[i].id);
                l.removeAt(i);
              },
              background: Container(color: Colors.red.withValues(alpha: .4)),
              child: ListTile(
                  leading: Cover(l[i]),
                  title: Text(l[i].title),
                  subtitle: Text(l[i].artist),
                  trailing: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_handle)),
                  onTap: () => context.read<PlayerService>().playQueue(l, i)))),
    );
  }
}
