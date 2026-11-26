// fatto da Vuoler21
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/track.dart';
import '../../services/library_service.dart';
import '../../services/metadata_service.dart';
import '../widgets/loader.dart';

void showFixSheet(BuildContext c, Track t) =>
    showModalBottomSheet(context: c, isScrollControlled: true, builder: (_) => FixTrackSheet(track: t));

class FixTrackSheet extends StatefulWidget {
  final Track track;
  const FixTrackSheet({super.key, required this.track});
  @override
  State<FixTrackSheet> createState() => _FixState();
}

class _FixState extends State<FixTrackSheet> {
  late final q = TextEditingController(text: '${widget.track.title} ${widget.track.artist}');
  final svc = MetadataService();
  List<Candidate>? res;
  bool busy = false;
  String? err;

  Future<void> _search() async {
    setState(() { busy = true; err = null; });
    try {
      res = await svc.search(q.text);
    } catch (e) {
      err = '$e';
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _pick(Candidate c) async {
    setState(() => busy = true);
    try {
      await svc.apply(widget.track, c, context.read<LibraryService>());
    } catch (e) {
      err = '$e';
    }
    if (!mounted) return;
    if (err == null) {
      Navigator.pop(context);
    } else {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: MediaQuery.viewInsetsOf(context) + const EdgeInsets.all(16),
        child: SizedBox(
          height: 520,
          child: Column(children: [
            TextField(
                controller: q,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                    labelText: 'Cerca la canzone reale',
                    suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search))),
            if (err != null) Padding(padding: const EdgeInsets.all(8), child: Text(err!, style: const TextStyle(color: Colors.redAccent))),
            Expanded(
                child: busy
                    ? const Center(child: UiverseLoader(size: 56))
                    : ListView(children: [
                        for (final c in res ?? <Candidate>[])
                          ListTile(
                              leading: c.thumb == null
                                  ? const Icon(Icons.album)
                                  : Image.network(c.thumb!, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.album)),
                              title: Text(c.title),
                              subtitle: Text('${c.artist} · ${c.album}'),
                              trailing: Text(c.durationMs > 0 ? '${c.durationMs ~/ 60000}:${((c.durationMs ~/ 1000) % 60).toString().padLeft(2, '0')}' : ''),
                              onTap: () => _pick(c)),
                      ])),
          ]),
        ),
      );
}
