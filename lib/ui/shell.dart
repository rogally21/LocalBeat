// fatto da Vuoler21
import 'package:flutter/material.dart';
import 'screens/home.dart';
import 'screens/library.dart';
import 'screens/playlists.dart';
import 'widgets/mini_player.dart';
import 'widgets/page_switcher.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final pc = PageController();
  int idx = 0;
  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.library_music_rounded, 'Libreria'),
    (Icons.queue_music_rounded, 'Playlist'),
  ];

  void _go(int i) {
    setState(() => idx = i);
    goPage(pc, i);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    final body = Column(children: [
      Expanded(
          child: PageSwitcher(
              controller: pc,
              onChanged: (i) => setState(() => idx = i),
              pages: const [HomeScreen(), LibraryScreen(), PlaylistsScreen()])),
      const MiniPlayer(),
    ]);
    return Scaffold(
      body: Row(children: [
        if (wide)
          NavigationRail(
              selectedIndex: idx,
              onDestinationSelected: _go,
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.transparent,
              destinations: [for (final e in _items) NavigationRailDestination(icon: Icon(e.$1), label: Text(e.$2))]),
        Expanded(child: body),
      ]),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: idx,
              onDestinationSelected: _go,
              backgroundColor: Colors.black.withValues(alpha: .4),
              destinations: [for (final e in _items) NavigationDestination(icon: Icon(e.$1), label: e.$2)]),
    );
  }
}
