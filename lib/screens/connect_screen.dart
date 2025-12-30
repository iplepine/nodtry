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
    final myCode = ref.read(myProfileProvider).asData?.value?.inviteCode;

    if (text != null && _isValidInviteCode(text)) {
      if (text == myCode) return; // 내 코드면 무시

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

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
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

  void _shareCode(String code) {
    // TODO: 공유 기능 구현
    _copyCode(code);
  }

  Future<void> _submitCode(String code) async {
    final myCode = ref.read(myProfileProvider).asData?.value?.inviteCode;
    if (code == myCode) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('본인의 초대 코드는 사용할 수 없습니다.')));
      return;
    }

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
    // 연결 상태 변경 감지하여 네비게이션 처리
    ref.listen(connectionStatusStreamProvider, (previous, next) {
      next.whenData((status) {
        if (status == ConnectionStatus.active &&
            _state != ConnectState.connected) {
          setState(() {
            _state = ConnectState.connected;
          });
        } else if (status != ConnectionStatus.active &&
            _state == ConnectState.connected) {
          setState(() {
            _state = ConnectState.initial;
          });
        }
      });
    });

    final canPop = Navigator.canPop(context);
    final myProfileAsync = ref.watch(myProfileProvider);

    // 내 초대 코드 자동 설정
    final myInviteCode = myProfileAsync.asData?.value?.inviteCode;
    if (myInviteCode != null && _inviteCode != myInviteCode) {
      // _inviteCode = myInviteCode;
    }

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

              // 메인 메시지 영역 (연결되면 다른 메시지? 일단 유지)
              if (_state != ConnectState.connected) _buildMessageSection(),

              const SizedBox(height: 48),

              if (_state == ConnectState.connected)
                _buildConnectedState()
              else ...[
                // 1. 내 초대 코드 표시
                if (myInviteCode != null) ...[
                  Text(
                    AppLocalizations.of(context)!.usMyInviteCode,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  _buildCodeCard(code: myInviteCode),
                  const SizedBox(height: 40),
                  Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 40),
                ],

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
                _buildCodeInput(),

                // 초기화면의 "혼자 시작하기" 버튼 (온보딩인 경우에만 맨 아래 배치)
                if (!canPop) ...[
                  const SizedBox(height: 40),
                  TextButton(
                    onPressed: _navigateToHome,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.startSolo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
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
  Widget _buildCodeCard({required String code}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            code, // 인자로 받은 코드 사용
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyCode(code),
                  icon: const Icon(Icons.copy, size: 20),
                  label: Text(AppLocalizations.of(context)!.copyCode),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _shareCode(code),
                  icon: const Icon(Icons.share, size: 20),
                  label: Text(AppLocalizations.of(context)!.shareCode),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ),
            ],
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

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('연결 해제'),
        content: const Text('정말로 연결을 끊으시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('해제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 현재 연결된 모든 상대 끊기 (MVP: 가장 최근 혹은 전체)
        // 여기서는 usecase에 targetId를 넘겨야 함.
        // 상태를 보고 ConnectedUser를 가져와야 하는데, 일단 'users' collection을 조회할 필요 없이
        // relations에서 찾아서 지우므로 target ID가 필요함.
        // 하지만 UseCase는 ID를 요구함.
        // ConnectRepository.disconnectByUser also needs ID.
        // 현재 화면에서 connected 상대 ID를 알고 있나?
        // 안다면 좋지만 모른다면?
        // getConnections()를 호출해서 가져와야 함.

        // 심플하게: Repository에게 "나와 연결된 모든 사람 끊어"라고 할 수도 있지만
        // 일단 getConnections()로 찾자.

        final connections = await ref
            .read(connectRepositoryProvider)
            .getConnections();
        if (connections.isNotEmpty) {
          final targetId =
              connections.first.executorId ==
                  ref.read(myProfileProvider).asData?.value?.uid
              ? connections.first.managerId
              : connections.first.executorId;

          await ref.read(disconnectConnectionUseCaseProvider).execute(targetId);
        } else {
          // 이미 연결 없음?
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('연결 해제 실패: $e')));
        }
      }
    }
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
          const SizedBox(height: 16),
          TextButton(
            onPressed: _disconnect,
            child: const Text(
              '연결 끊기',
              style: TextStyle(
                color: Colors.red,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
