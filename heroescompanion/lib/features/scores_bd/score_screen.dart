import 'package:flutter/material.dart';
import 'package:heroescompanion/features/factions/factions_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:heroescompanion/features/scores_bd/score_record.dart';

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
  String _playerName2 = '';
  String _playerName3 = '';
  String _playerName4 = '';
  String _selectedFaction2 = Faction.all[0].name;
  String _selectedFaction3 = Faction.all[0].name;
  String _selectedFaction4 = Faction.all[0].name;
  final List<String> _playerValues2 = List.generate(6, (index) => '');
  final List<String> _playerValues3 = List.generate(6, (index) => '');
  final List<String> _playerValues4 = List.generate(6, (index) => '');

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

  int get _total2 {
    int sum = 0;
    for (var value in _playerValues2) {
      final number = int.tryParse(value);
      if (number != null) {
        sum += number;
      }
    }
    return sum;
  }

  int get _total3 {
    int sum = 0;
    for (var value in _playerValues3) {
      final number = int.tryParse(value);
      if (number != null) {
        sum += number;
      }
    }
    return sum;
  }

  int get _total4 {
    int sum = 0;
    for (var value in _playerValues4) {
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
            // const Icon(Icons.emoji_events, size: 64, color: Colors.blue),
            // const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Имя 2 игрока',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                        onChanged: (value) {
                          setState(() {
                            _playerName2 = value;
                          });
                        },
                      ),
                    ),
                    // _factionMenu(_selectedFaction2),
                    SizedBox(
                      width: 100,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedFaction2,
                          items: Faction.all.map((Faction faction) {
                            return DropdownMenuItem<String>(
                              value: faction.name,
                              child: Text(
                                faction.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedFaction2 = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    _buildInputFieldWithBackground('assets/score_screen/general.PNG', 1, flag: false, playerIndex: 2),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Имя 3 игрока',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                        onChanged: (value) {
                          setState(() {
                            _playerName3 = value;
                          });
                        },
                      ),
                    ),
                    // _factionMenu(_selectedFaction2),
                    SizedBox(
                      width: 100,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedFaction3,
                          items: Faction.all.map((Faction faction) {
                            return DropdownMenuItem<String>(
                              value: faction.name,
                              child: Text(
                                faction.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedFaction3 = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    _buildInputFieldWithBackground('assets/score_screen/general.PNG', 1, flag: false, playerIndex: 3),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Имя 4 игрока',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                        onChanged: (value) {
                          setState(() {
                            _playerName4 = value;
                          });
                        },
                      ),
                    ),
                    // _factionMenu(_selectedFaction2),
                    SizedBox(
                      width: 100,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedFaction4,
                          items: Faction.all.map((Faction faction) {
                            return DropdownMenuItem<String>(
                              value: faction.name,
                              child: Text(
                                faction.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedFaction4 = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    _buildInputFieldWithBackground('assets/score_screen/general.PNG', 1, flag: false, playerIndex: 4),
                  ],
                ),
                  
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveResults,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Сохранить результаты',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _factionMenu(String selectedFaction) { 
  //   return SizedBox(
  //             width: 100,
  //             child: DropdownButtonHideUnderline(
  //               child: DropdownButton<String>(
  //                 isExpanded: true,
  //                 value: selectedFaction,
  //                 items: Faction.all.map((Faction faction) {
  //                   return DropdownMenuItem<String>(
  //                     value: faction.name,
  //                     child: Text(
  //                       faction.name,
  //                       textAlign: TextAlign.center,
  //                       style: const TextStyle(fontSize: 10),
  //                     ),
  //                   );
  //                 }).toList(),
  //                 onChanged: (String? newValue) {
  //                   if (newValue != null) {
  //                     setState(() {
  //                       selectedFaction = newValue;
  //                     });
  //                   }
  //                 },
  //               ),
  //             ),
  //           );
  // }

  // Widget _buildInputField(String hint, String state) {
  //   return SizedBox(
  //             width: 100,
  //             child: TextField(
  //               decoration: InputDecoration(
  //                 hintText: hint,
  //                 border: const OutlineInputBorder(),
  //                 contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
  //               ),
  //               textAlign: TextAlign.center,
  //               style: const TextStyle(fontSize: 12),
  //               onChanged: (value) {
  //                 setState(() {
  //                   state = value;
  //                 });
  //               },
  //             ),
  //           );
  // }

  Widget _buildInputFieldWithBackground(String asset, int index, {bool flag = true, int playerIndex = 1}) {
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
                  if (flag) {
                    setState(() {
                      _values[index] = value;
                    });
                  } else {
                    switch (playerIndex) {
                      case 2:
                        _playerValues2[index] = value;
                        break;
                      case 3:
                        _playerValues3[index] = value;
                        break;
                      case 4:
                        _playerValues4[index] = value;
                        break;
                    }
                  }
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

  // ... existing code ...
  Future<void> _saveResults() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing records
    final recordsJson = prefs.getStringList('score_records') ?? [];
    final records = recordsJson
        .map((jsonStr) => ScoreRecord.fromJson(jsonDecode(jsonStr)))
        .toList();
    
    // Create a list of player scores for this game
    final playerScores = <PlayerScore>[];
    
    if (_playerName.isNotEmpty) {
      playerScores.add(PlayerScore(
        playerName: _playerName,
        score: _total,
        faction: _faction.name,
      ));
    }
    
    if (_playerName2.isNotEmpty) {
      playerScores.add(PlayerScore(
        playerName: _playerName2,
        score: _total2,
        faction: _selectedFaction2,
      ));
    }
    
    if (_playerName3.isNotEmpty) {
      playerScores.add(PlayerScore(
        playerName: _playerName3,
        score: _total3,
        faction: _selectedFaction3,
      ));
    }
    
    if (_playerName4.isNotEmpty) {
      playerScores.add(PlayerScore(
        playerName: _playerName4,
        score: _total4,
        faction: _selectedFaction4,
      ));
    }
    
    // Only save if we have at least one player
    if (playerScores.isNotEmpty) {
      // Add new record with all players
      records.add(ScoreRecord(
        dateTime: DateTime.now(),
        playerScores: playerScores,
      ));
      
      // Save updated records
      final updatedRecordsJson = records
          .map((record) => jsonEncode(record.toJson()))
          .toList();
      
      await prefs.setStringList('score_records', updatedRecordsJson);
      
      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Результаты успешно сохранены'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushNamed(context, '/score_history');
      }
    }
  }
// ... existing code ...
  
}