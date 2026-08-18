import 'package:flutter_test/flutter_test.dart';
import 'package:heroescompanion/domain/faction.dart';
import 'package:heroescompanion/domain/faction_parser.dart';
import 'package:heroescompanion/domain/strength_modifier.dart';

const _humansJson = '''
{
  "name": "Люди",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "assets/faction_background/humans_low.PNG",
  "description": "Владеют сильными и относительно дешёвыми войсками.",
  "resources": ["Дерево", "Железо", "Золото"],
  "units": [
    {"id": "soldier", "name": "Солдат", "power": 2},
    {"id": "latnik", "name": "Латник", "power": 3},
    {"id": "archimage", "name": "Архимаг", "power": 5}
  ],
  "modifiers": [
    {"unit": "soldier", "type": "toggle", "bonusPower": 3},
    {"unit": "latnik", "type": "toggle", "bonusPower": 4},
    {"unit": "archimage", "type": "toggle", "bonusPower": 7}
  ]
}
''';

const _elementalsJson = '''
{
  "name": "Элементали",
  "gamePart": 2,
  "color": "#F44336",
  "background": "assets/faction_background/elementals_low.PNG",
  "description": "Поглощают силу осколков Сердца.",
  "resources": ["Дерево", "Железо", "Золото"],
  "units": [
    {"id": "zefira", "name": "Зефира", "power": 2},
    {"id": "tur", "name": "Тур", "power": 1},
    {"id": "dzazir", "name": "Джазир", "power": 0},
    {"id": "maya", "name": "Майя", "power": 7}
  ],
  "modifiers": [
    {"unit": "zefira", "type": "toggle", "bonusPower": 3},
    {"unit": "tur", "type": "toggle", "bonusPower": 2},
    {"unit": "maya", "type": "toggle", "bonusPower": 10},
    {"unit": "maya", "type": "toggle", "bonusPower": 14},
    {"unit": "dzazir", "type": "counter", "step": 3}
  ]
}
''';

Faction parse(String source) => const FactionParser().parse(source);

void main() {
  group('корректный вход (данные v1)', () {
    test('Люди: фракция целиком разбирается в модель', () {
      final faction = parse(_humansJson);

      expect(faction.name, 'Люди');
      expect(faction.gamePart, 1);
      expect(faction.color, '#BE5737');
      expect(faction.backgroundPath, 'assets/faction_background/humans_low.PNG');
      expect(faction.resources, const ['Дерево', 'Железо', 'Золото']);
      expect(faction.units, hasLength(3));
      expect(faction.units[0].id, 'soldier');
      expect(faction.units[0].name, 'Солдат');
      expect(faction.units[0].basePower, 2);
      expect(faction.unitById('archimage')?.basePower, 5);
      expect(faction.unitById('dragon'), isNull);
    });

    test('Люди: модификаторы привязаны к юнитам по id', () {
      final faction = parse(_humansJson);

      expect(faction.modifiers, hasLength(3));
      expect(
        faction.modifiers.every((m) => faction.unitById(m.unitId) != null),
        isTrue,
      );
      final soldierMods = faction.modifiersFor('soldier');
      expect(soldierMods, hasLength(1));
      final mod = soldierMods.single as ToggleModifier;
      expect(mod.bonusPower, 3);
      expect(mod.withEnabled(true).applyTo(2), 3);
      expect(faction.modifiersFor('archimage').single is ToggleModifier, isTrue);
    });

    test('Элементали: юниты и силы из данных v1', () {
      final faction = parse(_elementalsJson);

      expect(faction.name, 'Элементали');
      expect(faction.gamePart, 2);
      expect(faction.units, hasLength(4));
      expect(
        faction.units.map((u) => (u.name, u.basePower)).toList(),
        const [
          ('Зефира', 2),
          ('Тур', 1),
          ('Джазир', 0),
          ('Майя', 7),
        ],
      );
    });

    test('Элементали: цепочка «Майя 7→10→14» — модификаторы одного юнита', () {
      final faction = parse(_elementalsJson);

      final mayaMods = faction.modifiersFor('maya');
      expect(mayaMods, hasLength(2));
      expect(mayaMods.every((m) => m.unitId == 'maya'), isTrue);
      final bonuses = mayaMods.map((m) => (m as ToggleModifier).bonusPower);
      expect(bonuses, const [10, 14]);

      final chained = mayaMods.fold<int>(
        7,
        (power, modifier) =>
            (modifier as ToggleModifier).withEnabled(true).applyTo(power),
      );
      expect(chained, 14);
    });

    test('Элементали: счётчик «Джазир» — базовая + счёт × шаг', () {
      final faction = parse(_elementalsJson);

      final mod = faction.modifiersFor('dzazir').single as CounterModifier;
      expect(mod.step, 3);
      expect(mod.withCount(2).applyTo(0), 6);
    });
  });

  group('counter с параметрами по умолчанию', () {
    test('шаг и maxCount необязательны', () {
      const json = '''
{
  "name": "Нежить",
  "gamePart": 1,
  "color": "#088AAA",
  "background": "assets/faction_background/necros_low.PNG",
  "description": "Способна воскрешать павших воинов.",
  "resources": ["Дерево", "Железо", "Золото"],
  "units": [
    {"id": "skeleton", "name": "Скелет", "power": 1},
    {"id": "palach", "name": "Палач", "power": 0}
  ],
  "modifiers": [
    {"unit": "skeleton", "type": "toggle", "bonusPower": 2},
    {"unit": "palach", "type": "counter"}
  ]
}
''';

      final faction = parse(json);

      final mod = faction.modifiersFor('palach').single as CounterModifier;
      expect(mod.step, 1);
      expect(mod.maxCount, 99);
      expect(mod.withCount(3).applyTo(0), 3);
    });
  });

  group('counter с отрицательным шагом (счётчик урона)', () {
    test('Архонты: Вершитель со step -2 разбирается и уменьшает силу', () {
      const json = '''
{
  "name": "Архонты",
  "gamePart": 3,
  "color": "#3949AB",
  "background": "assets/faction_background/archons_low.PNG",
  "description": "Их здания уже построены.",
  "resources": ["Дерево", "Железо", "Золото"],
  "units": [
    {"id": "obvinitel", "name": "Обвинитель", "power": 1},
    {"id": "vershitel", "name": "Вершитель", "power": 14}
  ],
  "modifiers": [
    {"unit": "vershitel", "type": "counter", "step": -2}
  ]
}
''';

      final faction = parse(json);

      final mod = faction.modifiersFor('vershitel').single as CounterModifier;
      expect(mod.step, -2);
      expect(mod.withCount(0).applyTo(14), 14);
      expect(mod.withCount(2).applyTo(14), 10);
    });
  });

  group('armyPower: признак особого расчёта силы', () {
    test('без поля — стандартный расчёт perUnit', () {
      final faction = parse(_humansJson);

      expect(faction.armyPowerFormula, ArmyPowerFormula.perUnit);
    });

    test('Наги: armyPower = nSquared', () {
      const json = '''
{
  "name": "Наги",
  "gamePart": 2,
  "color": "#00C6D4",
  "background": "assets/faction_background/nags_low.PNG",
  "description": "Водные существа краки служат им и воинами, и ресурсами.",
  "resources": ["Дерево", "Железо", "Золото"],
  "units": [
    {"id": "kraken", "name": "Краки", "power": 1}
  ],
  "armyPower": "nSquared"
}
''';

      final faction = parse(json);

      expect(faction.armyPowerFormula, ArmyPowerFormula.nSquared);
    });

    test('неизвестное значение → FactionInvalidValueException', () {
      const json = '''
{
  "name": "Наги",
  "gamePart": 2,
  "color": "#00C6D4",
  "background": "b",
  "description": "Тестовое описание фракции.",
  "resources": ["Дерево"],
  "units": [
    {"id": "kraken", "name": "Краки", "power": 1}
  ],
  "armyPower": "nPower"
}
''';

      expect(
        () => parse(json),
        throwsA(
          isA<FactionInvalidValueException>()
              .having((e) => e.field, 'field', 'armyPower'),
        ),
      );
    });
  });

  group('battleUpgrade: «Лавка бронника» (эльфы)', () {
    const json = '''
{
  "name": "Эльфы",
  "gamePart": 1,
  "color": "#732EB4",
  "background": "assets/faction_background/elfs_low.PNG",
  "description": "Усиливают свои войска грифонами и энтами.",
  "resources": ["Дерево", "Железо", "Золото"],
  "units": [
    {"id": "pixi", "name": "Пикси", "power": 1},
    {"id": "grifon", "name": "Грифон", "power": 3},
    {"id": "ent", "name": "Энт", "power": 6}
  ],
  "battleUpgrade": {
    "resource": "Дерево",
    "limit": 2,
    "powers": {"pixi": 2, "grifon": 5, "ent": 10}
  }
}
''';

    test('разбирается: цена-ресурс, лимит, целевые силы юнитов', () {
      final faction = parse(json);

      final upgrade = faction.battleUpgrade;
      expect(upgrade, isNotNull);
      expect(upgrade!.resource, 'Дерево');
      expect(upgrade.limit, 2);
      expect(upgrade.powers, const {'pixi': 2, 'grifon': 5, 'ent': 10});
      expect(upgrade.targetPowerOf('ent'), 10);
      expect(upgrade.targetPowerOf('dragon'), isNull);
    });

    test('без поля battleUpgrade — null', () {
      expect(parse(_humansJson).battleUpgrade, isNull);
    });

    test('цена-ресурс вне ресурсов фракции → FactionInvalidValueException', () {
      const json = '''
{
  "name": "Эльфы",
  "gamePart": 1,
  "color": "#732EB4",
  "background": "b",
  "description": "Тестовое описание фракции.",
  "resources": ["Дерево"],
  "units": [
    {"id": "pixi", "name": "Пикси", "power": 1}
  ],
  "battleUpgrade": {
    "resource": "Ярость",
    "limit": 2,
    "powers": {"pixi": 2}
  }
}
''';

      expect(
        () => parse(json),
        throwsA(
          isA<FactionInvalidValueException>()
              .having((e) => e.field, 'field', 'resource'),
        ),
      );
    });

    test('лимит меньше 1 → FactionInvalidValueException', () {
      const json = '''
{
  "name": "Эльфы",
  "gamePart": 1,
  "color": "#732EB4",
  "background": "b",
  "description": "Тестовое описание фракции.",
  "resources": ["Дерево"],
  "units": [
    {"id": "pixi", "name": "Пикси", "power": 1}
  ],
  "battleUpgrade": {
    "resource": "Дерево",
    "limit": 0,
    "powers": {"pixi": 2}
  }
}
''';

      expect(
        () => parse(json),
        throwsA(
          isA<FactionInvalidValueException>()
              .having((e) => e.field, 'field', 'limit'),
        ),
      );
    });

    test('целевая сила для неизвестного юнита → FactionUnknownUnitException', () {
      const json = '''
{
  "name": "Эльфы",
  "gamePart": 1,
  "color": "#732EB4",
  "background": "b",
  "description": "Тестовое описание фракции.",
  "resources": ["Дерево"],
  "units": [
    {"id": "pixi", "name": "Пикси", "power": 1}
  ],
  "battleUpgrade": {
    "resource": "Дерево",
    "limit": 2,
    "powers": {"dragon": 2}
  }
}
''';

      expect(
        () => parse(json),
        throwsA(
          isA<FactionUnknownUnitException>()
              .having((e) => e.unitId, 'unitId', 'dragon'),
        ),
      );
    });

    test('пустые целевые силы → FactionInvalidValueException', () {
      const json = '''
{
  "name": "Эльфы",
  "gamePart": 1,
  "color": "#732EB4",
  "background": "b",
  "description": "Тестовое описание фракции.",
  "resources": ["Дерево"],
  "units": [
    {"id": "pixi", "name": "Пикси", "power": 1}
  ],
  "battleUpgrade": {
    "resource": "Дерево",
    "limit": 2,
    "powers": {}
  }
}
''';

      expect(
        () => parse(json),
        throwsA(
          isA<FactionInvalidValueException>()
              .having((e) => e.field, 'field', 'powers'),
        ),
      );
    });

    test('целевая сила строкой → FactionInvalidValueException', () {
      const json = '''
{
  "name": "Эльфы",
  "gamePart": 1,
  "color": "#732EB4",
  "background": "b",
  "description": "Тестовое описание фракции.",
  "resources": ["Дерево"],
  "units": [
    {"id": "pixi", "name": "Пикси", "power": 1}
  ],
  "battleUpgrade": {
    "resource": "Дерево",
    "limit": 2,
    "powers": {"pixi": "2"}
  }
}
''';

      expect(
        () => parse(json),
        throwsA(
          isA<FactionInvalidValueException>()
              .having((e) => e.field, 'field', 'pixi'),
        ),
      );
    });

    test('неизвестное поле в battleUpgrade → FactionUnknownFieldException', () {
      const json = '''
{
  "name": "Эльфы",
  "gamePart": 1,
  "color": "#732EB4",
  "background": "b",
  "description": "Тестовое описание фракции.",
  "resources": ["Дерево"],
  "units": [
    {"id": "pixi", "name": "Пикси", "power": 1}
  ],
  "battleUpgrade": {
    "resource": "Дерево",
    "limit": 2,
    "cost": 3,
    "powers": {"pixi": 2}
  }
}
''';

      expect(
        () => parse(json),
        throwsA(
          isA<FactionUnknownFieldException>()
              .having((e) => e.field, 'field', 'cost'),
        ),
      );
    });
  });

  group('description: краткое описание фракции', () {
    test('непустая строка разбирается в Faction.description', () {
      const json = '''
{
  "name": "Люди",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "b",
  "description": "Владеют сильными и относительно дешёвыми войсками.",
  "resources": ["Дерево"],
  "units": [
    {"id": "soldier", "name": "Солдат", "power": 2}
  ]
}
''';

      final faction = parse(json);

      expect(
        faction.description,
        'Владеют сильными и относительно дешёвыми войсками.',
      );
    });

    test('отсутствует → FactionMissingFieldException', () {
      const json = '''
{
  "name": "Люди",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "b",
  "resources": ["Дерево"],
  "units": [
    {"id": "soldier", "name": "Солдат", "power": 2}
  ]
}
''';

      expect(
        () => parse(json),
        throwsA(
          isA<FactionMissingFieldException>()
              .having((e) => e.field, 'field', 'description'),
        ),
      );
    });

    test('пустая строка → FactionInvalidValueException', () {
      const json = '''
{
  "name": "Люди",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "b",
  "description": "",
  "resources": ["Дерево"],
  "units": [
    {"id": "soldier", "name": "Солдат", "power": 2}
  ]
}
''';

      expect(
        () => parse(json),
        throwsA(
          isA<FactionInvalidValueException>()
              .having((e) => e.field, 'field', 'description'),
        ),
      );
    });

    test('не строка → FactionInvalidValueException', () {
      const json = '''
{
  "name": "Люди",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "b",
  "description": 42,
  "resources": ["Дерево"],
  "units": [
    {"id": "soldier", "name": "Солдат", "power": 2}
  ]
}
''';

      expect(
        () => parse(json),
        throwsA(
          isA<FactionInvalidValueException>()
              .having((e) => e.field, 'field', 'description'),
        ),
      );
    });
  });

  group('битый вход', () {
    test('некорректный JSON-синтаксис → FactionSyntaxException', () {
      expect(
        () => parse('{не json'),
        throwsA(isA<FactionSyntaxException>()),
      );
    });

    test('корневой элемент не объект → FactionSyntaxException', () {
      expect(
        () => parse('[1, 2, 3]'),
        throwsA(isA<FactionSyntaxException>()),
      );
    });

    test('неизвестное поле у фракции → FactionUnknownFieldException', () {
      const json = '''
{
  "name": "Люди",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "assets/faction_background/humans_low.PNG",
  "description": "Владеют сильными и относительно дешёвыми войсками.",
  "resources": ["Дерево", "Железо", "Золото"],
  "unitCount": 3,
  "units": [
    {"id": "soldier", "name": "Солдат", "power": 2}
  ]
}
''';

      expect(
        () => parse(json),
        throwsA(
          isA<FactionUnknownFieldException>()
              .having((e) => e.field, 'field', 'unitCount'),
        ),
      );
    });

    test('неизвестное поле у юнита → FactionUnknownFieldException', () {
      const json = '''
{
  "name": "Люди",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "b",
  "description": "Тестовое описание фракции.",
  "resources": ["Дерево"],
  "units": [
    {"id": "soldier", "name": "Солдат", "power": 2, "bonus": 3}
  ]
}
''';

      expect(
        () => parse(json),
        throwsA(
          isA<FactionUnknownFieldException>()
              .having((e) => e.field, 'field', 'bonus'),
        ),
      );
    });

    test('отсутствует обязательное поле у юнита → FactionMissingFieldException', () {
      const json = '''
{
  "name": "Люди",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "b",
  "description": "Тестовое описание фракции.",
  "resources": ["Дерево"],
  "units": [
    {"id": "soldier", "power": 2}
  ]
}
''';

      expect(
        () => parse(json),
        throwsA(
          isA<FactionMissingFieldException>()
              .having((e) => e.field, 'field', 'name'),
        ),
      );
    });

    test('сила строкой → FactionInvalidValueException', () {
      const json = '''
{
  "name": "Люди",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "b",
  "description": "Тестовое описание фракции.",
  "resources": ["Дерево"],
  "units": [
    {"id": "soldier", "name": "Солдат", "power": "2"}
  ]
}
''';

      expect(
        () => parse(json),
        throwsA(
          isA<FactionInvalidValueException>()
              .having((e) => e.field, 'field', 'power'),
        ),
      );
    });

    test('отрицательная сила → FactionInvalidValueException', () {
      const json = '''
{
  "name": "Люди",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "b",
  "description": "Тестовое описание фракции.",
  "resources": ["Дерево"],
  "units": [
    {"id": "soldier", "name": "Солдат", "power": -1}
  ]
}
''';

      expect(() => parse(json), throwsA(isA<FactionInvalidValueException>()));
    });

    test('часть игры вне 1–3 → FactionInvalidValueException', () {
      const json = '''
{
  "name": "Люди",
  "gamePart": 4,
  "color": "#BE5737",
  "background": "b",
  "description": "Тестовое описание фракции.",
  "resources": ["Дерево"],
  "units": [
    {"id": "soldier", "name": "Солдат", "power": 2}
  ]
}
''';

      expect(
        () => parse(json),
        throwsA(
          isA<FactionInvalidValueException>()
              .having((e) => e.field, 'field', 'gamePart'),
        ),
      );
    });

    test('пустой список юнитов → FactionInvalidValueException', () {
      const json = '''
{
  "name": "Люди",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "b",
  "description": "Тестовое описание фракции.",
  "resources": ["Дерево"],
  "units": []
}
''';

      expect(
        () => parse(json),
        throwsA(
          isA<FactionInvalidValueException>()
              .having((e) => e.field, 'field', 'units'),
        ),
      );
    });

    test('дубликат id юнита → FactionDuplicateUnitIdException', () {
      const json = '''
{
  "name": "Люди",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "b",
  "description": "Тестовое описание фракции.",
  "resources": ["Дерево"],
  "units": [
    {"id": "soldier", "name": "Солдат", "power": 2},
    {"id": "soldier", "name": "Гвардеец", "power": 4}
  ]
}
''';

      expect(
        () => parse(json),
        throwsA(
          isA<FactionDuplicateUnitIdException>()
              .having((e) => e.unitId, 'unitId', 'soldier'),
        ),
      );
    });

    test('модификатор ссылается на несуществующего юнита → FactionUnknownUnitException', () {
      const json = '''
{
  "name": "Люди",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "b",
  "description": "Тестовое описание фракции.",
  "resources": ["Дерево"],
  "units": [
    {"id": "soldier", "name": "Солдат", "power": 2}
  ],
  "modifiers": [
    {"unit": "dragon", "type": "toggle", "bonusPower": 3}
  ]
}
''';

      expect(
        () => parse(json),
        throwsA(
          isA<FactionUnknownUnitException>()
              .having((e) => e.unitId, 'unitId', 'dragon'),
        ),
      );
    });

    test('неизвестный тип модификатора → FactionUnknownModifierTypeException', () {
      const json = '''
{
  "name": "Люди",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "b",
  "description": "Тестовое описание фракции.",
  "resources": ["Дерево"],
  "units": [
    {"id": "soldier", "name": "Солдат", "power": 2}
  ],
  "modifiers": [
    {"unit": "soldier", "type": "magic", "bonusPower": 3}
  ]
}
''';

      expect(
        () => parse(json),
        throwsA(
          isA<FactionUnknownModifierTypeException>()
              .having((e) => e.type, 'type', 'magic'),
        ),
      );
    });

    test('toggle без bonusPower → FactionMissingFieldException', () {
      const json = '''
{
  "name": "Люди",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "b",
  "description": "Тестовое описание фракции.",
  "resources": ["Дерево"],
  "units": [
    {"id": "soldier", "name": "Солдат", "power": 2}
  ],
  "modifiers": [
    {"unit": "soldier", "type": "toggle"}
  ]
}
''';

      expect(
        () => parse(json),
        throwsA(
          isA<FactionMissingFieldException>()
              .having((e) => e.field, 'field', 'bonusPower'),
        ),
      );
    });

    test('сообщения ошибок содержат контекст', () {
      const json = '''
{
  "name": "Люди",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "b",
  "description": "Тестовое описание фракции.",
  "resources": ["Дерево"],
  "units": [
    {"id": "soldier", "name": "Солдат", "power": 2}
  ],
  "modifiers": [
    {"unit": "dragon", "type": "toggle", "bonusPower": 3}
  ]
}
''';

      try {
        parse(json);
        fail('ожидалось исключение');
      } on FactionParseException catch (e) {
        expect(e.message, contains('dragon'));
        expect(e.toString(), contains('FactionUnknownUnitException'));
      }
    });
  });
}
