import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import '../data/repositories.dart';
import 'backup/onboarding_screen.dart';
import 'import/import_screen.dart';

import 'plan/week_screen.dart';
import 'recipes/recipe_book_screen.dart';
import 'settings/settings_screen.dart';
import 'shopping/shopping_screen.dart';

/// Brand colour, also the launcher icon background.
const brandColor = Color(0xFFE07A3F);

ThemeData buildTheme(Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: brandColor,
    brightness: brightness,
  ),
  useMaterial3: true,
);

class MiraiCookApp extends ConsumerWidget {
  const MiraiCookApp({super.key, this.home});

  /// Overrides the home widget (tests, onboarding).
  final Widget? home;

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'Mirai Cook',
    debugShowCheckedModeBanner: false,
    locale: const Locale('it'),
    supportedLocales: const [Locale('it')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    // UI-1, UI-2
    theme: buildTheme(Brightness.light),
    darkTheme: buildTheme(Brightness.dark),
    themeMode: ref.watch(themeModeProvider).value ?? ThemeMode.system,
    home: home ?? const StartupGate(),
  );
}

/// Shows onboarding on an empty first launch (DATA-14), else the app.
class StartupGate extends ConsumerWidget {
  const StartupGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(needsOnboardingProvider)) {
        AsyncData(value: true) => const OnboardingScreen(),
        AsyncData(value: false) || AsyncError() => const HomeShell(),
        _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
      };
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;
  StreamSubscription<String>? _shares;
  AppLifecycleListener? _lifecycle;

  void selectTab(int tab) => setState(() => _tab = tab);

  @override
  void initState() {
    super.initState();
    // IMP-1: shared URLs start an import.
    final source = ref.read(shareIntentSourceProvider);
    _shares = source.sharedTexts.listen(_onShared);
    source.takeInitialText().then((text) {
      if (text != null) _onShared(text);
    });
    // DATA-3: back up changed data when the app goes to background.
    _lifecycle = AppLifecycleListener(
      onHide: () => ref.read(backupControllerProvider).backupIfNeeded(),
    );
    _ensureDailyBackup();
  }

  Future<void> _ensureDailyBackup() async {
    final settings = ref.read(settingsRepositoryProvider);
    if (await settings.get(SettingKeys.backupAccount) != null) {
      await ref.read(backgroundSchedulerProvider)?.scheduleDailyBackup();
    }
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    _shares?.cancel();
    super.dispose();
  }

  void _onShared(String text) {
    if (!mounted) return;
    selectTab(1);
    openImport(context, text);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(changeTrackerProvider); // DATA-3
    final backupMissing =
        ref.watch(settingProvider(SettingKeys.backupAccount)).value == null;
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          WeekScreen(),
          RecipeBookScreen(),
          ShoppingScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: selectTab,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.calendar_view_week),
            label: 'Piano',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_book),
            label: 'Ricette',
          ),
          const NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Spesa',
          ),
          NavigationDestination(
            // DATA-13: badge while backup is not configured.
            icon: Badge(
              key: const Key('settings-badge'),
              isLabelVisible: backupMissing,
              child: const Icon(Icons.settings_outlined),
            ),
            label: 'Impostazioni',
          ),
        ],
      ),
    );
  }
}
