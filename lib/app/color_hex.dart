import 'dart:ui' show Color;

/// Парсинг цвета фракции из данных (`#RRGGBB`).
///
/// Данные валидируются как непустая строка; при неожиданном формате
/// возвращается [fallback], чтобы UI не падал на битых данных.
Color colorFromHex(String hex, {Color fallback = const Color(0xFF9E9E9E)}) {
  final normalized = hex.replaceFirst('#', '');
  if (normalized.length != 6) return fallback;
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return fallback;
  return Color(0xFF000000 | value);
}

/// Контрастный цвет текста на фоне [background]: тёмный на светлых
/// цветах фракций (золото Орков, бирюза Наг), белый — на тёмных.
Color contrastingForeground(Color background) {
  return background.computeLuminance() > 0.5
      ? const Color(0xDD000000)
      : const Color(0xFFFFFFFF);
}

