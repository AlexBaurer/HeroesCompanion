import 'package:flutter/material.dart';
import 'package:heroescompanion/features/factions/factions_data.dart';

class ScoreScreen extends StatefulWidget {
  final String factionName;

  const ScoreScreen({super.key, required this.factionName});

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();

}
  
class _ScoreScreenState extends State<ScoreScreen> {
  late Faction _faction;
  final List<String> _values = List.generate(5, (index) => '');

  @override
  void initState() {
    super.initState();
    _faction = Faction.fromName(widget.factionName) ?? Faction.all[0];
  }

  int get _total {
    int sum = 0;
    for (var value in _values) {
      final number = int.tryParse(value);
      if (number != null) {
        sum += number;
      }
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    // Получаем переданный аргумент (название фракции)
    debugPrint('context ${context}');

    debugPrint('fraca $_faction');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Результаты игры'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Игра завершена!\nФракция: ${_faction.name}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 32),
            ...List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Поле ${index + 1}',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _values[index] = value;
                    });
                  },
                ),
              );
            }),
            const SizedBox(height: 16),
            Container(
              width: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Column(
                children: [
                  const Text(
                    'Общий счёт',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$_total',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}