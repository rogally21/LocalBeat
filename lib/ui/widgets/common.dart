// fatto da Vuoler21
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/track.dart';
import '../../services/library_service.dart';
import 'loader.dart';

ImageProvider coverProvider(Track t) => t.cover != null && File(t.cover!).existsSync()
    ? FileImage(File(t.cover!))
    : const AssetImage('assets/logo.png');

class Cover extends StatelessWidget {
  final Track t;
  final double size;
  const Cover(this.t, {super.key, this.size = 48});
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(size * .2),
      child: Image(image: coverProvider(t), width: size, height: size, fit: BoxFit.cover));
}

String fmt(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

Future<void> runImport(BuildContext c, Future<int> Function() f) async {
  final nav = Navigator.of(c);
  showDialog(
      context: c,
      barrierDismissible: false,
      builder: (_) => const Center(child: UiverseLoader(size: 64)));
  var n = 0;
  try {
    n = await f();
  } finally {
    nav.pop();
  }
  if (c.mounted) {
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('$n brani importati')));
  }
}

Future<void> pickPlaylist(BuildContext c, Track t) async {
  final lib = c.read<LibraryService>();
  await showDialog(
      context: c,
      builder: (_) => SimpleDialog(title: const Text('Aggiungi a playlist'), children: [
            if (lib.playlists.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Crea prima una playlist')),
            for (final pl in lib.playlists)
              SimpleDialogOption(
                  child: Text(pl['name'] as String),
                  onPressed: () async {
                    await lib.addToPlaylist(pl['id'] as int, t.id);
                    if (c.mounted) Navigator.pop(c);
                  }),
          ]));
}
