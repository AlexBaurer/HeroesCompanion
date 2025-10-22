import 'package:flutter/material.dart';
import 'package:heroescompanion/features/scores_bd/score_record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ScoreHistoryScreen extends StatefulWidget {
  const ScoreHistoryScreen({super.key});

  @override
  State<ScoreHistoryScreen> createState() => _ScoreHistoryScreenState();
}

class _ScoreHistoryScreenState extends State<ScoreHistoryScreen> {
  List<ScoreRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final recordsJson = prefs.getStringList('score_records') ?? [];
      final records = recordsJson
          .map((jsonStr) => ScoreRecord.fromJson(jsonDecode(jsonStr)))
          .toList();

      // Sort by date (newest first)
      records.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при загрузке записей'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('score_records');
    
    setState(() {
      _records = [];
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('История очищена'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История результатов'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Очистить историю'),
                      content: const Text('Вы уверены, что хотите удалить всю историю результатов?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _clearRecords();
                          },
                          child: const Text('Удалить', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'История пуста',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Сохраните результаты игры, чтобы они появились здесь',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final record = _records[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Text(
                          'Игра от ${_formatDateTime(record.dateTime)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text('${record.playerScores.length} игроков'),
                        children: [
                          for (var i = 0; i < record.playerScores.length; i++)
                            ListTile(
                              title: Text(
                                '${record.playerScores[i].playerName} (${record.playerScores[i].faction})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: Text(
                                record.playerScores[i].score.toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}