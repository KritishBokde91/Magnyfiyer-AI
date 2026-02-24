import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'theme/app_theme.dart';
import 'providers/chat_provider.dart';
import 'providers/theme_provider.dart';
import 'services/storage_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Window Manager (Linux Desktop) ────────────────────────────────────────
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1400, 900),
    minimumSize: Size(900, 600),
    center: true,
    title: 'Mercury AI',
    titleBarStyle: TitleBarStyle.normal,
    windowButtonVisibility: true,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setIcon('assets/images/mercury_ai.png');
    await windowManager.show();
    await windowManager.focus();
  });

  // ── Initialize Storage ────────────────────────────────────────────────────
  final storage = StorageService();
  await storage.init();

  runApp(NexusApp(storage: storage));
}

class NexusApp extends StatelessWidget {
  final StorageService storage;

  const NexusApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(storage: storage)),
        ChangeNotifierProvider(create: (_) => ChatProvider(storage: storage)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, _) {
          return MaterialApp(
            title: 'Mercury AI',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
