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

    await _pumpShot(
      tester,
      _LoginShot(iconImage: iconImage!, googleLogoImage: googleLogoImage!),
    );
    await _capture(tester, '01_login');

    await _pumpHomeShot(tester);
    await _capture(tester, '02_home');

    await tester.tap(find.text('기록'));
    await _settle(tester);
    await _capture(tester, '03_history');

    await tester.tap(find.text('우리'));
    await _settle(tester);
    await _capture(tester, '04_us');

    await tester.runAsync(_writeAndroidStoreIcon);
  });
}

Future<void> _loadFonts() async {
  final loader = FontLoader('Pretendard')
    ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
    ..addFont(rootBundle.load('assets/fonts/Pretendard-Medium.otf'))
    ..addFont(rootBundle.load('assets/fonts/Pretendard-Bold.otf'));
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

_homeOverrides() {
  final me = _user(
    uid: 'me',
    name: '민서',
    status: '퇴근 후에도 약속은 작게 지키는 중',
    inviteCode: 'NOD-4821',
  );
  final partner = _user(
    uid: 'partner',
    name: '지민',
    status: '서로 놓치지 않게 봐주는 메이트',
  );
  final connected = [
    ConnectedUser(user: partner, isSupported: true, isCheering: true),
  ];

  final myPlans = [
    _plan(
      id: 'study_words',
      userId: 'me',
      title: '영어 단어 20개 외우기',
      hour: 21,
      startOffsetDays: -10,
      endOffsetDays: 18,
    ),
    _plan(
      id: 'evening_walk',
      userId: 'me',
      title: '저녁 산책 15분',
      hour: 19,
      startOffsetDays: -5,
      endOffsetDays: 23,
    ),
  ];
  final partnerPlans = [
    _plan(
      id: 'partner_reading',
      userId: 'partner',
      title: '잠들기 전 책 10쪽',
      hour: 22,
      startOffsetDays: -7,
      endOffsetDays: 21,
    ),
  ];

  return [
    myProfileProvider.overrideWith((ref) => Stream.value(me)),
    connectedProfilesProvider.overrideWith((ref) async => connected),
    nowTabViewModelProvider.overrideWith(
      () => StaticNowTabViewModel(_nowState(partner)),
    ),
    historyViewModelProvider.overrideWith(
      () => StaticHistoryViewModel(_historyState()),
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

NowTabState _nowState(UserModel partner) {
  final nowAction = HomeCardModel(
    state: HomeCardState.nowAction,
    plan: _plan(
      id: 'today_words',
      userId: 'me',
      title: '영어 단어 20개 외우기',
      hour: DateTime.now().hour,
      startOffsetDays: -10,
      endOffsetDays: 18,
      note: '어제보다 빨리 시작해볼게요.',
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
          title: '어제 저녁 산책',
          hour: 19,
          startOffsetDays: -5,
          endOffsetDays: 23,
        ),
      ),
      HomeCardModel(
        state: HomeCardState.partnerAction,
        partnerName: partner.displayName,
        headerMessage: '지민이 해냈어요',
        plan: _plan(
          id: 'partner_done',
          userId: 'partner',
          title: '책 10쪽 읽기',
          hour: 22,
          startOffsetDays: -7,
          endOffsetDays: 21,
          note: '오늘은 자기 전에 바로 읽었어요.',
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
          title: '어제 저녁 산책',
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
        headerMessage: '지민이 해냈어요',
        plan: _plan(
          id: 'partner_done',
          userId: 'partner',
          title: '책 10쪽 읽기',
          hour: 22,
          startOffsetDays: -7,
          endOffsetDays: 21,
          note: '오늘은 자기 전에 바로 읽었어요.',
        ),
        currentWeek: 2,
        totalWeeks: 4,
      ),
    ],
    partnerProfile: partner,
    headerPeriodState: HeaderPeriodState.inProgress,
  );
}

HistoryState _historyState() {
  final now = DateTime.now();
  return HistoryState(
    activeItems: [
      HistoryItem(
        id: 'h1',
        planId: 'today_words',
        date: now,
        title: '영어 단어 20개 외우기',
        status: HistoryStatus.done,
        executorId: 'me',
        note: '20개 다 외웠고, 헷갈린 3개만 다시 볼게요.',
        isVerifiedByPartner: true,
      ),
      HistoryItem(
        id: 'h2',
        planId: 'partner_done',
        date: now.subtract(const Duration(hours: 2)),
        title: '책 10쪽 읽기',
        status: HistoryStatus.done,
        executorId: 'partner',
        partnerName: '지민',
        comment: '오늘은 먼저 끝냈네요. 좋아요 👍',
        isVerifiedByMe: true,
      ),
      HistoryItem(
        id: 'h3',
        planId: 'evening_walk',
        date: now.subtract(const Duration(days: 1)),
        title: '저녁 산책 15분',
        status: HistoryStatus.actuallyDone,
        executorId: 'me',
        note: '늦었지만 집 앞 한 바퀴는 채웠어요.',
      ),
    ],
    finishedPlanSummaries: [
      PlanSummary(
        planId: 'finished_1',
        title: '아침 물 한 컵 마시기',
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.subtract(const Duration(days: 2)),
        myCount: 24,
        partnerCount: 21,
      ),
    ],
    partnerName: '지민',
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

Future<void> _pumpShot(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      child: RepaintBoundary(
        key: _shotKey,
        child: MaterialApp(
          locale: const Locale('ko'),
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

Future<void> _pumpHomeShot(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: _homeOverrides(),
      child: RepaintBoundary(
        key: _shotKey,
        child: MaterialApp(
          locale: const Locale('ko'),
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

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary =
        _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final targets = [
      'ios/fastlane/screenshots/ko/$name.png',
      'android/fastlane/metadata/android/ko-KR/images/phoneScreenshots/$name.png',
    ];

    for (final target in targets) {
      final file = File(target);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    }
  });
}

Future<void> _writeAndroidStoreIcon() async {
  final source = File('web/icons/Icon-512.png');
  if (!source.existsSync()) return;

  final bytes = await source.readAsBytes();
  for (final locale in const ['ko-KR', 'en-US']) {
    final file = File(
      'android/fastlane/metadata/android/$locale/images/icon.png',
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
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
