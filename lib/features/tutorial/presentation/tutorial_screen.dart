import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  static const _pages = [
    _TutorialPageData(
      icon: Icons.edit_note_rounded,
      title: '할 일을 작게 정해요',
      body: '막연한 목표 대신 오늘 바로 할 수 있는 약속 하나를 만들어요. 작게 시작해야 진짜로 움직일 수 있어요.',
    ),
    _TutorialPageData(
      icon: Icons.handshake_outlined,
      title: '혼자 버티지 않아요',
      body: '필요하면 파트너와 연결해서 실천 여부를 확인받아요. 부담은 줄이고, 실행감은 남깁니다.',
    ),
    _TutorialPageData(
      icon: Icons.insights_rounded,
      title: '기록으로 다음을 정해요',
      body: '성공과 미룸을 기록해 다음 약속의 크기를 조정해요. 실패도 다음 설계의 재료가 됩니다.',
    ),
  ];

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
    if (_index == _pages.length - 1) {
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
    final isLast = _index == _pages.length - 1;

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
                  child: Text(isLast ? '닫기' : '건너뛰기'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, pageIndex) {
                    final page = _pages[pageIndex];
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
                children: List.generate(_pages.length, (dotIndex) {
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
                  child: Text(isLast ? '그래, 시작하기' : '다음'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '처음엔 작은 약속 하나면 충분해요.',
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
