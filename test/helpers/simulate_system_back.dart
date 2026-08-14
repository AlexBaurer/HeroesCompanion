import 'package:flutter/services.dart';

/// Симулирует системное «назад» (как в тестах Flutter framework):
/// платформенное сообщение popRoute по каналу навигации — полный путь
/// через RootBackButtonDispatcher (go_router) → RouterDelegate.popRoute →
/// maybePop → PopScope.
Future<void> simulateSystemBack() {
  return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        SystemChannels.navigation.name,
        const JSONMessageCodec().encodeMessage(<String, dynamic>{
          'method': 'popRoute',
        }),
        (ByteData? _) {},
      );
}
