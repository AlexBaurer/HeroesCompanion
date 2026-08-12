/// Действия раунда партии: 5 ячеек, 4 из них получают уровень 1–4.
enum GameAction { wood, iron, gold, move, build }

/// Порядок действий текущего раунда: у каждого действия уровень 0–4,
/// где 0 — действие не выбрано. Уровни выбранных действий уникальны.
class ActionOrder {
  const ActionOrder._(this._levels);

  /// Уровень каждого действия: 0 — не выбрано.
  final Map<GameAction, int> _levels;

  static const int maxLevel = 4;

  factory ActionOrder.empty() => const ActionOrder._({});

  int levelOf(GameAction action) => _levels[action] ?? 0;

  bool isChosen(GameAction action) => levelOf(action) > 0;

  int get chosenCount => _levels.values.where((level) => level > 0).length;

  /// Порядок задан полностью: выбраны 4 действия из 5.
  bool get isComplete => chosenCount == GameAction.values.length - 1;

  /// Выбранные действия в порядке выполнения (по возрастанию уровня).
  List<GameAction> get chosenActions {
    final actions = <GameAction>[
      for (final action in GameAction.values)
        if (isChosen(action)) action,
    ];
    actions.sort((a, b) => levelOf(a).compareTo(levelOf(b)));
    return actions;
  }

  /// Задаёт уровень [level] действию [action].
  /// Бросает [ArgumentError], если уровень уже занят другим действием
  /// или выходит за пределы 1–4.
  ActionOrder withLevel(GameAction action, int level) {
    if (level < 1 || level > maxLevel) {
      throw ArgumentError.value(
        level,
        'level',
        'уровень действия должен быть в диапазоне 1–$maxLevel',
      );
    }
    final levels = Map<GameAction, int>.of(_levels);
    for (final entry in levels.entries) {
      if (entry.key != action && entry.value == level) {
        throw ArgumentError.value(
          level,
          'level',
          'уровень $level уже занят действием ${entry.key}',
        );
      }
    }
    levels[action] = level;
    return ActionOrder._(levels);
  }

  /// Снимает уровень с действия (оставляет пустым).
  ActionOrder without(GameAction action) {
    final levels = Map<GameAction, int>.of(_levels);
    levels.remove(action);
    return ActionOrder._(levels);
  }
}
