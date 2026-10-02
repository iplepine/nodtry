import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/analytics.dart';

/// Store review prompts are asked at most this many times, ever (spec §4.10).
const int kMaxReviewPrompts = 3;

/// The 인정 count that asks for a review the first time it is reached.
const int kReviewPropsThreshold = 3;

/// The moments that may ask for a store review.
enum ReviewTrigger {
  /// The couple's first 둘운완 day.
  firstDuoDay('first_duo_day'),

  /// The 3rd 인정 I received.
  thirdProps('third_props');

  const ReviewTrigger(this.id);
  final String id;
}

/// SharedPreferences keys.
abstract final class ReviewPromptPrefKeys {
  /// int: how many times the review was requested.
  static const count = 'review.prompt_count_v1';

  /// String list of [ReviewTrigger.id]s already used.
  static const fired = 'review.prompt_fired_v1';
}

/// The review trigger that is due now, or null. Each trigger asks once; no
/// more than [kMaxReviewPrompts] asks in total.
ReviewTrigger? dueReviewTrigger({
  required bool hadDuoDay,
  required int propsReceived,
  required int promptsShown,
  required Set<String> fired,
}) {
  if (promptsShown >= kMaxReviewPrompts) return null;
  if (hadDuoDay && !fired.contains(ReviewTrigger.firstDuoDay.id)) {
    return ReviewTrigger.firstDuoDay;
  }
  if (propsReceived >= kReviewPropsThreshold &&
      !fired.contains(ReviewTrigger.thirdProps.id)) {
    return ReviewTrigger.thirdProps;
  }
  return null;
}

/// The OS review dialog behind a seam. Overridden in tests.
abstract class ReviewRequester {
  Future<bool> isAvailable();
  Future<void> requestReview();
}

class InAppReviewRequester implements ReviewRequester {
  const InAppReviewRequester();

  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();
}

final reviewRequesterProvider = Provider<ReviewRequester>(
  (ref) => const InAppReviewRequester(),
);

/// Remembers how often the review was asked, per device.
class ReviewPromptStore {
  ReviewPromptStore(this._prefs);

  final SharedPreferences _prefs;

  int get promptsShown => _prefs.getInt(ReviewPromptPrefKeys.count) ?? 0;

  Set<String> get fired =>
      (_prefs.getStringList(ReviewPromptPrefKeys.fired) ?? const []).toSet();

  Future<void> recordPrompt(ReviewTrigger trigger) async {
    await _prefs.setInt(ReviewPromptPrefKeys.count, promptsShown + 1);
    await _prefs.setStringList(ReviewPromptPrefKeys.fired, [
      ...fired,
      trigger.id,
    ]);
  }
}

/// Asks the OS for a store review when a trigger is due. Never blocks: the
/// request is fired and forgotten, and any failure is swallowed. The ask is
/// counted before the dialog so a crash can't make it repeat. Returns the
/// trigger that asked, or null.
Future<ReviewTrigger?> maybeRequestReview({
  required ReviewPromptStore store,
  required ReviewRequester requester,
  required bool hadDuoDay,
  required int propsReceived,
}) async {
  final trigger = dueReviewTrigger(
    hadDuoDay: hadDuoDay,
    propsReceived: propsReceived,
    promptsShown: store.promptsShown,
    fired: store.fired,
  );
  if (trigger == null) return null;
  try {
    // Not available (e.g. no Play Store): try again another day.
    if (!await requester.isAvailable()) return null;
    await store.recordPrompt(trigger);
    AnalyticsService.log(AnalyticsEvent.reviewPromptShown, {
      'trigger': trigger.id,
      'count': store.promptsShown,
    });
    unawaited(
      requester.requestReview().catchError((Object e) {
        debugPrint('[ReviewPrompt] request failed (ignored): $e');
      }),
    );
    return trigger;
  } catch (e) {
    debugPrint('[ReviewPrompt] skipped: $e');
    return null;
  }
}
