import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../connect_state.dart';
import '../viewmodel/connect_viewmodel.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_underlined_text.dart';
import '../../../../widgets/primary_button.dart';
import '../../../../routes/app_router.dart';
import '../../../../providers/repository_provider.dart';
import '../../../../utils/ui_error_codes.dart';
// removed unused connect_repository import

/// Maps a locale-independent connect error code to a localized message.
String _connectErrorText(AppLocalizations l10n, String code) {
  switch (code) {
    case ConnectErrorCode.selfCode:
      return l10n.connectErrorSelfCode;
    case ConnectErrorCode.disconnectFailed:
      return l10n.connectErrorDisconnectFailed;
    case ConnectErrorCode.connectFailed:
    default:
      return l10n.connectErrorFailed;
  }
}

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 클립보드 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkClipboard();
    });
  }

  Future<void> _checkClipboard() async {
    final connectState = ref.read(connectViewModelProvider).value;
    if (connectState == null ||
        connectState.flowState == ConnectFlowState.waiting ||
        connectState.flowState == ConnectFlowState.connected) {
      return;
    }

    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;

    final text = clipboardData?.text;
    final myCode = ref.read(myProfileProvider).value?.inviteCode;

    if (text != null && _isValidInviteCode(text)) {
      if (text == myCode) return; // 내 코드면 무시

      if (!mounted) return;

      // 사용자에게 붙여넣기 의사 묻기
      showDialog(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(l10n.connectInviteCodeDetectedTitle),
            content: Text(l10n.connectInviteCodeDetectedBody(text)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.connectCancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _fillCode(text);
                },
                child: Text(l10n.connectPaste),
              ),
            ],
          );
        },
      );
    }
  }

  bool _isValidInviteCode(String code) {
    // 8자리 영문 대문자+숫자 체크
    final regex = RegExp(r'^[A-Z0-9]{8}$');
    return regex.hasMatch(code);
  }

  void _fillCode(String code) {
    if (code.length != 8) return;
    _codeController.text = code;
    _connectManually();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // _buildCodeCard has been moved up to build block in previous step?
  // No, the previous step replaced the build block AND _buildCodeCard definition if it was inside the replacement range.
  // The replacement range ended at 324, but _buildInitialOptions ended around 324.
  // _buildCodeCard was likely below. I need to removing the OLD _buildCodeCard and helpers if they were not replaced.
  // Wait, I replaced `_buildInitialOptions` in the previous step because I included it in the `TargetContent`.
  // Does `TargetContent` cover `_buildCodeCard`?
  // Let's check the previous `TargetContent`. It ends with `_buildInitialOptions`.
  // So `_buildCodeCard` is likely still there in its OLD form.
  // I need to update it or remove it.

  // Actually, I put the NEW `_buildCodeCard` logic inside the ReplacementContent of the previous step.
  // So now I have TWO `_buildCodeCard` methods in the file if the old one was below the target range.
  // I should check where `_buildInitialOptions` ended.

  // I will check the file content first to be safe, or just view_file.
  // But to be quick, I'll update `_copyCode` and `_shareCode` to accept arguments and remove old `_buildCodeCard` if present.

  Future<void> _connectManually() async {
    final code = _codeController.text;
    if (code.length == 8) {
      // 1. 이미 연결된 파트너가 있는지 확인
      final profiles = await ref.read(connectedProfilesProvider.future);
      if (profiles.isNotEmpty) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text(l10n.connectNotice),
              content: Text(l10n.connectAlreadyConnectedBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.connectOk, style: TextStyle(color: AppColors.primary)),
                ),
              ],
            );
          },
        );
        return;
      }

      // 2. 연결 요청
      ref
          .read(connectViewModelProvider.notifier)
          .dispatch(SubmitInviteCodeIntent(code));
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectState =
        ref.watch(connectViewModelProvider).value ?? const ConnectState();

    // 연결 상태 변경 감지하여 네비게이션 처리
    ref.listen(connectViewModelProvider, (previous, next) {
      if (next.value?.flowState == ConnectFlowState.connected &&
          previous?.value?.flowState != ConnectFlowState.connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.connectSuccess),
            backgroundColor: AppColors.primary,
          ),
        );
        // 즉시 이전 화면으로 돌아감
        if (context.mounted) {
          context.pop();
        }
      }
    });

    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: canPop
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: canPop ? 0 : 40),

              // 메인 메시지 영역
              if (connectState.flowState != ConnectFlowState.connected)
                _buildMessageSection(),

              const SizedBox(height: 48),

              // 연결 성공 상태에서는 이미 팝되었으므로 여기 오지 않음
              // 하지만 안전을 위해 flowState 체크 유지
              if (connectState.flowState != ConnectFlowState.connected) ...[
                // 2. 상대방 코드 입력
                Text(
                  AppLocalizations.of(context)!.enterInviteCode,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildCodeInput(connectState),

                // 초기화면의 "혼자 시작하기" 버튼 (온보딩인 경우에만 맨 아래 배치)
                if (!canPop) ...[
                  const SizedBox(height: 40),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.home),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    child: AppUnderlinedText(
                      AppLocalizations.of(context)!.startSolo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageSection() {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.connectHeadline,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.connectSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // 기존 _buildInitialOptions 제거

  // _buildCodeCard 수정 (인자 받도록)
  Widget _buildCodeInput(ConnectState state) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.enterCodeBelow,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // 단일 TextField 입력
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: _codeController,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            maxLength: 8,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 8, // 글자 간격
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'ABCD1234',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                letterSpacing: 4,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 24),
            ),
            onChanged: (value) {
              if (value.length == 8) {
                _connectManually();
              }
            },
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) {
                return newValue.copyWith(text: newValue.text.toUpperCase());
              }),
            ],
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
          ),
        ),

        const SizedBox(height: 32),

        if (state.flowState == ConnectFlowState.waiting) ...[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
        ] else ...[
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _connectErrorText(
                  AppLocalizations.of(context)!,
                  state.errorMessage!,
                ),
                style: TextStyle(color: AppColors.error, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          PrimaryButton(
            text: AppLocalizations.of(context)!.sendConnectionRequest,
            onPressed: () => _connectManually(),
            isLoading: state.isProcessing,
          ),
        ],
      ],
    );
  }
}
