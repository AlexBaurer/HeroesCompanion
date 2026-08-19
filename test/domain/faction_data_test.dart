import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heroescompanion/domain/faction.dart';
import 'package:heroescompanion/domain/faction_parser.dart';
import 'package:heroescompanion/domain/strength_modifier.dart';

const _factionFiles = [
  // Часть 1 (коробка 1)
  'humans.json',
  'necros.json',
  'gnomes.json',
  'orcs.json',
  'elfs.json',
  'nags.json',
  // Часть 2 (коробка 2)
  'gremlins.json',
  'mechanisms.json',
  'elementals.json',
  'demons.json',
  'halflings.json',
  'cultists.json',
  // Часть 3 (коробка 3)
  'mushroomers.json',
  'werewolves.json',
  'archons.json',
  'lizardmen.json',
  'darkelfs.json',
  'cyclops.json',
];

const _expectedNames = [
  'Люди',
  'Нежить',
  'Гномы',
  'Орки',
  'Эльфы',
  'Наги',
  'Гремлины',
  'Механизмы',
  'Элементали',
  'Демоны',
  'Полурослики',
  'Культисты',
  'Гриболюды',
  'Оборотни',
  'Архонты',
  'Ящеры',
  'Тёмные эльфы',
  'Циклопы',
];

/// Юниты и силы коробок 1–2 — из данных v1 (factions_data.dart).
const _v1Units = {
  'humans.json': [('Солдат', 2), ('Латник', 3), ('Архимаг', 5)],
  'necros.json': [('Скелет', 1), ('Палач', 0), ('Лич', 5)],
  'gnomes.json': [
    ('Механик', 0),
    ('Стреколёт', 2),
    ('Автоматон', 4),
    ('Мехозавр', 5),
  ],
  'orcs.json': [('Разведчик', 2), ('Громила', 5), ('Взрыватель', 9)],
  'elfs.json': [('Пикси', 1), ('Грифон', 3), ('Энт', 6)],
  'nags.json': [('Краки', 1)],
  'gremlins.json': [('Вышибала', 1), ('Наливала', 4), ('Летала', 9)],
  'mechanisms.json': [('Ядро', 1), ('Крушитель', 4), ('Колосс', 7)],
  'elementals.json': [
    ('Зефира', 2),
    ('Тур', 1),
    ('Джазир', 0),
    ('Майя', 7),
  ],
  'demons.json': [('Бес', 1), ('Суккуб', 4), ('Мясник', 7)],
  'halflings.json': [('Гладиатор', 3), ('Легионер', 6)],
  'cultists.json': [('Проповедник', 3), ('Паломник', 0)],
};

Faction load(String fileName) {
  final source = File('assets/factions/$fileName').readAsStringSync();
  return const FactionParser().parse(source);
}

List<StrengthModifier> modsByUnit(Faction faction, String unitId) =>
    faction.modifiersFor(unitId);

void main() {
  group('данные 18 фракций (тикет 05)', () {
    test('18 файлов: по 6 фракций на каждую часть игры', () {
      final factions = _factionFiles.map(load).toList();

      expect(factions, hasLength(18));
      for (var part = 1; part <= 3; part++) {
        expect(
          factions.where((f) => f.gamePart == part),
          hasLength(6),
          reason: 'часть $part должна содержать 6 фракций',
        );
      }
    });

    test('каждый JSON проходит валидатор FactionParser', () {
      for (final file in _factionFiles) {
        expect(
          () => load(file),
          returnsNormally,
          reason: '$file должен парситься без ошибок',
        );
      }
    });

    test('имена фракций — 12 из v1 плюс 6 новых из коробки 3', () {
      final names = _factionFiles.map(load).map((f) => f.name).toList();

      expect(names, _expectedNames);
      expect(names.toSet(), hasLength(18));
    });

    test('у каждой фракции есть непустое описание (тикет 19)', () {
      for (final file in _factionFiles) {
        final faction = load(file);
        expect(faction.description, isNotEmpty, reason: file);
        expect(faction.description.trim(), isNotEmpty, reason: file);
      }
    });

    test('у каждой фракции есть ресурсы и фон в формате v1', () {
      for (final file in _factionFiles) {
        final faction = load(file);
        expect(faction.resources, isNotEmpty, reason: file);
        expect(faction.resources.every((r) => r.isNotEmpty), isTrue,
            reason: file);
        expect(
          faction.backgroundPath,
          startsWith('assets/faction_background/'),
          reason: file,
        );
        expect(faction.backgroundPath, endsWith('_low.PNG'), reason: file);
        expect(faction.color, startsWith('#'), reason: file);
      }
    });

    test('все модификаторы ссылаются на существующих юнитов', () {
      for (final file in _factionFiles) {
        final faction = load(file);
        for (final modifier in faction.modifiers) {
          expect(faction.unitById(modifier.unitId), isNotNull,
              reason: '$file: модификатор юнита ${modifier.unitId}');
        }
      }
    });

    test('uniqueUnits (тикет 23): true у Гриболюдов, false у остальных', () {
      for (final file in _factionFiles) {
        final faction = load(file);
        if (file == 'mushroomers.json') {
          expect(faction.uniqueUnits, isTrue, reason: file);
        } else {
          expect(faction.uniqueUnits, isFalse, reason: file);
        }
      }
    });
  });

  group('коробки 1–2 совпадают с данными v1', () {
    _v1Units.forEach((file, expected) {
      test(file, () {
        final faction = load(file);
        expect(
          faction.units.map((u) => (u.name, u.basePower)).toList(),
          expected,
        );
      });
    });

    test('Наги: краки считаются по формуле n²', () {
      final faction = load('nags.json');
      expect(faction.armyPowerFormula, ArmyPowerFormula.nSquared);
    });

    test('Эльфы: «Лавка бронника» — дерево, лимит 2, целевые силы 1→2, 3→5, 6→10', () {
      final faction = load('elfs.json');
      final upgrade = faction.battleUpgrade;
      expect(upgrade, isNotNull);
      expect(upgrade!.resource, 'Дерево');
      expect(faction.resources, contains(upgrade.resource));
      expect(upgrade.limit, 2);
      expect(upgrade.powers, const {'pixi': 2, 'grifon': 5, 'ent': 10});
      for (final unitId in upgrade.powers.keys) {
        expect(faction.unitById(unitId), isNotNull,
            reason: 'целевая сила юнита $unitId');
      }
    });

    test('battleUpgrade есть только у эльфов', () {
      for (final file in _factionFiles) {
        final faction = load(file);
        if (file == 'elfs.json') {
          expect(faction.battleUpgrade, isNotNull, reason: file);
        } else {
          expect(faction.battleUpgrade, isNull, reason: file);
        }
      }
    });

    test('Люди: переключатели 2→3, 3→4, 5→7', () {
      final faction = load('humans.json');
      final bonuses = faction.modifiers
          .map((m) => (m as ToggleModifier).bonusPower)
          .toList();
      expect(bonuses, [3, 4, 7]);
    });

    test('Нежить: скелет-переключатель и палач-счётчик', () {
      final faction = load('necros.json');
      expect(modsByUnit(faction, 'skeleton').single, isA<ToggleModifier>());
      final palach = modsByUnit(faction, 'palach').single as CounterModifier;
      expect(palach.step, 1);
    });

    test('Элементали: цепочка «Майя 7→10→14» — два переключателя одного юнита', () {
      final faction = load('elementals.json');
      final maya = modsByUnit(faction, 'maya');
      expect(maya, hasLength(2));
      expect(
        maya.map((m) => (m as ToggleModifier).bonusPower),
        [10, 14],
      );
      final dzazir = modsByUnit(faction, 'dzazir').single as CounterModifier;
      expect(dzazir.step, 3);
    });

    test('Культисты: паломник — 4 переключателя местностей', () {
      final faction = load('cultists.json');
      final palomnik = modsByUnit(faction, 'palomnik');
      expect(palomnik, hasLength(4));
      expect(
        palomnik.map((m) => (m as ToggleModifier).bonusPower),
        [4, 6, 8, 10],
      );
    });

    test('Механизмы: ресурсы только дерево и золото (как в v1)', () {
      final faction = load('mechanisms.json');
      expect(faction.resources, ['Дерево', 'Золото']);
    });

    test('Орки: фракционный ресурс «Ярость»', () {
      final faction = load('orcs.json');
      expect(faction.resources, ['Дерево', 'Железо', 'Золото', 'Ярость']);
    });
  });

  group('коробка 3 (чтение rules3.pdf)', () {
    test('Оборотни: Одичалый 2, Волхв 4, Ярл 4; волчья ночь — переключатели', () {
      final faction = load('werewolves.json');
      expect(faction.resources, ['Дерево', 'Железо', 'Золото', 'Мясо']);
      expect(
        faction.units.map((u) => (u.name, u.basePower)).toList(),
        [('Одичалый', 2), ('Волхв', 4), ('Ярл', 4)],
      );
      expect(
        modsByUnit(faction, 'odichaly').whereType<ToggleModifier>().map((m) => m.bonusPower),
        [3],
      );
      expect(
        modsByUnit(faction, 'odichaly').whereType<CounterModifier>().map((m) => m.step),
        [2],
      );
      expect(
        (modsByUnit(faction, 'volhv').single as ToggleModifier).bonusPower,
        6,
      );
      expect(
        modsByUnit(faction, 'yarl').whereType<ToggleModifier>().map((m) => m.bonusPower),
        [8],
      );
      expect(
        modsByUnit(faction, 'yarl').whereType<CounterModifier>().map((m) => m.step),
        [1],
      );
    });

    test('Архонты: Обвинитель 1, Защитник 2, Вершитель 14; счётчики силы', () {
      final faction = load('archons.json');
      expect(
        faction.units.map((u) => (u.name, u.basePower)).toList(),
        [('Обвинитель', 1), ('Защитник', 2), ('Вершитель', 14)],
      );
      expect(faction.modifiers, hasLength(2));
      final zashitnik = faction.modifiers[0] as CounterModifier;
      expect(zashitnik.unitId, 'zaschitnik');
      expect(zashitnik.step, 1);
      final vershitel = faction.modifiers[1] as CounterModifier;
      expect(vershitel.unitId, 'vershitel');
      expect(vershitel.step, -2);
    });

    test('Ящеры: Шаман 4 с двумя переключателями (5 и 6)', () {
      final faction = load('lizardmen.json');
      expect(faction.units.single.name, 'Шаман');
      expect(faction.units.single.basePower, 4);
      final shaman = modsByUnit(faction, 'shaman');
      expect(shaman, hasLength(2));
      expect(
        shaman.map((m) => (m as ToggleModifier).bonusPower),
        [5, 6],
      );
    });

    test('Тёмные эльфы: Ассасин 3, Кокон 1, Арахнид 5 с переключателем до 7', () {
      final faction = load('darkelfs.json');
      expect(
        faction.units.map((u) => (u.name, u.basePower)).toList(),
        [('Ассасин', 3), ('Кокон', 1), ('Арахнид', 5)],
      );
      expect(
        (modsByUnit(faction, 'arahnid').single as ToggleModifier).bonusPower,
        7,
      );
    });

    test('Циклопы: Охотник 7, Пастырь 4 (→6), Саблезуб 1; без «Подков» (тикет 24)', () {
      final faction = load('cyclops.json');
      expect(faction.resources, ['Дерево', 'Железо', 'Золото']);
      expect(faction.resources, isNot(contains('Подковы')));
      expect(
        faction.units.map((u) => (u.name, u.basePower)).toList(),
        [('Охотник', 7), ('Пастырь', 4), ('Саблезуб', 1)],
      );
      expect(
        (modsByUnit(faction, 'pastyr').single as ToggleModifier).bonusPower,
        6,
      );
    });

    test('Гриболюды: 12 зданий-воинов, Архитокс и Тленитель силой 10', () {
      final faction = load('mushroomers.json');
      expect(faction.resources, ['Дерево', 'Железо', 'Золото', 'Грибной ресурс']);
      expect(faction.units, hasLength(12));
      expect(faction.unitById('arhytoks')?.basePower, 10);
      expect(faction.unitById('tlenitel')?.basePower, 10);
      expect(faction.unitById('muhostrel')?.basePower, 8);
      final boost = faction.modifiers
          .map((m) => (m as ToggleModifier).bonusPower)
          .toList();
      expect(boost, [4, 4, 4]);
    });
  });
}
