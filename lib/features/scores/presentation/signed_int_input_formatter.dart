import 'package:flutter/services.dart';

/// Допустимый текст ячейки подсчёта: пусто либо целое со знаком,
/// минус — только первым символом («-12», «7»).
final RegExp _signedIntPattern = RegExp(r'^-?\d*$');

/// Фильтр ввода очков: только цифры; минус разрешён лишь в начале —
/// буквы и знак не на своём месте ввод не пропускают.
final TextInputFormatter signedIntInputFormatter =
    TextInputFormatter.withFunction((oldValue, newValue) {
  return _signedIntPattern.hasMatch(newValue.text) ? newValue : oldValue;
});
