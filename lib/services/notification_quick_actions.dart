/// Action buttons on partner pushes: act on the push without hunting for the
/// card. Every button opens the app, which then runs the same handler as the
/// card's own button (so guards, analytics and the snackbar match).
///
/// The server picks a push's buttons by naming a category (`data.category`,
/// and `aps.category` for iOS, see functions `quickActionCategory`). iOS
/// shows a remote push's buttons from its registered category; Android gets
/// those pushes as data-only and builds the buttons here when it draws them.
library;

enum NotificationQuickAction {
  /// ❤️ 인정 on the partner's proof.
  props('quick_props'),

  /// 🏃 지금 간다 to a knock.
  pokeComing('quick_poke_coming'),

  /// 🙏 오늘은 봐줘 to a knock.
  pokePass('quick_poke_pass'),

  /// 💪 응원 보내기 on the partner's missed workout.
  cheer('quick_cheer');

  const NotificationQuickAction(this.id);

  /// The notification action identifier.
  final String id;

  /// The action for a tapped button's id; null for a body tap (including
  /// iOS's default action identifier) or an unknown id.
  static NotificationQuickAction? fromId(String? id) {
    for (final action in values) {
      if (action.id == id) return action;
    }
    return null;
  }

  /// Analytics value.
  String get analyticsId => switch (this) {
    props => 'props',
    pokeComing => 'poke_coming',
    pokePass => 'poke_pass',
    cheer => 'cheer',
  };
}

/// Notification categories and their buttons, in display order. The keys
/// are a contract with the server.
const Map<String, List<NotificationQuickAction>> kQuickActionCategories = {
  'partner_proof': [NotificationQuickAction.props],
  'poke_reply': [
    NotificationQuickAction.pokeComing,
    NotificationQuickAction.pokePass,
  ],
  'partner_missed': [NotificationQuickAction.cheer],
};

/// The buttons of a push in [category] (`data.category`); none for an
/// unknown or missing category.
List<NotificationQuickAction> quickActionsForCategory(String? category) =>
    kQuickActionCategories[category] ?? const [];
