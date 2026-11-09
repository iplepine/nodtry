import Foundation

/// The snapshot the app writes for the widgets
/// (lib/features/widget_sync/domain/duo_widget_snapshot.dart). Every string is
/// already localized by the app; this side only lays it out.
struct DuoWidgetSnapshot: Equatable {
  struct Person: Equatable {
    let name: String
    /// `done`, `done_proof`, `rest`, `pending` or `off` (DuoWidgetPersonStatus.wire).
    let status: String
    let text: String
  }

  let date: String
  let streak: Int
  let headline: String
  let duoDone: Bool
  let badge: String?
  let me: Person
  let partner: Person
  let staleText: String

  /// Same as `kDuoWidgetSnapshotKey` in Dart.
  static let key = "duo_widget_snapshot_v1"

  /// Same as `kDuoWidgetAppGroupId` in Dart (and both targets' entitlements).
  static let appGroupId = "group.com.devho.nodtry.app"

  /// The snapshot describes an earlier day: its statuses are no longer today's.
  func isStale(at now: Date = Date(), calendar: Calendar = .current) -> Bool {
    date != Self.dateKey(now, calendar: calendar)
  }

  static func dateKey(_ day: Date, calendar: Calendar = .current) -> String {
    let parts = calendar.dateComponents([.year, .month, .day], from: day)
    return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
  }

  static func load() -> DuoWidgetSnapshot? {
    guard let raw = UserDefaults(suiteName: appGroupId)?.string(forKey: key) else {
      return nil
    }
    return parse(raw)
  }

  static func parse(_ raw: String) -> DuoWidgetSnapshot? {
    guard
      let data = raw.data(using: .utf8),
      let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
      let me = person(json["me"]),
      let partner = person(json["partner"])
    else { return nil }
    let badge = (json["badge"] as? String).flatMap { $0.isEmpty ? nil : $0 }
    return DuoWidgetSnapshot(
      date: json["date"] as? String ?? "",
      streak: (json["streak"] as? NSNumber)?.intValue ?? 0,
      headline: json["headline"] as? String ?? "",
      duoDone: (json["duoDone"] as? NSNumber)?.boolValue ?? false,
      badge: badge,
      me: me,
      partner: partner,
      staleText: json["stale"] as? String ?? ""
    )
  }

  private static func person(_ value: Any?) -> Person? {
    guard let map = value as? [String: Any] else { return nil }
    return Person(
      name: map["name"] as? String ?? "",
      status: map["status"] as? String ?? "",
      text: map["text"] as? String ?? ""
    )
  }

  /// Gallery / placeholder preview.
  static let preview = DuoWidgetSnapshot(
    date: dateKey(Date()),
    streak: 3,
    headline: String(localized: "preview_headline"),
    duoDone: false,
    badge: nil,
    me: Person(name: String(localized: "preview_me"), status: "done", text: String(localized: "preview_done")),
    partner: Person(
      name: String(localized: "preview_partner"),
      status: "pending",
      text: String(localized: "preview_pending")
    ),
    staleText: ""
  )
}
