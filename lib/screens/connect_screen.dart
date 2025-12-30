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
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

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
    // 6자리 영문 대문자+숫자 체크
    final regex = RegExp(r'^[A-Z0-9]{6}$');
    return regex.hasMatch(code);
  }

  void _fillCode(String code) {
    if (code.length != 6) return;

    setState(() {
      _state = ConnectState.codeEntered;
    });

    for (int i = 0; i < 6; i++) {
      _codeControllers[i].text = code[i];
    }
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _generateCode() async {
    try {
      // 내 프로필에서 기존 초대 코드 가져오기
      final useCase = ref.read(getMyProfileUseCaseProvider);
      final user = await useCase.execute();

      if (user?.inviteCode != null && mounted) {
        setState(() {
          _inviteCode = user!.inviteCode!;
          _state = ConnectState.codeGenerated;
        });
      } else {
        // 코드가 없는 경우 (예외 상황)
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

  void _onCodeChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    // 모든 칸이 채워지면 연결 요청
    if (_codeControllers.every((controller) => controller.text.isNotEmpty)) {
      // 자동 제출하지 않음 (버튼 클릭 유도)
    }
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
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length == 6) {
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

    // Watch connection status stream (UI 업데이트용 - 현재는 _state로 관리되어 크게 필요 없으나 미래를 위해)
    // final statusAsync = ref.watch(connectionStatusStreamProvider);

    // Status에 따른 화면 전환 로직
    // build 내에서 부수 효과(네비게이션 등)를 직접 일으키는 건 지양해야 함.
    // 하지만 상태값(_state) 변경은 가능.

    // statusAsync.whenData((status) {
    //   if (status == ConnectionStatus.active &&
    //       _state != ConnectState.connected) {
    //     // 연결 완료
    //     WidgetsBinding.instance.addPostFrameCallback((_) {
    //       if (mounted) {
    //         setState(() {
    //           _state = ConnectState.connected;
    //         });
    //       }
    //     });
    //   } else if (status == ConnectionStatus.pending &&
    //       _state != ConnectState.waiting) {
    //     // 대기 중 (이미 _submitCode에서 설정했지만, 스트림 소스일 경우 동기화)
    //     // 여기서는 UI 로컬 상태와 Provider 상태가 섞여 있어 조심해야 함.
    //   }
    // });

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
              if (_state == ConnectState.codeEntered) _buildCodeInput(),

              // 연결 대기 중
              if (_state == ConnectState.waiting) _buildWaitingState(),

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
          Text(
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
        // 6칸 코드 입력 필드
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 48,
              child: TextField(
                controller: _codeControllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                maxLength: 1,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  counterText: '',
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
                ),
                onChanged: (value) => _onCodeChanged(index, value),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          text: AppLocalizations.of(context)!.sendConnectionRequest,
          onPressed: _connectManually,
        ),
      ],
    );
  }

  Widget _buildWaitingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.waitingForConnection,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
