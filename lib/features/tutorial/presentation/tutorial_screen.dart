import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({
    super.key,
    this.onFinished,
    this.showBackButton = true,
  });

  final VoidCallback? onFinished;
  final bool showBackButton;

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  /// This screen is shown before sign-in, so it is the very first thing a new
  /// user sees — resolve the copy against the active locale rather than
  /// hardcoding it.
  static List<_TutorialPageData> _pagesFor(AppLocalizations l10n) => [
    _TutorialPageData(
      icon: Icons.edit_note_rounded,
      title: l10n.tutorialPage1Title,
      body: l10n.tutorialPage1Body,
    ),
    _TutorialPageData(
      icon: Icons.handshake_outlined,
      title: l10n.tutorialPage2Title,
      body: l10n.tutorialPage2Body,
    ),
    _TutorialPageData(
      icon: Icons.insights_rounded,
      title: l10n.tutorialPage3Title,
      body: l10n.tutorialPage3Body,
    ),
  ];

  static const _pageCount = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    final callback = widget.onFinished;
    if (callback != null) {
      callback();
      return;
    }
    if (context.canPop()) {
      context.pop();
    }
  }

  void _next() {
    if (_index == _pageCount - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _pagesFor(l10n);
    final isLast = _index == pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showBackButton
          ? AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  child: Text(isLast ? l10n.tutorialClose : l10n.tutorialSkip),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, pageIndex) {
                    final page = pages[pageIndex];
                    return Column(
                      children: [
                        const Spacer(),
                        Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AppColors.divider,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.10,
                                ),
                                blurRadius: 28,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Icon(
                            page.icon,
                            color: AppColors.primary,
                            size: 62,
                          ),
                        ),
                        const SizedBox(height: 34),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 330),
                          child: Text(
                            page.body,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.58,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (dotIndex) {
                  final selected = dotIndex == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: selected ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  child: Text(isLast ? l10n.tutorialStart : l10n.tutorialNext),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.tutorialFooter,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialPageData {
  const _TutorialPageData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
