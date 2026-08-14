import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heroescompanion/app/orientation_lock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('lockPortraitOrientation', () {
    final messenger = TestWidgetsFlutterBinding.instance.defaultBinaryMessenger;

    tearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('передаёт Flutter только портретную ориентацию (portraitUp)', () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });

      await lockPortraitOrientation();

      final call = calls.where(
        (c) => c.method == 'SystemChrome.setPreferredOrientations',
      );
      expect(call, hasLength(1));
      expect(
        call.first.arguments['orientations'],
        ['DeviceOrientation.portraitUp'],
      );
    });
  });
}
