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
  final List<String> _values = List.generate(6, (index) => '');
  String _playerName = '';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Результаты игры'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            SizedBox(
              width: 250,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Введите имя игрока',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
                onChanged: (value) {
                  setState(() {
                    _playerName = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 32),
            // First row with first three input fields
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInputFieldWithBackground('assets/score_screen/buildings.PNG', 1),
                const SizedBox(width: 16),
                _buildInputFieldWithBackground('assets/score_screen/fundaments.PNG', 2),
                const SizedBox(width: 16),
                _buildInputFieldWithBackground('assets/score_screen/resources.PNG', 3),
              ],
            ),
            const SizedBox(height: 16),
            // Second row with last two input fields and total display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInputFieldWithBackground('assets/score_screen/fights.PNG', 4),
                const SizedBox(width: 16),
                _buildInputFieldWithBackground('assets/score_screen/artifacts.PNG', 5),
                const SizedBox(width: 16),
                _buildTotalDisplay(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFieldWithBackground(String asset, int index) {
    return Stack(
      children: [
        // Полупрозрачная картинка из ассетов
        Opacity(
          opacity: 0.8,
          child: Image.asset(
            asset,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        // Поле ввода поверх картинки
        Transform.translate(
          offset: const Offset(0, 45),
          child: SizedBox(
              width: 100,
              height: 100,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: InputBorder.none, // Убираем границу
                  enabledBorder: InputBorder.none, // Убираем границу в обычном состоянии
                  focusedBorder: InputBorder.none, // Убираем границу при фокусе
                  contentPadding: EdgeInsets.all(8),
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
                onChanged: (value) {
                  setState(() {
                    _values[index] = value;
                  });
                },
              ),
            ),
        ),
      ],
    );
  }

  Widget _buildTotalDisplay() {
    return Stack(
      children: [
        // Полупрозрачная картинка для отображения суммы
        Opacity(
          opacity: 0.8,
          child: Image.asset(
            'assets/score_screen/general.PNG',
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        // Отображение суммы поверх картинки
        Transform.translate(
          offset: const Offset(0, 45),
          child: Container(
              width: 100,
              height: 100,
              // decoration: BoxDecoration(
              //   color: Colors.transparent,
              //   border: Border.all(color: Colors.blue),
              // ),
              child:       
                  Text(
                    '$_total',
                    textAlign: TextAlign.center,
                    style: const TextStyle(            
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
          ],
        );
      
  }
}