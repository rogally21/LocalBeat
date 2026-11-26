// fatto da Vuoler21
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/theme.dart';
import 'services/library_service.dart';
import 'services/player_service.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    JustAudioMediaKit.ensureInitialized();
  } else {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.vuoler21.localbeat.audio',
      androidNotificationChannelName: 'LocalBeat',
      androidNotificationOngoing: true,
    );
  }
  final lib = LibraryService();
  await lib.init();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: lib),
      ChangeNotifierProvider(create: (_) => PlayerService(lib)),
    ],
    child: const LocalBeatApp(),
  ));
}

class LocalBeatApp extends StatelessWidget {
  const LocalBeatApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'LocalBeat',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const Shell(),
      );
}
