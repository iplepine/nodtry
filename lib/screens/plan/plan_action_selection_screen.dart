import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/progress_hint_bar.dart';
import '../../widgets/primary_button.dart';
import '../../routes/app_router.dart';
import '../../l10n/app_localizations.dart';

/// Screen 1: 행동 선택 화면
///
/// "한 가지 약속만 정해볼까요?"
class PlanActionSelectionScreen extends StatefulWidget {
  const PlanActionSelectionScreen({super.key});

  @override
  State<PlanActionSelectionScreen> createState() =>
      _PlanActionSelectionScreenState();
}

class _PlanActionSelectionScreenState extends State<PlanActionSelectionScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.planMyPromise,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // 진행 힌트 바
          ProgressHintBar(
            hint: l10n.planPreparing,
            currentStep: 1,
            totalSteps: 5,
          ),

          // 본문
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 타이틀
                  Text(
                    l10n.planWhatToPromise,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.planPromiseHint,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 직접 입력 필드 (메인)
                  TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: l10n.planActionHint,
                      hintStyle: TextStyle(
                        color: AppColors.textDisabled,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.divider,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.divider,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    onChanged: (value) {
                      setState(() {
                        // 입력값 변경 시 UI 업데이트
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // 하단 버튼
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.divider, width: 1),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // 비활성 상태일 때 안내 문구
                  if (_textController.text.trim().isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        l10n.planOneLineEnough,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textDisabled,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  PrimaryButton(
                    text: l10n.planNext,
                    onPressed: _textController.text.trim().isNotEmpty
                        ? () {
                            // 다음 화면으로 이동 (직접 입력한 텍스트 전달)
                            final actionText = _textController.text.trim();
                            context.push(
                              '${AppRoutes.planFrequency}?action=${Uri.encodeComponent(actionText)}',
                            );
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
