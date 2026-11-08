import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import 'import/import_screen.dart';

import 'plan/week_screen.dart';
import 'recipes/recipe_book_screen.dart';
import 'settings/settings_screen.dart';
import 'shopping/shopping_screen.dart';

class MiraiCookApp extends StatelessWidget {
  const MiraiCookApp({super.key, this.home});

  /// Overrides the home widget (tests, onboarding).
  final Widget? home;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Mirai Cook',
    debugShowCheckedModeBanner: false,
    locale: const Locale('it'),
    supportedLocales: const [Locale('it')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      colorSchemeSeed: const Color(0xFFE07A3F),
      useMaterial3: true,
    ),
    home: home ?? const HomeShell(),
  );
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;
  StreamSubscription<String>? _shares;

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
  }

  @override
  void dispose() {
    _shares?.cancel();
    super.dispose();
  }

  void _onShared(String text) {
    if (!mounted) return;
    selectTab(1);
    openImport(context, text);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.calendar_view_week),
          label: 'Piano',
        ),
        NavigationDestination(icon: Icon(Icons.menu_book), label: 'Ricette'),
        NavigationDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          label: 'Spesa',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: 'Impostazioni',
        ),
      ],
    ),
  );
}
