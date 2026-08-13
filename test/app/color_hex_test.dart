import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:heroescompanion/app/color_hex.dart';

void main() {
  group('colorFromHex', () {
    test('#RRGGBB → непрозрачный цвет', () {
      expect(colorFromHex('#BE5737'), const Color(0xFFBE5737));
      expect(colorFromHex('#3949AB'), const Color(0xFF3949AB));
    });

    test('без решётки тоже разбирается', () {
      expect(colorFromHex('BE5737'), const Color(0xFFBE5737));
    });

    test('некорректный формат → fallback', () {
      const fallback = Color(0xFF123456);
      expect(colorFromHex('', fallback: fallback), fallback);
      expect(colorFromHex('#FFF', fallback: fallback), fallback);
      expect(colorFromHex('#GGGGGG', fallback: fallback), fallback);
    });
  });
}
