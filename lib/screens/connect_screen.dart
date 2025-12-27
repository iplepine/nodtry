import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import 'home_screen.dart';

enum ConnectState {
  initial, // 초기 상태 - 코드 생성/입력 선택
  codeGenerated, // 코드 생성됨 (초대자)
  codeEntered, // 코드 입력됨 (참여자)
  waiting, // 연결 대기 중
  connected, // 연결 완료
}

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  ConnectState _state = ConnectState.initial;
  String _inviteCode = '';
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

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

  void _generateCode() {
    // 6자리 코드 생성 (숫자/영문)
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = DateTime.now().millisecondsSinceEpoch;
    final code = List.generate(6, (index) {
      return chars[(random + index) % chars.length];
    }).join();
    
    setState(() {
      _inviteCode = code;
      _state = ConnectState.codeGenerated;
    });
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _inviteCode));
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
      final enteredCode = _codeControllers.map((c) => c.text).join();
      _submitCode(enteredCode);
    }
  }

  void _submitCode(String code) {
    setState(() {
      _state = ConnectState.codeEntered;
    });
    
    // TODO: 서버에 연결 요청 전송
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _state = ConnectState.waiting;
        });
        
        // 임시: 연결 완료 시뮬레이션 (3초 후 홈 화면으로 이동)
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _navigateToHome();
          }
        });
      }
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  void _connectManually() {
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length == 6) {
      _submitCode(code);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
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
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
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
          Icon(
            Icons.check_circle,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Connected!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Go to Home',
            onPressed: _navigateToHome,
          ),
        ],
      ),
    );
  }
}

