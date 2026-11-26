// fatto da Vuoler21
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/lrc.dart';
import '../../models/track.dart';
import '../../services/library_service.dart';
import '../../services/player_service.dart';

class LyricsView extends StatefulWidget {
  final Track track;
  const LyricsView({super.key, required this.track});
  @override
  State<LyricsView> createState() => _LState();
}

class _LState extends State<LyricsView> {
  static const h = 60.0;
  List<LrcLine> lines = [];
  int offsetMs = 0, cur = -1;
  final sc = ScrollController();

  @override
  void initState() {
    super.initState();
    var s = widget.track.lrc;
    if (s == null) { // fallback: file .lrc accanto al brano
      final f = File(widget.track.path.replaceFirst(RegExp(r'\.[^.]+$'), '.lrc'));
      if (f.existsSync()) s = f.readAsStringSync();
    }
    lines = s == null ? [] : parseLrc(s);
  }

  Future<void> _persist() => context.read<LibraryService>().saveLrc(widget.track, toLrc(lines));

  void _edit(int k, PlayerService pl) => showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
                title: const Text('Imposta la riga alla posizione attuale'),
                onTap: () {
                  setState(() => lines[k].t = pl.player.position);
                  _persist();
                  Navigator.pop(context);
                }),
            ListTile(
                title: const Text('−0,2 s'),
                onTap: () {
                  setState(() => lines[k].t -= const Duration(milliseconds: 200));
                  _persist();
                }),
            ListTile(
                title: const Text('+0,2 s'),
                onTap: () {
                  setState(() => lines[k].t += const Duration(milliseconds: 200));
                  _persist();
                }),
          ])));

  @override
  Widget build(BuildContext context) {
    final pl = context.read<PlayerService>();
    if (lines.isEmpty) {
      return const Center(child: Text('Nessun testo sincronizzato.\nUsa “Correggi brano” per scaricarlo.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)));
    }
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() => offsetMs -= 250)),
        Text('Offset ${(offsetMs / 1000).toStringAsFixed(2)}s'),
        IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => offsetMs += 250)),
        TextButton(
            onPressed: offsetMs == 0
                ? null
                : () {
                    for (final l in lines) {
                      l.t = Duration(milliseconds: max(0, l.t.inMilliseconds - offsetMs));
                    }
                    setState(() => offsetMs = 0);
                    _persist();
                  },
            child: const Text('Applica')),
      ]),
      Expanded(
          child: StreamBuilder<Duration>(
              stream: pl.player.positionStream,
              builder: (_, s) {
                final pos = (s.data ?? Duration.zero) + Duration(milliseconds: offsetMs);
                final i = lines.lastIndexWhere((l) => l.t <= pos);
                if (i != cur) {
                  cur = i;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (sc.hasClients) sc.animateTo(max(i, 0) * h, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
                  });
                }
                double f = 0;
                if (i >= 0) {
                  final end = i + 1 < lines.length ? lines[i + 1].t : lines[i].t + const Duration(seconds: 4);
                  f = ((pos - lines[i].t).inMilliseconds / max(1, (end - lines[i].t).inMilliseconds)).clamp(0.0, 1.0);
                }
                return LayoutBuilder(
                    builder: (_, bc) => ListView.builder(
                        controller: sc,
                        itemExtent: h,
                        padding: EdgeInsets.symmetric(vertical: max(0, bc.maxHeight / 2 - h / 2)),
                        itemCount: lines.length,
                        itemBuilder: (_, k) {
                          final active = k == i;
                          final txt = Text(lines[k].text,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: active ? 24 : 19, fontWeight: FontWeight.bold, color: Colors.white));
                          return InkWell(
                              onTap: () => pl.player.seek(Duration(milliseconds: max(0, lines[k].t.inMilliseconds - offsetMs))),
                              onLongPress: () => _edit(k, pl),
                              child: Center(
                                  child: active
                                      ? ShaderMask(
                                          blendMode: BlendMode.srcIn,
                                          shaderCallback: (r) => LinearGradient(colors: const [Colors.white, Colors.white38], stops: [f, f]).createShader(r),
                                          child: txt)
                                      : Opacity(opacity: .4, child: txt)));
                        }));
              })),
    ]);
  }
}
