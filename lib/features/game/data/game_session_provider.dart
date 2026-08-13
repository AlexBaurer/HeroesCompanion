import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heroescompanion/domain/action_order.dart';
import 'package:heroescompanion/domain/session.dart';

import '../../factions/data/faction_providers.dart';

/// Сессия партии для фракции [factionName] — единый источник истины
/// состояния партии (раунд, ресурсы, армия, модификаторы, порядок действий).
///
/// `GameSession` мутабелен (один объект на партию); каждое изменение
/// уведомляет слушателей через [Ref.notifyListeners], чтобы виджеты
/// пересчитывали силу армии и перерисовывались.
final gameSessionProvider =
    NotifierProvider.family<GameSessionNotifier, GameSession, String>(
      GameSessionNotifier.new,
    );

class GameSessionNotifier extends FamilyNotifier<GameSession, String> {
  @override
  GameSession build(String factionName) {
    final catalog = ref.watch(factionCatalogProvider).value;
    final faction = catalog?.byName(factionName);
    if (faction == null) {
      throw StateError('фракция "$factionName" не найдена в каталоге');
    }
    return GameSession(faction: faction);
  }

  void setResource(String name, int value) {
    state.setResource(name, value);
    ref.notifyListeners();
  }

  void setArmyTotal(String unitId, int value) {
    state.setArmyTotal(unitId, value);
    ref.notifyListeners();
  }

  void setArmyDeployed(String unitId, int value) {
    state.setArmyDeployed(unitId, value);
    ref.notifyListeners();
  }

  void setToggleEnabled(int index, bool enabled) {
    state.setToggleEnabled(index, enabled);
    ref.notifyListeners();
  }

  void setCounterCount(int index, int count) {
    state.setCounterCount(index, count);
    ref.notifyListeners();
  }

  /// Переходит к следующему раунду; возвращает true, если партия завершена.
  bool advanceRound() {
    final finished = state.advanceRound();
    ref.notifyListeners();
    return finished;
  }

  /// Применяет порядок действий из ячеек перестановки [slots]: первые
  /// 4 ячейки получают уровни 1–4, пятая — невыбранное действие (уровень 0).
  /// Список короче полного (частичный порядок) не ломает состояние.
  void applyActionOrder(List<GameAction> slots) {
    for (final action in GameAction.values) {
      state.clearAction(action);
    }
    final levels = GameAction.values.length - 1;
    for (var i = 0; i < slots.length && i < levels; i++) {
      state.setActionLevel(slots[i], i + 1);
    }
    ref.notifyListeners();
  }
}
