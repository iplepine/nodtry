import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/history/presentation/history_state.dart';
import 'package:nod_try/features/history/presentation/history_viewmodel.dart';
import 'package:nod_try/features/now/presentation/now_tab_intent.dart';
import 'package:nod_try/features/now/presentation/now_tab_state.dart';
import 'package:nod_try/features/now/presentation/now_tab_viewmodel.dart';
import 'package:nod_try/features/us/presentation/us_state.dart';
import 'package:nod_try/features/us/presentation/us_viewmodel.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/connected_user.dart';
import 'package:nod_try/models/history_item.dart';
import 'package:nod_try/models/home_state.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/plan_summary.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/providers/plan_list_provider.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/screens/home_screen.dart';
import 'package:nod_try/theme/app_colors.dart';
import 'package:nod_try/theme/app_theme.dart';
import 'package:nod_try/theme/app_theme_enum.dart';
import 'package:nod_try/widgets/quiet_header.dart';

const _logicalSize = Size(440, 956);
const _pixelRatio = 3.0;
final _shotKey = GlobalKey();

class StaticNowTabViewModel extends NowTabViewModel {
  StaticNowTabViewModel(this.shotState);

  final NowTabState shotState;

  @override
  Stream<NowTabState> build() => Stream.value(shotState);

  @override
  Future<void> dispatch(NowTabIntent intent) async {}
}

class StaticHistoryViewModel extends HistoryViewModel {
  StaticHistoryViewModel(this.shotState);

  final HistoryState shotState;

  @override
  Stream<HistoryState> build() => Stream.value(shotState);
}

class StaticUsViewModel extends UsViewModel {
  StaticUsViewModel(this.shotState);

  final UsState shotState;

  @override
  FutureOr<UsState> build() => shotState;
}

void main() {
  testWidgets('generate current store screenshots', (tester) async {
    tester.view.physicalSize = _logicalSize * _pixelRatio;
    tester.view.devicePixelRatio = _pixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    AppColors.setTheme(AppThemeType.smokyPlum);
    await tester.runAsync(_loadFonts);
    final iconImage = await tester.runAsync(
      () async =>
          _decodeImage(await File('assets/images/app_icon.png').readAsBytes()),
    );
    final googleLogoImage = await tester.runAsync(
      () async => _decodeImage(
        await File('assets/images/google_logo.png').readAsBytes(),
      ),
    );

    await tester.runAsync(_clearStoreScreenshots);

    for (final locale in const [Locale('ko'), Locale('en')]) {
      final isKorean = locale.languageCode == 'ko';

      await _pumpShot(
        tester,
        _LoginShot(iconImage: iconImage!, googleLogoImage: googleLogoImage!),
        locale,
      );
      await _capture(tester, '01_login', locale);

      await _pumpHomeShot(tester, locale);
      await _capture(tester, '02_home', locale);

      await tester.tap(find.text(isKorean ? '기록' : 'History'));
      await _settle(tester);
      await _capture(tester, '03_history', locale);

      await tester.tap(find.text(isKorean ? '메이트' : 'Together'));
      await _settle(tester);
      await _capture(tester, '04_us', locale);
    }

  });
}

Future<void> _loadFonts() async {
  const pretendardPath = 'assets/fonts/Pretendard-Regular.otf';
  final pretendardFile = File(pretendardPath);
  final fontData = _isFontFile(pretendardFile)
      ? rootBundle.load(pretendardPath)
      : _loadFontFile(File('/System/Library/Fonts/AppleSDGothicNeo.ttc'));
  final loader = FontLoader('Pretendard')..addFont(fontData);
  await loader.load();

  final materialIconsPath = File(
    '${_flutterRoot()}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (materialIconsPath.existsSync()) {
    final materialLoader = FontLoader('MaterialIcons')
      ..addFont(_loadFontFile(materialIconsPath));
    await materialLoader.load();
  }
}

bool _isFontFile(File file) {
  if (!file.existsSync()) return false;
  final bytes = file.readAsBytesSync();
  if (bytes.length < 4) return false;

  final signature = String.fromCharCodes(bytes.take(4));
  return signature == 'OTTO' ||
      signature == 'ttcf' ||
      (bytes[0] == 0 && bytes[1] == 1 && bytes[2] == 0 && bytes[3] == 0);
}

String _flutterRoot() {
  var dir = File(Platform.resolvedExecutable).parent;
  while (dir.parent.path != dir.path) {
    final materialFont = File(
      '${dir.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (materialFont.existsSync()) return dir.path;
    dir = dir.parent;
  }
  final fallback = Platform.environment['FLUTTER_ROOT'];
  if (fallback != null && fallback.isNotEmpty) return fallback;
  return dir.path;
}

Future<ByteData> _loadFontFile(File file) async {
  final bytes = await file.readAsBytes();
  return ByteData.sublistView(bytes);
}

Future<ui.Image> _decodeImage(Uint8List bytes) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromList(bytes, completer.complete);
  return completer.future;
}

_homeOverrides(Locale locale) {
  final isKorean = locale.languageCode == 'ko';
  final me = _user(
    uid: 'me',
    name: isKorean ? '민서' : 'Minseo',
    status: isKorean
        ? '퇴근 후에도 약속은 작게 지키는 중'
        : 'Keeping promises small after work',
    inviteCode: 'NOD-4821',
  );
  final partner = _user(
    uid: 'partner',
    name: isKorean ? '지민' : 'Jimin',
    status: isKorean
        ? '서로 놓치지 않게 봐주는 메이트'
        : 'Here to notice and keep each other going',
  );
  final connected = [
    ConnectedUser(user: partner, isSupported: true, isCheering: true),
  ];

  final myPlans = [
    _plan(
      id: 'study_words',
      userId: 'me',
      title: isKorean ? '영어 단어 20개 외우기' : 'Learn 20 English words',
      hour: 21,
      startOffsetDays: -10,
      endOffsetDays: 18,
    ),
    _plan(
      id: 'evening_walk',
      userId: 'me',
      title: isKorean ? '저녁 산책 15분' : '15-minute evening walk',
      hour: 19,
      startOffsetDays: -5,
      endOffsetDays: 23,
    ),
  ];
  final partnerPlans = [
    _plan(
      id: 'partner_reading',
      userId: 'partner',
      title: isKorean ? '잠들기 전 책 10쪽' : 'Read 10 pages before bed',
      hour: 22,
      startOffsetDays: -7,
      endOffsetDays: 21,
    ),
  ];

  return [
    myProfileProvider.overrideWith((ref) => Stream.value(me)),
    connectedProfilesProvider.overrideWith((ref) async => connected),
    nowTabViewModelProvider.overrideWith(
      () => StaticNowTabViewModel(_nowState(partner, isKorean: isKorean)),
    ),
    historyViewModelProvider.overrideWith(
      () => StaticHistoryViewModel(_historyState(isKorean: isKorean)),
    ),
    usViewModelProvider.overrideWith(
      () => StaticUsViewModel(_usState(me, connected)),
    ),
    activePlansProvider('me').overrideWith((ref) => Stream.value(myPlans)),
    activePlansProvider(
      'partner',
    ).overrideWith((ref) => Stream.value(partnerPlans)),
  ];
}

NowTabState _nowState(UserModel partner, {required bool isKorean}) {
  final nowAction = HomeCardModel(
    state: HomeCardState.nowAction,
    plan: _plan(
      id: 'today_words',
      userId: 'me',
      title: isKorean ? '영어 단어 20개 외우기' : 'Learn 20 English words',
      hour: DateTime.now().hour,
      startOffsetDays: -10,
      endOffsetDays: 18,
      note: isKorean
          ? '어제보다 빨리 시작해볼게요.'
          : 'I will start earlier than yesterday.',
    ),
    currentWeek: 2,
    totalWeeks: 4,
    streakCount: 4,
  );

  return NowTabState(
    allCards: [
      nowAction,
      HomeCardModel(
        state: HomeCardState.overdue,
        plan: _plan(
          id: 'late_walk',
          userId: 'me',
          title: isKorean ? '어제 저녁 산책' : "Yesterday's evening walk",
          hour: 19,
          startOffsetDays: -5,
          endOffsetDays: 23,
        ),
      ),
      HomeCardModel(
        state: HomeCardState.partnerAction,
        partnerName: partner.displayName,
        headerMessage: isKorean ? '지민이 해냈어요' : 'Jimin did it',
        plan: _plan(
          id: 'partner_done',
          userId: 'partner',
          title: isKorean ? '책 10쪽 읽기' : 'Read 10 pages',
          hour: 22,
          startOffsetDays: -7,
          endOffsetDays: 21,
          note: isKorean
              ? '오늘은 자기 전에 바로 읽었어요.'
              : 'I read right before bed today.',
        ),
        currentWeek: 2,
        totalWeeks: 4,
      ),
    ],
    primaryCard: nowAction,
    secondaryCards: [
      HomeCardModel(
        state: HomeCardState.overdue,
        plan: _plan(
          id: 'late_walk',
          userId: 'me',
          title: isKorean ? '어제 저녁 산책' : "Yesterday's evening walk",
          hour: 19,
          startOffsetDays: -5,
          endOffsetDays: 23,
        ),
      ),
    ],
    managerCards: [
      HomeCardModel(
        state: HomeCardState.partnerAction,
        partnerName: partner.displayName,
        headerMessage: isKorean ? '지민이 해냈어요' : 'Jimin did it',
        plan: _plan(
          id: 'partner_done',
          userId: 'partner',
          title: isKorean ? '책 10쪽 읽기' : 'Read 10 pages',
          hour: 22,
          startOffsetDays: -7,
          endOffsetDays: 21,
          note: isKorean
              ? '오늘은 자기 전에 바로 읽었어요.'
              : 'I read right before bed today.',
        ),
        currentWeek: 2,
        totalWeeks: 4,
      ),
    ],
    partnerProfile: partner,
    headerPeriodState: HeaderPeriodState.inProgress,
  );
}

HistoryState _historyState({required bool isKorean}) {
  final now = DateTime.now();
  return HistoryState(
    activeItems: [
      HistoryItem(
        id: 'h1',
        planId: 'today_words',
        date: now,
        title: isKorean ? '영어 단어 20개 외우기' : 'Learn 20 English words',
        status: HistoryStatus.done,
        executorId: 'me',
        note: isKorean
            ? '20개 다 외웠고, 헷갈린 3개만 다시 볼게요.'
            : 'Learned all 20. I will review the three tricky ones.',
        isVerifiedByPartner: true,
      ),
      HistoryItem(
        id: 'h2',
        planId: 'partner_done',
        date: now.subtract(const Duration(hours: 2)),
        title: isKorean ? '책 10쪽 읽기' : 'Read 10 pages',
        status: HistoryStatus.done,
        executorId: 'partner',
        partnerName: isKorean ? '지민' : 'Jimin',
        comment: isKorean
            ? '오늘은 먼저 끝냈네요. 좋아요 👍'
            : 'You finished first today. Nice work!',
        isVerifiedByMe: true,
      ),
      HistoryItem(
        id: 'h3',
        planId: 'evening_walk',
        date: now.subtract(const Duration(days: 1)),
        title: isKorean ? '저녁 산책 15분' : '15-minute evening walk',
        status: HistoryStatus.actuallyDone,
        executorId: 'me',
        note: isKorean
            ? '늦었지만 집 앞 한 바퀴는 채웠어요.'
            : 'It was late, but I still walked around the block.',
      ),
    ],
    finishedPlanSummaries: [
      PlanSummary(
        planId: 'finished_1',
        title: isKorean ? '아침 물 한 컵 마시기' : 'Drink water every morning',
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.subtract(const Duration(days: 2)),
        myCount: 24,
        partnerCount: 21,
      ),
    ],
    partnerName: isKorean ? '지민' : 'Jimin',
    headerPeriodState: HeaderPeriodState.inProgress,
    currentWeek: 2,
    totalWeeks: 4,
  );
}

UsState _usState(UserModel me, List<ConnectedUser> connected) {
  return UsState(myProfile: me, connectedProfiles: connected);
}

UserModel _user({
  required String uid,
  required String name,
  String? status,
  String? inviteCode,
}) {
  final now = DateTime.now();
  return UserModel(
    uid: uid,
    displayName: name,
    email: '$uid@example.com',
    statusMessage: status,
    inviteCode: inviteCode,
    loginType: LoginType.email,
    createdAt: now.subtract(const Duration(days: 30)),
    updatedAt: now,
  );
}

Plan _plan({
  required String id,
  required String userId,
  required String title,
  required int hour,
  required int startOffsetDays,
  required int endOffsetDays,
  String? note,
}) {
  final now = DateTime.now();
  return Plan(
    id: id,
    userId: userId,
    startDate: now.add(Duration(days: startOffsetDays)),
    endDate: now.add(Duration(days: endOffsetDays)),
    state: PlanState.active,
    createdAt: now.add(Duration(days: startOffsetDays)),
    lastActionNote: note,
    items: [
      PlanItem(
        title: title,
        days: const [1, 2, 3, 4, 5],
        count: 5,
        notificationTime: NotificationTime.custom(hour, 0),
      ),
    ],
  );
}

Future<void> _pumpShot(WidgetTester tester, Widget child, Locale locale) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      child: RepaintBoundary(
        key: _shotKey,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.smokyPlumTheme,
          home: child,
        ),
      ),
    ),
  );
  await _settle(tester);
}

Future<void> _pumpHomeShot(WidgetTester tester, Locale locale) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: _homeOverrides(locale),
      child: RepaintBoundary(
        key: _shotKey,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.smokyPlumTheme,
          home: const HomeScreen(),
        ),
      ),
    ),
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i += 1) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> _capture(WidgetTester tester, String name, Locale locale) async {
  await tester.runAsync(() async {
    final boundary =
        _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final isKorean = locale.languageCode == 'ko';
    final iosLocale = isKorean ? 'ko' : 'en-US';
    final androidLocale = isKorean ? 'ko-KR' : 'en-US';
    final targets = [
      'ios/fastlane/screenshots/$iosLocale/$name.png',
      'android/fastlane/metadata/android/$androidLocale/images/phoneScreenshots/$name.png',
    ];

    for (final target in targets) {
      final file = File(target);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    }
  });
}

Future<void> _clearStoreScreenshots() async {
  final directories = [
    'ios/fastlane/screenshots/ko',
    'ios/fastlane/screenshots/en-US',
    'android/fastlane/metadata/android/ko-KR/images/phoneScreenshots',
    'android/fastlane/metadata/android/en-US/images/phoneScreenshots',
  ];

  for (final path in directories) {
    final directory = Directory(path);
    if (!directory.existsSync()) continue;

    await for (final entity in directory.list()) {
      if (entity is File && entity.path.endsWith('.png')) {
        await entity.delete();
      }
    }
  }
}

class _LoginShot extends StatelessWidget {
  const _LoginShot({required this.iconImage, required this.googleLogoImage});

  final ui.Image iconImage;
  final ui.Image googleLogoImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: RawImage(
                  image: iconImage,
                  width: 112,
                  height: 112,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.splashTagline,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              _LoginButton(
                color: Colors.black,
                foregroundColor: Colors.white,
                icon: Icons.apple,
                label: l10n.loginWithApple,
              ),
              const SizedBox(height: 12),
              _LoginButton(
                color: Colors.white,
                foregroundColor: const Color(0xFF1F1F1F),
                borderColor: const Color(0xFF747775),
                image: googleLogoImage,
                label: l10n.loginWithGoogle,
              ),
              const SizedBox(height: 12),
              _LoginButton(
                color: AppColors.background,
                foregroundColor: AppColors.primary,
                borderColor: AppColors.primary,
                label: l10n.loginWithEmail,
              ),
              const SizedBox(height: 18),
              Text(
                l10n.loginGuest,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Text(
                  l10n.privacyMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textDisabled,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.color,
    required this.foregroundColor,
    required this.label,
    this.borderColor,
    this.icon,
    this.image,
  });

  final Color color;
  final Color foregroundColor;
  final String label;
  final Color? borderColor;
  final IconData? icon;
  final ui.Image? image;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (image != null) ...[
            RawImage(image: image, width: 20, height: 20),
            const SizedBox(width: 10),
          ] else if (icon != null) ...[
            Icon(icon, color: foregroundColor, size: 22),
            const SizedBox(width: 10),
          ],
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
