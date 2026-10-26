import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../connect_state.dart';
import '../viewmodel/connect_viewmodel.dart';
import '../widgets/invite_confirm_sheet.dart';
import '../widgets/invite_share_panel.dart';
import '../widgets/partner_nickname_sheet.dart';
import '../../application/invite_services.dart';
import '../../application/partner_label_provider.dart';
import '../../application/partner_link_binder.dart';
import '../../domain/invite_code.dart';
import '../../../onboarding/domain/onboarding_gate.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/connected_user.dart';
import '../../../../models/user_model.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_underlined_text.dart';
import '../../../../routes/app_router.dart';
import '../../../../providers/repository_provider.dart';
import '../../../../repositories/connect_repository.dart';
import '../../../../utils/ui_error_codes.dart';
import '../../../../core/services/notification_service.dart';

/// Maps a locale-independent connect error code to a localized message.
String connectErrorText(AppLocalizations l10n, String code) {
  switch (code) {
    case ConnectErrorCode.selfCode:
      return l10n.connectErrorSelfCode;
    case ConnectErrorCode.disconnectFailed:
      return l10n.connectErrorDisconnectFailed;
    case ConnectErrorCode.codeNotFound:
      return l10n.connectErrorCodeNotFound;
    case ConnectErrorCode.codeFormat:
      return l10n.connectErrorCodeFormat;
    case ConnectErrorCode.ownerTaken:
      return l10n.connectErrorOwnerTaken;
    case ConnectErrorCode.selfTaken:
      return l10n.connectErrorSelfTaken;
    case ConnectErrorCode.codeChanged:
      return l10n.connectErrorCodeChanged;
    case ConnectErrorCode.linkUndone:
      return l10n.connectErrorLinkUndone;
    case ConnectErrorCode.connectFailed:
    default:
      return l10n.connectErrorFailed;
  }
}

/// The invite screen.
///
/// By default it is the inviter's screen: my code, big, with
/// "카톡으로 초대 보내기" (system share sheet) and "코드 복사", and a
/// "받은 코드가 있나요?" section below. [entryMode] puts code entry first (the
/// invitee's path from the tutorial link or an invite link).
///
/// Every code — typed, found on the clipboard or from a link — is looked up
/// first and confirmed with "{이름}의 운동 약속을 봐줄래요? [내가 봐줄게]".
/// After a link the screen turns into a success state and offers the
/// nickname sheet; the person who entered the code is then asked
/// "나도 걸래?".
class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({
    super.key,
    this.entryMode = false,
    this.initialCode,
    this.initialSource = InviteCodeSource.manual,
    this.prefetchedOwner,
    this.initialFailureReason,
  });

  final bool entryMode;

  /// `data.reason` of an opened `partner_connect_failed` push: why the last
  /// link didn't hold, shown above the code field.
  final String? initialFailureReason;

  /// A code to confirm right away (from a link or the clipboard).
  final String? initialCode;
  final InviteCodeSource initialSource;

  /// The owner of [initialCode] when the caller already looked it up.
  final UserModel? prefetchedOwner;

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// True from the moment a code is being checked until it resolves, so the
  /// keyboard action, the button and a clipboard/link code can't overlap.
  bool _isConnecting = false;

  /// Shows the spinner: a lookup or the link itself is in flight (not while
  /// the confirm sheet waits for the user).
  bool _isWorking = false;

  /// The last normalized code that was checked automatically, so editing a
  /// complete code doesn't re-open the confirm sheet on every keystroke.
  String? _lastAutoChecked;

  /// This device entered the code (the invitee).
  bool _submittedHere = false;
  bool _showSuccess = false;
  bool _nicknameOffered = false;
  String? _linkLostError;

  /// The code this device last submitted, to remember when its link is
  /// undone.
  String? _submittedCode;

  @override
  void initState() {
    super.initState();
    if (widget.initialFailureReason != null) {
      _linkLostError = ConnectErrorCode.forFailureReason(
        widget.initialFailureReason,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (!mounted) return;
    if (widget.entryMode) {
      // The pending entry was for this screen; don't send the user back here
      // after the next sign-in. Someone entering a code they got doesn't
      // need the "invite your partner" step on the next launch either.
      try {
        final store = ref.read(onboardingStoreProvider);
        await store.clearPendingCodeEntry();
        await store.markInviteStepDone();
      } catch (_) {}
    }
    if (!mounted) return;
    final initial = widget.initialCode;
    if (initial != null && initial.isNotEmpty) {
      _codeController.text = normalizeInviteCode(initial);
      await _redeem(
        initial,
        source: widget.initialSource,
        owner: widget.prefetchedOwner,
      );
      return;
    }
    if (widget.entryMode) _focusNode.requestFocus();
    await _checkClipboard();
  }

  /// A code found anywhere in the copied text (a whole share message works),
  /// read only after [InviteClipboard.hasStrings] says there is text.
  Future<void> _checkClipboard() async {
    final connectState = ref.read(connectViewModelProvider).value;
    if (connectState?.flowState == ConnectFlowState.waiting) return;
    final profiles = ref.read(connectedProfilesProvider).value;
    if (profiles != null && profiles.isNotEmpty) return;

    // Once per app run: every visit used to read the clipboard again (and
    // bring up the iOS paste prompt).
    final memory = ref.read(connectSessionMemoryProvider);
    if (memory.clipboardRead) return;

    final me = ref.read(myProfileProvider).value;
    final candidate = await ref
        .read(inviteCodeDetectorProvider)
        .fromClipboard(
          myCode: me?.inviteCode,
          myUid: me?.uid,
          onRead: () => memory.clipboardRead = true,
        );
    if (candidate == null || !mounted) return;
    if (memory.failedCodes.contains(candidate.code)) return;
    _codeController.text = candidate.code;
    _lastAutoChecked = candidate.code;
    await _redeem(
      candidate.code,
      source: InviteCodeSource.clipboard,
      owner: candidate.owner,
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<List<ConnectedUser>> _currentPartners() async {
    try {
      return await ref.read(connectedProfilesProvider.future);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _showAlreadyConnected() {
    return showDialog<void>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.connectNotice),
          content: Text(l10n.connectAlreadyConnectedBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.connectOk,
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Look up → confirm → connect.
  Future<void> _redeem(
    String rawCode, {
    required InviteCodeSource source,
    UserModel? owner,
  }) async {
    if (_isConnecting) return;
    setState(() {
      _isConnecting = true;
      _isWorking = true;
      _linkLostError = null;
    });
    try {
      // 1. 이미 연결된 짝꿍이 있으면 막는다 (1:1).
      final profiles = await _currentPartners();
      if (!mounted) return;
      if (profiles.isNotEmpty) {
        await _showAlreadyConnected();
        return;
      }

      final viewModel = ref.read(connectViewModelProvider.notifier);
      var code = normalizeInviteCode(rawCode);
      // A code whose link was just undone isn't tried again by itself (from a
      // link); typing it is still allowed.
      if (source == InviteCodeSource.link &&
          ref.read(connectSessionMemoryProvider).failedCodes.contains(code)) {
        setState(() => _linkLostError = ConnectErrorCode.linkUndone);
        return;
      }
      var resolved = owner;
      if (resolved == null) {
        final lookup = await viewModel.lookupInviter(rawCode, source: source);
        if (lookup is! InviteLookupFound) return; // error is in state
        code = lookup.code;
        resolved = lookup.owner;
      }
      if (!mounted) return;

      // 2. "{이름}의 운동 약속을 봐줄래요?"
      setState(() => _isWorking = false);
      final confirmed = await showInviteConfirmSheet(
        context,
        owner: resolved,
        fromClipboard: source == InviteCodeSource.clipboard,
      );
      if (!confirmed || !mounted) return;

      // Confirming agreed to the terms (shown on the sheet). Best-effort.
      try {
        unawaited(
          ref
              .read(userRepositoryProvider)
              .markTermsAccepted()
              .catchError((Object _) {}),
        );
      } catch (_) {}

      // 3. 연결
      setState(() => _isWorking = true);
      _submittedHere = true;
      _submittedCode = code;
      await viewModel.dispatch(SubmitInviteCodeIntent(code, source: source));
      if (!mounted) return;
      final after = ref.read(connectViewModelProvider).value;
      if (after?.errorMessage != null) {
        _submittedHere = false;
      } else {
        _enterSuccess();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isWorking = false;
        });
      }
    }
  }

  void _onCodeChanged(String value) {
    final code = normalizeInviteCode(value);
    if (ref.read(connectViewModelProvider).value?.errorMessage != null) {
      ref
          .read(connectViewModelProvider.notifier)
          .dispatch(const ClearConnectErrorIntent());
    }
    if (code.length == kInviteCodeLength && code != _lastAutoChecked) {
      _lastAutoChecked = code;
      _redeem(code, source: InviteCodeSource.manual);
    }
  }

  void _submitTyped() {
    final code = normalizeInviteCode(_codeController.text);
    _lastAutoChecked = code;
    _redeem(_codeController.text, source: InviteCodeSource.manual);
  }

  void _enterSuccess() {
    if (_showSuccess || !mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _showSuccess = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerNickname());
  }

  /// Right after linking: what do you call your partner? Offered once per
  /// partner (the home screen won't ask again).
  Future<void> _offerNickname() async {
    if (_nicknameOffered || !mounted) return;
    _nicknameOffered = true;
    final partners = await _currentPartners();
    final partner = partners.firstOrNull?.user;
    if (partner == null || !mounted) return;
    try {
      await ref.read(onboardingStoreProvider).markNicknamePrompted(partner.uid);
    } catch (_) {}
    if (!mounted) return;
    if (!ref.read(partnerLabelProvider).hasNickname) {
      await showPartnerNicknameSheet(context);
    }
    // Partner pushes (인증샷, 똑똑, 연결) need notification permission and a
    // registered token — ask now, for both of us, whether or not a promise
    // follows ("나중에" used to leave the invitee with no push at all).
    if (!mounted) return;
    await ref.read(notificationServiceProvider).requestPermissionAndRegister();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _makePromise() {
    final router = GoRouter.of(context);
    router.go(AppRoutes.home);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.push(AppRoutes.planCreate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final connectState =
        ref.watch(connectViewModelProvider).value ?? const ConnectState();

    // Read the link itself, not the view model's flowState: the view model
    // rebuilds (back to `initial`) whenever my profile changes, e.g. right
    // after a nickname is saved.
    ref.listen<AsyncValue<ConnectionStatus>>(connectionStatusStreamProvider, (
      previous,
      next,
    ) {
      final before = previous is AsyncData<ConnectionStatus>
          ? previous.value
          : null;
      final after = next is AsyncData<ConnectionStatus> ? next.value : null;
      switch (partnerLinkEventFor(before, after)) {
        case PartnerLinkEvent.linked:
          // Mine (after entering a code) or the inviter's live moment.
          _enterSuccess();
        case PartnerLinkEvent.unlinked:
          if (!_showSuccess) break;
          // The server undid the link (e.g. one of us already had a partner).
          // Remember the code so it isn't tried again by itself this run.
          final failed = _submittedCode;
          if (failed != null) {
            ref.read(connectSessionMemoryProvider).failedCodes.add(failed);
          }
          setState(() {
            _showSuccess = false;
            _submittedHere = false;
            _nicknameOffered = false;
            _linkLostError = ConnectErrorCode.linkUndone;
          });
        case null:
          break;
      }
    });

    final canPop = context.canPop();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: canPop && !_showSuccess
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
        child: _showSuccess
            ? _buildSuccess(l10n)
            : _buildInvite(l10n, connectState, canPop: canPop),
      ),
    );
  }

  Widget _buildInvite(
    AppLocalizations l10n,
    ConnectState connectState, {
    required bool canPop,
  }) {
    final header = Column(
      children: [
        Text(
          l10n.connectHeadline,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.connectSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );

    final entry = _buildCodeEntry(l10n, connectState);
    final share = const InviteSharePanel(surface: 'connect');

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, canPop ? 0 : 32, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widget.entryMode
            ? [
                entry,
                const SizedBox(height: 36),
                header,
                const SizedBox(height: 20),
                share,
                if (!canPop) _laterButton(l10n),
              ]
            : [
                header,
                const SizedBox(height: 24),
                share,
                const SizedBox(height: 36),
                entry,
                if (!canPop) _laterButton(l10n),
              ],
      ),
    );
  }

  Widget _laterButton(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: TextButton(
        key: const ValueKey('connect-later'),
        onPressed: () => context.go(AppRoutes.home),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        child: AppUnderlinedText(
          l10n.startSolo,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildCodeEntry(AppLocalizations l10n, ConnectState state) {
    final error = _linkLostError ?? state.errorMessage;
    final busy = _isWorking || state.isProcessing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.entryMode ? l10n.enterInviteCode : l10n.connectHaveCodeTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.enterCodeBelow,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('connect-code-field'),
          controller: _codeController,
          focusNode: _focusNode,
          textAlign: TextAlign.center,
          // Room for a pasted "ABCD-2345" or "ABCD 2345"; normalized on use.
          maxLength: kInviteCodeLength + 4,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 6,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: 'ABCD2345',
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
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
          ),
          onChanged: _onCodeChanged,
          onSubmitted: (_) => _submitTyped(),
          inputFormatters: [
            TextInputFormatter.withFunction((oldValue, newValue) {
              return newValue.copyWith(text: newValue.text.toUpperCase());
            }),
          ],
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.go,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
        ),
        const SizedBox(height: 12),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              connectErrorText(l10n, error),
              key: const ValueKey('connect-error'),
              style: TextStyle(color: AppColors.error, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            key: const ValueKey('connect-submit'),
            onPressed: busy ? null : _submitTyped,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: busy
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Text(l10n.sendConnectionRequest),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(AppLocalizations l10n) {
    final label = ref.watch(partnerLabelProvider).resolve(l10n);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.connectSuccessTitle(label),
            key: const ValueKey('connect-success-title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.3,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.connectSuccessBody,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          // Invitees skip the tutorial, so this is where they learn the loop.
          _buildHowItWorks(l10n),
          const SizedBox(height: 24),
          if (_submittedHere) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.connectSuccessAskTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.connectSuccessAskBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      key: const ValueKey('connect-success-make-promise'),
                      onPressed: _makePromise,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(l10n.connectSuccessMakePromise),
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('connect-success-later'),
                    onPressed: _leave,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: Text(l10n.connectSuccessLater),
                  ),
                ],
              ),
            ),
          ] else
            SizedBox(
              height: 52,
              child: FilledButton(
                key: const ValueKey('connect-success-done'),
                onPressed: _leave,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(l10n.connectSuccessDone),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(AppLocalizations l10n) {
    Widget step(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      key: const ValueKey('connect-success-how'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.connectHowTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          step(Icons.photo_camera_rounded, l10n.connectHowProof),
          step(Icons.favorite_rounded, l10n.connectHowAck),
          step(Icons.local_fire_department_rounded, l10n.connectHowDuo),
        ],
      ),
    );
  }
}
