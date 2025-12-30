import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import '../routes/app_router.dart';
import '../providers/repository_provider.dart';
import '../repositories/connect_repository.dart';
import '../models/user_model.dart';

enum ConnectState {
  initial, // 초기 상태 - 코드 생성/입력 선택
  codeGenerated, // 코드 생성됨 (초대자)
  codeEntered, // 코드 입력됨 (참여자)
  waiting, // 연결 대기 중
  connected, // 연결 완료
}

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  ConnectState _state = ConnectState.initial;
  String _inviteCode = '';
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
    // 연결 전 단계에서만 체크
    if (_state == ConnectState.waiting || _state == ConnectState.connected) {
      return;
    }

    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text;

    if (text != null && _isValidInviteCode(text)) {
      if (!mounted) return;

      // 사용자에게 붙여넣기 의사 묻기
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('초대 코드 감지'),
            content: Text('클립보드에서 초대 코드($text)를 발견했습니다.\n붙여넣으시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _fillCode(text);
                },
                child: const Text('붙여넣기'),
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

    setState(() {
      _state = ConnectState.codeEntered;
      _codeController.text = code;
    });

    _connectManually();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _generateCode() async {
    try {
      // 내 프로필에서 기존 초대 코드 가져오기 (Stream 처리)
      final useCase = ref.read(getMyProfileUseCaseProvider);
      UserModel? user;

      // Stream의 최신 데이터 대기 (캐시 -> 리모트 순으로 올 수 있음)
      // 화면에서는 'loading'을 보여주는 방식이 아니므로, 일단 첫 데이터라도 가져와서 보여줌
      // 여기서는 execute()가 닫힐 때까지 기다리는 것보다는,
      // myProfileProvider의 상태를 읽는 것이 더 나을 수도 있음.
      // 하지만 execute() 직접 호출 방식을 유지한다면:

      final stream = useCase.execute();
      await for (final u in stream) {
        if (u != null) {
          user = u;
          // 캐시 데이터가 오면 일단 보여주고, 나중에 리모트 데이터가 오면 갱신될 수도 있음.
          // 하지만 여기선 generateCode 버튼 클릭 시점이므로,
          // 가장 최신(혹은 캐시) 데이터를 받아서 할당.
          break; // 첫 유효 데이터만 받고 루프 종료 (빠른 반응성)
          // 만약 리모트까지 기다리려면 break 하지 않고 리모트 이벤트까지 수신해야 함.
          // 여기선 일단 첫 데이터(캐시)라도 있으면 보여줌.
        }
      }

      if (user?.inviteCode != null && mounted) {
        setState(() {
          _inviteCode = user!.inviteCode!;
          _state = ConnectState.codeGenerated;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('초대 코드를 찾을 수 없습니다.')));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('코드를 불러오는 중 오류가 발생했습니다: $e')));
    }
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _inviteCode));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.codeCopied),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareCode() {
    // TODO: 공유 기능 구현
    _copyCode();
  }

  Future<void> _submitCode(String code) async {
    setState(() {
      _state = ConnectState.codeEntered; // 입력 상태 유지
    });

    try {
      final repository = ref.read(connectRepositoryProvider);

      setState(() {
        _state = ConnectState.waiting;
      });

      await repository.connectWithCode(code);
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = ConnectState.codeEntered; // 다시 입력 대기
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('코드가 올바르지 않거나 연결에 실패했습니다.')));
      }
    }
  }

  void _navigateToHome() {
    context.go(AppRoutes.home);
  }

  void _connectManually() {
    final code = _codeController.text;
    if (code.length == 8) {
      _submitCode(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 연결 상태 변경 감지하여 네비게이션 처리
    ref.listen(connectionStatusStreamProvider, (previous, next) {
      next.whenData((status) {
        if (status == ConnectionStatus.active &&
            _state != ConnectState.connected) {
          setState(() {
            _state = ConnectState.connected;
          });
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // 메인 메시지 영역
              _buildMessageSection(),

              const SizedBox(height: 48),

              // 초기 상태: 코드 생성/입력 선택
              if (_state == ConnectState.initial) _buildInitialOptions(),

              // 코드 생성됨: 코드 표시
              if (_state == ConnectState.codeGenerated) _buildCodeCard(),

              // 코드 입력: 입력 필드
              if (_state == ConnectState.codeEntered ||
                  _state == ConnectState.waiting)
                _buildCodeInput(),

              // 연결 완료 (임시: 테스트용)
              if (_state == ConnectState.connected) _buildConnectedState(),

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

  Widget _buildInitialOptions() {
    return Column(
      children: [
        PrimaryButton(
          text: AppLocalizations.of(context)!.createInviteCode,
          onPressed: _generateCode,
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            setState(() {
              _state = ConnectState.codeEntered;
            });
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: BorderSide(color: AppColors.divider),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            AppLocalizations.of(context)!.enterInviteCode,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _navigateToHome,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: Text(
            AppLocalizations.of(context)!.startSolo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.inviteCode,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          // 코드 표시
          SelectableText(
            _inviteCode,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyCode,
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(AppLocalizations.of(context)!.copyCode),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareCode,
                  icon: const Icon(Icons.share, size: 18),
                  label: Text(AppLocalizations.of(context)!.shareCode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.codeShareMessage,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCodeInput() {
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
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
          ),
        ),

        const SizedBox(height: 32),

        if (_state == ConnectState.waiting) ...[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
        ] else
          PrimaryButton(
            text: AppLocalizations.of(context)!.sendConnectionRequest,
            onPressed: () => _connectManually(),
          ),
      ],
    );
  }

  Widget _buildConnectedState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, size: 48, color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.connectConnected,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: AppLocalizations.of(context)!.connectGoToHome,
            onPressed: _navigateToHome,
          ),
        ],
      ),
    );
  }
}
