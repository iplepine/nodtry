import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/plan_model.dart';
import '../../../models/proof_photo.dart';
import '../../../providers/repository_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/analytics.dart';
import '../../connect/application/partner_label_provider.dart';
import '../../plan/domain/workout_template.dart';
import '../../proof/data/proof_photo_cache.dart';
import '../../proof/data/share_card_temp_files.dart';
import '../application/duo_stats_provider.dart';

/// Why the share card was opened (analytics `trigger`).
enum DuoShareTrigger {
  /// Today just became a duo day.
  today('today'),

  /// The streak reached 3, 7 or 30.
  milestone('milestone'),

  /// The button on the Us tab.
  manual('manual');

  const DuoShareTrigger(this.id);
  final String id;
}

/// How the card uses photos (analytics `layout`).
enum ShareCardLayout {
  /// My 인증샷 only (or no photo at all).
  single('single'),

  /// My 인증샷 and my partner's, split top / bottom. Only when they allowed
  /// it (`users/{partner}.allowPartnerPhotoInShareCard`).
  together('together');

  const ShareCardLayout(this.id);
  final String id;
}

/// Everything the 9:16 share card shows. The partner's photo only when they
/// allowed it ([ShareCardLayout.together]), and never their real name — they
/// appear as the nickname I gave them, else 짝꿍.
class DuoShareCardData {
  const DuoShareCardData({
    required this.streak,
    required this.date,
    required this.meLabel,
    required this.partnerLabel,
    required this.me,
    required this.partner,
    this.photo,
    this.partnerPhoto,
  });

  final int streak;
  final DateTime date;
  final String meLabel;
  final String partnerLabel;
  final DuoPersonDay me;
  final DuoPersonDay partner;

  /// My proof photo (인증샷) of the card's day, JPEG bytes.
  final Uint8List? photo;

  /// My partner's 인증샷, only when they allowed it. With [photo] it makes
  /// the together layout; alone it is never shown.
  final Uint8List? partnerPhoto;

  ShareCardLayout get layout => photo != null && partnerPhoto != null
      ? ShareCardLayout.together
      : ShareCardLayout.single;
}

/// The Storage path of my proof photo for the card's [day]: the newest (by
/// `lastProofAt`) among [myPlans] whose photo belongs to that day's latest
/// record ([todayProofPhotoPathOf]). Null when I recorded without a photo,
/// or only my partner worked out — the card then uses its no-photo layout
/// rather than an old 인증샷 under today's date.
String? shareCardProofPhotoPathOf(
  Iterable<Plan> myPlans, {
  required DateTime day,
}) {
  Plan? latest;
  String? latestPath;
  for (final plan in myPlans) {
    final path = todayProofPhotoPathOf(plan, now: day);
    if (path == null) continue;
    final at = plan.lastProofAt;
    final latestAt = latest?.lastProofAt;
    if (latest == null ||
        (at != null && (latestAt == null || at.isAfter(latestAt)))) {
      latest = plan;
      latestPath = path;
    }
  }
  return latestPath;
}

/// The photo for one person in the together layout: the card [day]'s
/// ([shareCardProofPhotoPathOf]) when there is one, else the newest photo
/// across [plans] (by `lastProofAt`). Paths that aren't the plan owner's
/// (`proofs/{userId}/…`) are skipped.
String? shareCardLatestProofPhotoPathOf(
  Iterable<Plan> plans, {
  required DateTime day,
}) {
  final sameDay = shareCardProofPhotoPathOf(plans, day: day);
  if (sameDay != null) return sameDay;
  String? latestPath;
  DateTime? latestAt;
  for (final plan in plans) {
    final path = plan.lastProofPhotoPath;
    final at = plan.lastProofAt;
    if (path == null || path.isEmpty || at == null) continue;
    if (parseProofPhotoPath(path)?.ownerUid != plan.userId) continue;
    if (latestAt == null || at.isAfter(latestAt)) {
      latestAt = at;
      latestPath = path;
    }
  }
  return latestPath;
}

/// The two Storage paths the together layout would load, or null when it
/// isn't offered: my partner hasn't allowed their photo on my cards
/// ([partnerAllowed], `users/{partner}.allowPartnerPhotoInShareCard`,
/// missing = false), or either of us has no 인증샷.
///
/// Only the partner's plans I manage count — Storage lets a manager read
/// those photos only (and only ones since they became its manager; a photo
/// that still can't be read just keeps the card on the single layout).
({String mine, String partner})? shareCardTogetherPhotoPathsOf({
  required bool partnerAllowed,
  required String? myUid,
  required String? partnerUid,
  required Iterable<Plan> myPlans,
  required Iterable<Plan> partnerPlans,
  required DateTime day,
}) {
  if (!partnerAllowed || myUid == null || partnerUid == null) return null;
  if (myUid == partnerUid) return null;
  final mine = shareCardLatestProofPhotoPathOf(
    myPlans.where((plan) => plan.userId == myUid),
    day: day,
  );
  if (mine == null) return null;
  final partner = shareCardLatestProofPhotoPathOf(
    partnerPlans.where(
      (plan) => plan.userId == partnerUid && plan.managerId == myUid,
    ),
    day: day,
  );
  if (partner == null) return null;
  return (mine: mine, partner: partner);
}

/// The layouts the sheet offers: together only when my partner allowed it
/// and both photos actually loaded.
List<ShareCardLayout> shareCardLayoutsOf({
  required bool partnerAllowed,
  required bool hasMyPhoto,
  required bool hasPartnerPhoto,
}) {
  return partnerAllowed && hasMyPhoto && hasPartnerPhoto
      ? const [ShareCardLayout.single, ShareCardLayout.together]
      : const [ShareCardLayout.single];
}

/// One person's line on the card: "나 ✓ 🏃 러닝", "짝꿍 · 쉬는 날" …
String shareCardPersonLine(
  AppLocalizations l10n,
  String name,
  DuoPersonDay day,
) {
  switch (day.status) {
    case DuoDayStatus.done:
      final workouts = <String>{
        for (final type in day.doneWorkoutTypes)
          switch (workoutDisplayFor(l10n, type)) {
            final display? => '${display.emoji} ${display.name}',
            null => l10n.promiseUntitledFallback,
          },
      };
      return l10n.shareCardPersonDone(name, workouts.join(' · '));
    case DuoDayStatus.rested:
      return l10n.shareCardPersonRested(name);
    case DuoDayStatus.off:
      return l10n.shareCardPersonOff(name);
    case DuoDayStatus.pending:
    case DuoDayStatus.missed:
    case DuoDayStatus.upcoming:
      return l10n.shareCardPersonPending(name);
  }
}

/// The 9:16 share card (spec §4.8), laid out at [designSize] and exported at
/// 3x (1080×1920).
class DuoShareCard extends StatelessWidget {
  const DuoShareCard({super.key, required this.data});

  static const Size designSize = Size(360, 640);

  final DuoShareCardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final photo = data.photo;
    final partnerPhoto = data.layout == ShareCardLayout.together
        ? data.partnerPhoto
        : null;
    final date = DateFormat(
      l10n.localeName.startsWith('ko') ? 'yyyy.MM.dd (E)' : 'MMM d, yyyy',
      l10n.localeName,
    ).format(data.date);
    const shadow = [Shadow(blurRadius: 8, color: Colors.black38)];

    return Semantics(
      label: l10n.shareCardSemantics,
      child: SizedBox.fromSize(
        size: designSize,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo != null && partnerPhoto != null)
              _togetherBackground(photo, partnerPhoto)
            else if (photo != null)
              _photo(photo)
            else
              _gradientBackground(),
            // Legibility scrim over the photo.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: photo != null ? 0.25 : 0),
                    Colors.transparent,
                    Colors.black.withValues(alpha: photo != null ? 0.7 : 0.15),
                  ],
                  stops: const [0, 0.4, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.appTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (photo == null)
                    // No photo: the day's workouts, big, instead of an
                    // empty gradient.
                    Expanded(
                      child: Center(
                        child: Text(
                          _workoutEmojis(l10n),
                          key: const ValueKey('share-card-emojis'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 88, height: 1.1),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  Text(
                    data.streak > 0
                        ? l10n.shareCardStreak(data.streak)
                        : l10n.shareCardNoStreak,
                    key: const ValueKey('share-card-headline'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      shadows: shadow,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final line in [
                    shareCardPersonLine(l10n, data.meLabel, data.me),
                    shareCardPersonLine(l10n, data.partnerLabel, data.partner),
                  ]) ...[
                    Text(
                      line,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        shadows: shadow,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    date,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      shadows: shadow,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.shareCardStores,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      shadows: shadow,
                    ),
                  ),
                ],
              ),
            ),
            if (partnerPhoto != null) ...[
              // Whose photo is whose, top-right of each half.
              Positioned(
                top: 32,
                right: 28,
                child: _nameChip(data.meLabel, const ValueKey('share-card-me')),
              ),
              Positioned(
                top: _togetherHalf + _togetherGap + 14,
                right: 28,
                child: _nameChip(
                  data.partnerLabel,
                  const ValueKey('share-card-partner'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static const double _togetherGap = 2;
  static const double _togetherHalf = (640 - _togetherGap) / 2;

  Widget _photo(Uint8List bytes) {
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stack) => _gradientBackground(),
    );
  }

  /// Mine on top, my partner's below, with a thin white seam.
  Widget _togetherBackground(Uint8List mine, Uint8List partner) {
    return ColoredBox(
      key: const ValueKey('share-card-together'),
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: _togetherHalf,
            width: double.infinity,
            child: _photo(mine),
          ),
          const SizedBox(height: _togetherGap),
          SizedBox(
            height: _togetherHalf,
            width: double.infinity,
            child: _photo(partner),
          ),
        ],
      ),
    );
  }

  Widget _nameChip(String label, Key key) {
    return Container(
      key: key,
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// The emojis of the workouts done that day (both of us), or 💪.
  String _workoutEmojis(AppLocalizations l10n) {
    final emojis = <String>{
      for (final type in [
        ...data.me.doneWorkoutTypes,
        ...data.partner.doneWorkoutTypes,
      ])
        if (workoutDisplayFor(l10n, type) case final display?) display.emoji,
    };
    return emojis.isEmpty ? '💪' : emojis.take(3).join(' ');
  }

  Widget _gradientBackground() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryPressed],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Capture + share seams
// ---------------------------------------------------------------------------

/// Renders the [RepaintBoundary] behind [key] to PNG bytes at [pixelRatio].
Future<Uint8List> captureShareCardPng(
  GlobalKey key, {
  double pixelRatio = 3,
}) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('share card: no PNG data');
    return data.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// Turns the card on screen into PNG bytes. Overridden in tests.
final shareCardCaptureProvider =
    Provider<Future<Uint8List> Function(GlobalKey)>(
      (ref) => captureShareCardPng,
    );

/// What happened to the share sheet.
class ShareCardResult {
  const ShareCardResult({required this.shared, required this.target});

  static const failed = ShareCardResult(shared: false, target: 'failed');

  final bool shared;

  /// `kakao`, `instagram`, `save`, `copy`, `other` or `unknown`.
  final String target;
}

/// The `target` param of `share_card_shared` from share_plus' raw result
/// (the Android package / iOS activity type the user picked).
String shareCardTargetFromRaw(String raw) {
  final value = raw.toLowerCase();
  if (value.isEmpty || value.contains('share/unavailable')) return 'unknown';
  if (value.contains('kakao')) return 'kakao';
  if (value.contains('instagram')) return 'instagram';
  if (value.contains('savetocameraroll') || value.contains('gallery')) {
    return 'save';
  }
  if (value.contains('copytopasteboard') || value.contains('clipboard')) {
    return 'copy';
  }
  return 'other';
}

/// Opens the system share sheet with the card image. Overridden in tests.
abstract class ShareCardSharer {
  Future<ShareCardResult> sharePng(
    Uint8List png, {
    required String text,
    Rect? origin,
  });
}

class SharePlusShareCardSharer implements ShareCardSharer {
  SharePlusShareCardSharer({
    required ShareCardTempFiles files,
    Future<ShareResult> Function(ShareParams params)? share,
  }) : _files = files,
       _share = share ?? SharePlus.instance.share;

  final ShareCardTempFiles _files;

  /// The system share sheet (`SharePlus.instance.share`); a seam for tests.
  final Future<ShareResult> Function(ShareParams params) _share;

  @override
  Future<ShareCardResult> sharePng(
    Uint8List png, {
    required String text,
    Rect? origin,
  }) async {
    final file = await _files.writeCard(png);
    final ShareResult result;
    try {
      result = await _share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: text,
          sharePositionOrigin: origin,
        ),
      );
    } finally {
      // The share sheet is done with it (Android shares its own copy), so
      // the card, which may hold my partner's photo, doesn't stay behind.
      await _files.deleteCard();
    }
    switch (result.status) {
      case ShareResultStatus.dismissed:
        return const ShareCardResult(shared: false, target: 'dismissed');
      case ShareResultStatus.success:
        return ShareCardResult(
          shared: true,
          target: shareCardTargetFromRaw(result.raw),
        );
      case ShareResultStatus.unavailable:
        return const ShareCardResult(shared: true, target: 'unknown');
    }
  }
}

final shareCardSharerProvider = Provider<ShareCardSharer>(
  (ref) =>
      SharePlusShareCardSharer(files: ref.watch(shareCardTempFilesProvider)),
);

/// Whether [partnerUid] lets their 인증샷 go on the share cards I make
/// (`users/{partnerUid}.allowPartnerPhotoInShareCard`, missing = false).
/// Read from the server (never the offline cache) when the sheet opens and
/// again right before a together card is captured, so a partner who turned
/// it off is not on the next card. Any failure, offline included, is false.
/// Overridden in tests.
final shareCardPartnerConsentProvider =
    Provider<Future<bool> Function(String partnerUid)>(
      (ref) => (partnerUid) async {
        try {
          return await ref
              .read(userRepositoryProvider)
              .fetchPartnerPhotoShareConsent(partnerUid)
              .timeout(kShareCardPhotoTimeout);
        } catch (e) {
          debugPrint('[DuoShareSheet] partner photo consent unknown: $e');
          return false;
        }
      },
    );

/// My partner's plans, or null without a partner or while they load.
final partnerDuoPlansProvider = Provider.autoDispose<List<Plan>?>((ref) {
  final partnerUid = ref.watch(
    partnerLabelProvider.select((label) => label.partnerUid),
  );
  if (partnerUid == null) return null;
  return ref.watch(duoPlansProvider(partnerUid)).value;
});

// ---------------------------------------------------------------------------
// The sheet
// ---------------------------------------------------------------------------

/// The card data from the current stats, without the photo; null without a
/// partner or before the stats load.
DuoShareCardData? duoShareCardDataOf(WidgetRef ref, AppLocalizations l10n) {
  final stats = ref.read(duoStatsProvider);
  if (stats == null || !stats.hasPartner) return null;
  final label = ref.read(partnerLabelProvider);
  return DuoShareCardData(
    streak: stats.streak,
    date: stats.today.date,
    meLabel: l10n.duoMeLabel,
    // The nickname is mine to share; the partner's real name is not.
    partnerLabel:
        normalizePartnerNickname(label.nickname) ??
        l10n.partnerFallbackLabelStart,
    me: stats.today.me,
    partner: stats.today.partner,
  );
}

/// Shows the share card with [공유하기] / [다음에]. Returns whether it was
/// shared. Does nothing (false) without a partner.
Future<bool> showDuoShareCardSheet(
  BuildContext context,
  WidgetRef ref, {
  required DuoShareTrigger trigger,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final data = duoShareCardDataOf(ref, l10n);
  if (data == null) return false;
  // The single layout: only my own photo, and only the card day's. The
  // partner's joins only in the together layout, when they allowed it.
  final photoPath = shareCardProofPhotoPathOf(
    ref.read(myDuoPlansProvider) ?? const [],
    day: data.date,
  );
  String? myUid;
  try {
    myUid = ref.read(myProfileProvider).value?.uid;
  } catch (_) {
    // No profile: no together layout.
  }
  final partnerUid = ref.read(partnerLabelProvider).partnerUid;
  final shared = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DuoShareSheet(
      data: data,
      trigger: trigger,
      photoPath: photoPath,
      myUid: myUid,
      partnerUid: partnerUid,
    ),
  );
  return shared ?? false;
}

/// How long the sheet waits for my photo before sharing the card without it.
const Duration kShareCardPhotoTimeout = Duration(seconds: 4);

class DuoShareSheet extends ConsumerStatefulWidget {
  const DuoShareSheet({
    super.key,
    required this.data,
    required this.trigger,
    this.photoPath,
    this.myUid,
    this.partnerUid,
  });

  final DuoShareCardData data;
  final DuoShareTrigger trigger;

  /// My latest proof photo (Storage path), loaded while the sheet is open.
  final String? photoPath;

  /// Me and my partner, for the together layout; without either the sheet
  /// only offers the single layout.
  final String? myUid;
  final String? partnerUid;

  @override
  ConsumerState<DuoShareSheet> createState() => _DuoShareSheetState();
}

class _DuoShareSheetState extends ConsumerState<DuoShareSheet> {
  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _shareButtonKey = GlobalKey();
  bool _busy = false;
  Uint8List? _photo;
  bool _photoLoading = false;

  /// Whether my partner allows their photo on my cards; null until known.
  bool? _partnerAllowed;

  /// The together layout's photos (mine may be an earlier day's than
  /// [_photo]); both or neither.
  Uint8List? _togetherMine;
  Uint8List? _togetherPartner;
  ShareCardLayout _layout = ShareCardLayout.single;

  @override
  void initState() {
    super.initState();
    _photo = widget.data.photo;
    final path = widget.photoPath;
    if (_photo == null && path != null) {
      _photoLoading = true;
      _loadPhoto(path);
    }
    _loadTogether();
  }

  List<ShareCardLayout> get _layouts => shareCardLayoutsOf(
    partnerAllowed: _partnerAllowed ?? false,
    hasMyPhoto: _togetherMine != null,
    hasPartnerPhoto: _togetherPartner != null,
  );

  ShareCardLayout get _effectiveLayout =>
      _layouts.contains(_layout) ? _layout : ShareCardLayout.single;

  /// Asks whether my partner allowed it, then loads both photos. Any failure
  /// (no consent, no photo, Storage denies an older photo, slow network)
  /// just leaves the single layout.
  Future<void> _loadTogether() async {
    final myUid = widget.myUid;
    final partnerUid = widget.partnerUid;
    if (myUid == null || partnerUid == null) return;
    var allowed = false;
    try {
      allowed = await ref
          .read(shareCardPartnerConsentProvider)(partnerUid)
          .timeout(kShareCardPhotoTimeout);
    } catch (e) {
      debugPrint('[DuoShareSheet] partner photo consent unknown: $e');
    }
    if (!mounted) return;
    setState(() => _partnerAllowed = allowed);
    if (!allowed) return;

    final paths = shareCardTogetherPhotoPathsOf(
      partnerAllowed: allowed,
      myUid: myUid,
      partnerUid: partnerUid,
      myPlans: ref.read(myDuoPlansProvider) ?? const [],
      partnerPlans: ref.read(partnerDuoPlansProvider) ?? const [],
      day: widget.data.date,
    );
    if (paths == null) return;
    try {
      final cache = ref.read(proofPhotoCacheProvider);
      final photos = await Future.wait([
        cache.load(paths.mine),
        cache.load(paths.partner),
      ]).timeout(kShareCardPhotoTimeout);
      if (!mounted) return;
      setState(() {
        _togetherMine = photos[0];
        _togetherPartner = photos[1];
      });
    } catch (e) {
      debugPrint('[DuoShareSheet] single layout only: $e');
    }
  }

  /// A slow or missing photo just means a card without it.
  Future<void> _loadPhoto(String path) async {
    Uint8List? bytes;
    try {
      bytes = await ref
          .read(proofPhotoCacheProvider)
          .load(path)
          .timeout(kShareCardPhotoTimeout);
    } catch (e) {
      debugPrint('[DuoShareSheet] no photo on the card: $e');
    }
    if (!mounted) return;
    setState(() {
      _photo = bytes;
      _photoLoading = false;
    });
  }

  DuoShareCardData get _data {
    final data = widget.data;
    return DuoShareCardData(
      streak: data.streak,
      date: data.date,
      meLabel: data.meLabel,
      partnerLabel: data.partnerLabel,
      me: data.me,
      partner: data.partner,
      photo: _effectiveLayout == ShareCardLayout.together
          ? _togetherMine
          : _photo,
      partnerPhoto: _effectiveLayout == ShareCardLayout.together
          ? _togetherPartner
          : null,
    );
  }

  String _title(AppLocalizations l10n) {
    switch (widget.trigger) {
      case DuoShareTrigger.today:
        return l10n.shareCardSheetTitleToday;
      case DuoShareTrigger.milestone:
        return l10n.shareCardSheetTitleMilestone(widget.data.streak);
      case DuoShareTrigger.manual:
        return l10n.shareCardSheetTitleManual;
    }
  }

  Rect? _origin() {
    final box = _shareButtonKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Asks the server again, right before a together card is captured.
  Future<bool> _partnerStillAllows() async {
    final partnerUid = widget.partnerUid;
    if (partnerUid == null) return false;
    return ref.read(shareCardPartnerConsentProvider)(partnerUid);
  }

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final card = _data;
    try {
      if (card.layout == ShareCardLayout.together &&
          !await _partnerStillAllows()) {
        // They turned it off while the sheet was open: show the single card
        // (and the consent hint) instead of sharing what they withdrew.
        if (mounted) {
          setState(() {
            _partnerAllowed = false;
            _togetherMine = null;
            _togetherPartner = null;
            _busy = false;
          });
        }
        return;
      }
      if (!mounted) return;
      final photos = [?card.photo, ?card.partnerPhoto];
      if (photos.isNotEmpty) {
        // Make sure the photos are decoded and painted before the capture.
        try {
          await Future.wait([
            for (final photo in photos)
              precacheImage(MemoryImage(photo), context),
          ]).timeout(const Duration(seconds: 2));
          await WidgetsBinding.instance.endOfFrame;
        } catch (_) {
          // Capture whatever is on screen.
        }
      }
      if (!mounted) return;
      final png = await ref.read(shareCardCaptureProvider)(_cardKey);
      final result = await ref
          .read(shareCardSharerProvider)
          .sharePng(png, text: l10n.shareCardText, origin: _origin());
      if (result.shared) {
        AnalyticsService.log(AnalyticsEvent.shareCardShared, {
          'target': result.target,
          'trigger': widget.trigger.id,
          'streak': widget.data.streak,
          'layout': card.layout.id,
        });
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
    } catch (e) {
      debugPrint('[DuoShareSheet] share failed: $e');
      messenger?.showSnackBar(SnackBar(content: Text(l10n.shareCardFailed)));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final layouts = _layouts;
    final layout = _effectiveLayout;
    // Preview height: whatever fits next to the title, the layout toggle
    // and the buttons.
    final previewHeight =
        (media.size.height * 0.56 - (layouts.length > 1 ? 48 : 0)).clamp(
          200.0,
          520.0,
        );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, media.viewPadding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.disabled,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _title(l10n),
            key: const ValueKey('share-sheet-title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: previewHeight,
            child: FittedBox(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: RepaintBoundary(
                  key: _cardKey,
                  child: DuoShareCard(data: _data),
                ),
              ),
            ),
          ),
          if (layouts.length > 1) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final option in layouts)
                  ChoiceChip(
                    key: ValueKey('share-layout-${option.id}'),
                    label: Text(switch (option) {
                      ShareCardLayout.single =>
                        l10n.sharePhotoConsentLayoutSingle,
                      ShareCardLayout.together =>
                        l10n.sharePhotoConsentLayoutTogether,
                    }),
                    selected: layout == option,
                    onSelected: _busy
                        ? null
                        : (_) => setState(() => _layout = option),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            layout == ShareCardLayout.together
                ? l10n.sharePhotoConsentTogetherNote
                : l10n.shareCardOnlyMyPhoto,
            key: const ValueKey('share-sheet-photo-note'),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          if (_partnerAllowed == false) ...[
            const SizedBox(height: 2),
            Text(
              l10n.sharePhotoConsentHint,
              key: const ValueKey('share-sheet-consent-hint'),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textDisabled, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: _shareButtonKey,
              onPressed: (_busy || _photoLoading) ? null : _share,
              icon: (_busy || _photoLoading)
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.ios_share_rounded, size: 18),
              label: Text(
                l10n.shareCardShare,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          TextButton(
            key: const ValueKey('share-sheet-later'),
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: Text(l10n.shareCardLater),
          ),
        ],
      ),
    );
  }
}

/// The Us-tab button that opens the share card.
class DuoShareButton extends ConsumerWidget {
  const DuoShareButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return TextButton.icon(
      key: const ValueKey('duo-share-button'),
      onPressed: () =>
          showDuoShareCardSheet(context, ref, trigger: DuoShareTrigger.manual),
      icon: Icon(Icons.ios_share_rounded, size: 16, color: AppColors.primary),
      label: Text(
        l10n.duoShareButton,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
