import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heroescompanion/features/scores/presentation/signed_int_input_formatter.dart';

void main() {
  /// Результат применения фильтра к полной замене текста поля
  /// (как делает TextField при вводе/вставке).
  String apply(String oldText, String newText) {
    return signedIntInputFormatter
        .formatEditUpdate(
          TextEditingValue(text: oldText),
          TextEditingValue(text: newText),
        )
        .text;
  }

  group('signedIntInputFormatter', () {
    test('пустое значение допустимо (поле ещё не заполнено)', () {
      expect(apply('', ''), '');
    });

    test('минус в начале допустим (ввод отрицательного числа)', () {
      expect(apply('', '-'), '-');
    });

    test('положительные и отрицательные целые допустимы', () {
      expect(apply('', '0'), '0');
      expect(apply('0', '12'), '12');
      expect(apply('', '-12'), '-12');
      expect(apply('-1', '-124'), '-124');
    });

    test('буквы отбрасываются', () {
      expect(apply('', 'abc'), '');
      expect(apply('12', '12a'), '12');
      expect(apply('', 'abc12'), '');
    });

    test('минус допустим только первым символом', () {
      expect(apply('1', '1-2'), '1');
      expect(apply('12', '12-'), '12');
      expect(apply('12', '1-2-3'), '12');
      expect(apply('', '--12'), '');
      expect(apply('-5', '-5-'), '-5');
    });
  });
}
