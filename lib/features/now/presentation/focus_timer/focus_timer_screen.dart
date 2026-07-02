import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/analytics.dart';

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
    AnalyticsService.log(AnalyticsEvent.focusTimerStarted, {
      'duration_min': widget.minutes,
    });
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
      AnalyticsService.log(AnalyticsEvent.focusTimerCompleted, {
        'duration_min': widget.minutes,
      });
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
    AnalyticsService.log(AnalyticsEvent.focusTimerCompleted, {
      'duration_min': widget.minutes,
      'elapsed_min': _currentElapsed().inMinutes,
      'manual': true,
    });
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(
          l10n.focusTimerGiveUpTitle,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.focusTimerGiveUpBody,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.focusTimerKeepGoing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: Text(l10n.focusTimerGiveUp),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _finished = true;
      _ticker?.cancel();
      AnalyticsService.log(AnalyticsEvent.focusTimerCancelled, {
        'duration_min': widget.minutes,
        'elapsed_min': _currentElapsed().inMinutes,
      });
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
    final l10n = AppLocalizations.of(context)!;
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
                ? l10n.focusTimerHeader(widget.minutes)
                : l10n.focusTimerHeaderWithPlan(widget.planTitle!, widget.minutes),
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
                                l10n.focusTimerPaused,
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
                    label: Text(l10n.focusTimerDoneNow),
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
                        child: Text(paused ? l10n.focusTimerResume : l10n.focusTimerPause),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: _attemptGiveUp,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(l10n.focusTimerGiveUpShort),
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
