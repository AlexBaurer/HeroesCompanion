import 'package:flutter/material.dart';

class ScoreEntryScreen extends StatelessWidget {
  const ScoreEntryScreen({super.key, this.factionName});

  /// Фракция игрока, переданная с экрана партии (тикет 08 использует её
  /// для записи результатов).
  final String? factionName;

  @override
  Widget build(BuildContext context) {
    final faction = factionName == null ? '' : ' ($factionName)';
    return Scaffold(
      appBar: AppBar(title: const Text('Ввод очков')),
      body: Center(child: Text('Заглушка: ввод очков$faction')),
    );
  }
}
