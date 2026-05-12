import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/widgets/action_note_dialog.dart';

void main() {
  testWidgets('keeps long cheer input and labels inside the dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: ActionNoteDialog(
            title: '파트너가 남긴 아주 긴 실천 제목이 들어와도 깨지지 않는지 확인하는 테스트 제목',
            hintText: '따뜻한 피드백을 남겨주세요 (선택)',
            buttonLabel: '확인하고 응원 보내기',
          ),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.minLines, 3);
    expect(textField.maxLines, 5);

    await tester.enterText(
      find.byType(TextField),
      List.filled(150, '응원').join(),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('centers emoji reactions with fixed text metrics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: ActionNoteDialog(
            title: '파트너 실천',
            hintText: '따뜻한 피드백을 남겨주세요 (선택)',
          ),
        ),
      ),
    );

    final emojiText = tester.widget<Text>(find.text('👍'));

    expect(emojiText.textAlign, TextAlign.center);
    expect(emojiText.style?.height, 1);
    expect(emojiText.strutStyle?.height, 1);
    expect(emojiText.strutStyle?.forceStrutHeight, isTrue);
  });
}
