import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _tab = 0;

  void selectTab(int tab) => setState(() => _tab = tab);

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
