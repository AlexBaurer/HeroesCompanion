import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heroescompanion/app/orientation_lock.dart';

void main() {
  group('lockPortraitOrientation', () {
    testWidgets('передаёт Flutter только портретную ориентацию (portraitUp)', (
      tester,
    ) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await lockPortraitOrientation();

      final call = calls.where(
        (c) => c.method == 'SystemChrome.setPreferredOrientations',
      );
      expect(call, hasLength(1));
      final orientations =
          (call.first.arguments as Map<Object?, Object?>)['orientations'];
      expect(orientations, ['DeviceOrientation.portraitUp']);
    });
  });
}
