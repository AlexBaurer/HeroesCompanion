import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_router.dart';
import 'app/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: HeroesCompanionApp()));
}

class HeroesCompanionApp extends StatelessWidget {
  const HeroesCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Герои — Помощник',
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
