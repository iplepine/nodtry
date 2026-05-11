import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/widgets/time_chip.dart';

void main() {
  testWidgets('keeps long labels inside narrow cards', (tester) async {
    tester.view.physicalSize = const Size(240, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: TimeChip(
              text: '오후 11:59 · 이미 시간이 꽤 지났지만 오늘 안에는 괜찮아요',
              type: TimeChipType.past,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(TimeChip)).width, lessThanOrEqualTo(132));
  });
}
