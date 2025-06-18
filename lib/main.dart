import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tic_tac_zwo/app.dart';
import 'package:tic_tac_zwo/config/auth_config/auth_config.dart';
import 'package:tic_tac_zwo/features/wortschatz/data/models/saved_noun_hive.dart';
import 'package:tic_tac_zwo/hive/hive_registrar.g.dart';

import 'config/game_config/theme.dart';
import 'features/game/online/data/models/german_noun_hive.dart';
import 'features/navigation/routes/app_router.dart';
import 'features/navigation/routes/route_names.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AuthConfig.url,
    anonKey: AuthConfig.anonKey,
  );

  final Directory appDocumentDir = await getApplicationDocumentsDirectory();
  Hive
    ..init(appDocumentDir.path)
    ..registerAdapters();

  await Hive.openBox<GermanNounHive>('german_nouns');
  await Hive.openBox<SavedNounHive>('saved_nouns');
  await Hive.openBox('sync_info');
  await Hive.openBox('user_preferences');

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark));

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  // global key for scaffold messenger
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: RouteNames.home,
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: DataInitializationWrapper(
        child: const App(),
      ),
    );
  }
}
