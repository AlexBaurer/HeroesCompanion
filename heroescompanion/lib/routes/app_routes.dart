import 'package:flutter/material.dart';
import 'package:heroescompanion/features/main_menu/presentation/main_menu_screen.dart';
import 'package:heroescompanion/features/factions/faction_detail_screen.dart';
import 'package:heroescompanion/features/scores_bd/score_screen.dart';

class AppRoutes {
  static const String mainMenu = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case mainMenu:
        return MaterialPageRoute(builder: (_) => const MainMenuScreen());

      case '/faction':
        final args = settings.arguments as String?;
        if (args == null) {
          return _errorRoute('Не указана фракция');
        }
        return MaterialPageRoute(
          builder: (_) => FactionDetailScreen(factionName: args),
        );

      case '/score':
        final args = settings.arguments as String?;
        if (args == null) {
          return _errorRoute('Не указана фракция');
        }
        return MaterialPageRoute(
          builder: (_) => ScoreScreen(factionName: args),
        );

      default:
        return _errorRoute('Страница не найдена');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ошибка')),
        body: Center(child: Text(message)),
      );
    });
  }
}

// Заглушка для второго экрана
class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем переданный аргумент (название фракции)
    final String faction = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(title: Text(faction)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Здесь будет информация\nо фракции "$faction"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}