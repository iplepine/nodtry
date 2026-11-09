part of '../us_screen.dart';

/// Us 헤더 카드 — 두 사람의 공동 정체성을 시각화하는 진입 카드.
/// 김민서 페르소나의 권고: "Me / You가 병렬로 나열되어 '우리'가 어디에도 없다.
/// 두 거실을 잇는 같이 보는 창문 하나가 필요하다."
///
/// With the duo stats in (spec §4.7): "둘이 함께 N일째", this week's dots for
/// both of us and the share-card button.
class _UsHeroCard extends StatelessWidget {
  final String myName;
  final String? myImageUrl;
  final String partnerName;
  final String? partnerImageUrl;
  final DuoStats? stats;
  final AppLocalizations l10n;

  const _UsHeroCard({
    required this.myName,
    required this.myImageUrl,
    required this.partnerName,
    required this.partnerImageUrl,
    required this.stats,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final stats = this.stats;
    final hasStats = stats != null && stats.hasPartner;
    return Container(
      key: const ValueKey('us-hero'),
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 두 아바타 겹침 — 시각적 공동 정체성의 핵심 모티프.
              SizedBox(
                width: 80,
                height: 44,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      child: _HeroAvatar(imageUrl: myImageUrl, name: myName),
                    ),
                    Positioned(
                      left: 36,
                      child: _HeroAvatar(
                        imageUrl: partnerImageUrl,
                        name: partnerName,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$myName · $partnerName',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasStats
                          ? duoStreakHeadline(l10n, stats.streak)
                          : l10n.usHeroSubtitle,
                      key: const ValueKey('us-hero-streak'),
                      style: TextStyle(
                        color: hasStats
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: hasStats ? 14 : 12,
                        fontWeight: hasStats
                            ? FontWeight.w800
                            : FontWeight.w400,
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasStats) ...[
            const SizedBox(height: 14),
            DuoWeekDots(
              week: stats.week,
              showPartner: true,
              meLabel: l10n.duoMeLabel,
              partnerLabel: partnerName,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    stats.todayIsDuoDone
                        ? l10n.duoTodayDone
                        : l10n.duoWeekDuoDays(stats.weekDuoDays),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const DuoShareButton(),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;

  const _HeroAvatar({required this.imageUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    const radius = 22.0;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.background, width: 2),
        ),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          imageBuilder: (context, imageProvider) =>
              CircleAvatar(radius: radius, backgroundImage: imageProvider),
          placeholder: (context, url) => CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          ),
          errorWidget: (context, url, error) => _initialAvatar(radius),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.background, width: 2),
      ),
      child: _initialAvatar(radius),
    );
  }

  Widget _initialAvatar(double radius) {
    final initial = (name?.trim().isNotEmpty ?? false)
        ? String.fromCharCode(name!.trim().runes.first)
        : null;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
      child: initial != null
          ? Text(
              initial,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryPressed,
              ),
            )
          : Icon(
              Icons.person_rounded,
              size: 20,
              color: AppColors.primaryPressed,
            ),
    );
  }
}
