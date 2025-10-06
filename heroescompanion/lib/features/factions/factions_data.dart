import 'package:flutter/material.dart';

class Faction {
  final String name;
  final Color primaryColor;
  final List<String> resources;
  final List<String> units;
  final List<String> unitsAssets;

  const Faction({
    required this.name,
    required this.primaryColor,
    required this.resources,
    required this.units,
    required this.unitsAssets,
    });

  static const all = [
    Faction(
      name: 'Люди',
      primaryColor: Colors.blue,
      resources: ['Золото', 'Дерево', 'Железо'],
      units: ['Солдат', 'Латник', 'Архимаг'],
      unitsAssets: ['assets/units/soldier.PNG', 'assets/units/latnik.PNG', 'assets/units/archimage.PNG'],
    ),
    Faction(
      name: 'Нежить',
      primaryColor: Colors.grey,
      resources: ['Золото', 'Дерево', 'Железо'],
      units: ['Скелет', 'Палач', 'Лич'],
      unitsAssets: ['assets/units/skeleton.PNG', 'assets/units/paladin.PNG', 'assets/units/lich.PNG'],
    ),
    Faction(
      name: 'Гномы',
      primaryColor: Colors.brown,
      resources: ['Золото', 'Дерево', 'Железо'],
      units: ['Механик', 'Стреколёт', 'Автоматон', 'Мехозавр'],
      unitsAssets: ['assets/units/mechanic.PNG', 'assets/units/skarlat.PNG', 'assets/units/automaton.PNG', 'assets/units/mechazavr.PNG'],
    ),
    Faction(
      name: 'Орки',
      primaryColor: Colors.green,
      resources: ['Золото', 'Дерево', 'Железо', 'Ярость'],
      units: ['Разведчик', 'Громила', 'Взрыватель'],
      unitsAssets: ['assets/units/explorer.PNG', 'assets/units/grom.PNG', 'assets/units/vzryvatel.PNG'],
    ),
    Faction(
      name: 'Эльфы',
      primaryColor: Colors.teal,
      resources: ['Золото', 'Дерево', 'Железо'],
      units: ['Пикси', 'Грифон', 'Энт'],
      unitsAssets: ['assets/units/pixi.PNG', 'assets/units/grifon.PNG', 'assets/units/ent.PNG'],
    ),
    Faction(
      name: 'Наги',
      primaryColor: Colors.cyan,
      resources: ['Золото', 'Дерево', 'Железо', 'Краки'],
      units: ['Краки'],
      unitsAssets: ['assets/units/kraki.PNG'],
    ),
    Faction(
      name: 'Гремлины',
      primaryColor: Colors.orange,
      resources: ['Золото', 'Дерево', 'Железо'],
      units: ['Вышибала', 'Наливала', 'Летала'],
      unitsAssets: ['assets/units/vyshivabla.PNG', 'assets/units/nalivala.PNG', 'assets/units/letala.PNG'],
    ),
    Faction(
      name: 'Механизмы',
      primaryColor: Colors.grey,
      resources: ['Золото', 'Дерево'],
      units: ['Ядро', 'Крушитель', 'Колосс'],
      unitsAssets: ['assets/units/yadro.PNG', 'assets/units/krushitel.PNG', 'assets/units/koloss.PNG'],
    ),
    Faction(
      name: 'Элементали',
      primaryColor: Colors.red,
      resources: ['Золото', 'Дерево', 'Железо'],
      units: ['Зефира', 'Тур', 'Джазир', 'Майя'],
      unitsAssets: ['assets/units/zefira.PNG', 'assets/units/tur.PNG', 'assets/units/dzazir.PNG', 'assets/units/maya.PNG'],
    ),
    Faction(
      name: 'Демоны',
      primaryColor: Colors.deepPurple,
      resources: ['Золото', 'Дерево', 'Железо'],
      units: ['Бес', 'Суккуб', 'Мясник'],
      unitsAssets: ['assets/units/bes.PNG', 'assets/units/sukkub.PNG', 'assets/units/myasnik.PNG'],
    ),
    Faction(
      name: 'Полурослики',
      primaryColor: Colors.greenAccent,
      resources: ['Золото', 'Дерево', 'Железо'],
      units: ['Гладиатор', 'Легионер'],
      unitsAssets: ['assets/units/gladiator.PNG', 'assets/units/legioner.PNG'],
    ),
    Faction(
      name: 'Культисты',
      primaryColor: Colors.black,
      resources: ['Золото', 'Дерево', 'Железо'],
      units: ['Проповедник', 'Паломник'],
      unitsAssets: ['assets/units/propovednik.PNG', 'assets/units/palomnik.PNG'],
    ),
  ];

  static Faction? fromName(String name) {
    return all.firstWhere((f) => f.name == name);
  }
}