import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

class FocusTimerScreen extends StatefulWidget {
  final int minutes;
  final String? planTitle;

  const FocusTimerScreen({
    super.key,
    required this.minutes,
    this.planTitle,
  });

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with WidgetsBindingObserver {
  late final Duration _total;
  late DateTime _endTime;
  Duration? _pausedRemaining;
  Timer? _ticker;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _total = Duration(minutes: widget.minutes);
    _endTime = DateTime.now().add(_total);
    WidgetsBinding.instance.addObserver(this);
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _pausedRemaining == null &&
        !_finished) {
      _onTick();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    if (_finished) return;
    final remaining = _currentRemaining();
    if (remaining <= Duration.zero) {
      _finished = true;
      _ticker?.cancel();
      if (mounted) Navigator.of(context).pop(_total);
    } else if (mounted) {
      setState(() {});
    }
  }

  Duration _currentRemaining() {
    if (_pausedRemaining != null) return _pausedRemaining!;
    final left = _endTime.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  Duration _currentElapsed() {
    final elapsed = _total - _currentRemaining();
    if (elapsed.isNegative) return Duration.zero;
    if (elapsed > _total) return _total;
    return elapsed;
  }

  void _completeNow() {
    if (_finished) return;
    _finished = true;
    _ticker?.cancel();
    Navigator.of(context).pop(_currentElapsed());
  }

  void _togglePause() {
    setState(() {
      if (_pausedRemaining == null) {
        _pausedRemaining = _currentRemaining();
        _ticker?.cancel();
      } else {
        _endTime = DateTime.now().add(_pausedRemaining!);
        _pausedRemaining = null;
        _startTicker();
      }
    });
  }

  Future<void> _attemptGiveUp() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(
          '타이머를 그만둘까요?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '진행 기록은 따로 남지 않아요. 약속은 미처리 상태로 남아요.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('계속하기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('그만두기'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _finished = true;
      _ticker?.cancel();
      Navigator.of(context).pop(null);
    }
  }

  String _formatRemaining(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _currentRemaining();
    final progress = _total.inMilliseconds == 0
        ? 0.0
        : (_total.inMilliseconds - remaining.inMilliseconds) /
            _total.inMilliseconds;
    final paused = _pausedRemaining != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _attemptGiveUp();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: _attemptGiveUp,
          ),
          title: Text(
            widget.planTitle == null
                ? '${widget.minutes}분 집중'
                : '${widget.planTitle} · ${widget.minutes}분',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(),
                SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          strokeWidth: 10,
                          backgroundColor:
                              AppColors.surface.withValues(alpha: 0.6),
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatRemaining(remaining),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (paused)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '잠시 멈춤',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _completeNow,
                    icon: const Icon(
                      Icons.check_circle_outline,
                      size: 22,
                    ),
                    label: const Text('했어! 지금 끝낼게'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _togglePause,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(paused ? '재개' : '잠시 멈춤'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: _attemptGiveUp,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('포기'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
