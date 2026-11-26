// fatto da Vuoler21
class LrcLine {
  Duration t;
  String text;
  LrcLine(this.t, this.text);
}

/// Supporta LRC standard e "enhanced" (i tag <mm:ss.xx> per parola vengono ignorati,
/// l'evidenziazione parola-per-parola è interpolata sulla durata della riga).
List<LrcLine> parseLrc(String s) {
  final re = RegExp(r'\[(\d+):(\d+(?:\.\d+)?)\]');
  final out = <LrcLine>[];
  for (final line in s.split('\n')) {
    final ms = re.allMatches(line).toList();
    if (ms.isEmpty) continue;
    final text = line.replaceAll(re, '').replaceAll(RegExp(r'<[^>]*>'), '').trim();
    for (final m in ms) {
      final sec = int.parse(m[1]!) * 60 + double.parse(m[2]!);
      out.add(LrcLine(Duration(milliseconds: (sec * 1000).round()), text));
    }
  }
  out.sort((a, b) => a.t.compareTo(b.t));
  return out;
}

String toLrc(List<LrcLine> l) => l.map((e) {
      final m = e.t.inMinutes.toString().padLeft(2, '0');
      final s = ((e.t.inMilliseconds % 60000) / 1000).toStringAsFixed(2).padLeft(5, '0');
      return '[$m:$s]${e.text}';
    }).join('\n');
