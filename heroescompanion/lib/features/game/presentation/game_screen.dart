import 'package:flutter/material.dart';

class GameScreen extends StatelessWidget {
  final String factionName;

  const GameScreen({super.key, required this.factionName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Партия: $factionName')),
      body: const Center(child: Text('Заглушка: экран партии')),
    );
  }
}
