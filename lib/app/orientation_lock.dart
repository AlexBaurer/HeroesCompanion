import 'package:flutter/services.dart';

/// Все экраны приложения остаются в портретной ориентации при повороте
/// устройства (тикет 15). Вызывается при старте, до первого кадра.
Future<void> lockPortraitOrientation() =>
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
