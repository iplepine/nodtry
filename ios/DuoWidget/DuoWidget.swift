import SwiftUI
import WidgetKit

// Home-screen and lock-screen widget: the duo streak and today for both of
// you. The app writes the snapshot (lib/features/widget_sync) into the shared
// App Group and asks WidgetKit to reload `DuoWidget`; this extension never
// reads Firestore. Privacy: names and status words only, no photos or notes,
// since lock-screen widgets show on a locked device.

struct DuoWidgetEntry: TimelineEntry {
  let date: Date
  /// nil: not signed in or no partner yet (placeholder copy).
  let snapshot: DuoWidgetSnapshot?
}

struct DuoWidgetProvider: TimelineProvider {
  func placeholder(in context: Context) -> DuoWidgetEntry {
    DuoWidgetEntry(date: Date(), snapshot: .preview)
  }

  func getSnapshot(in context: Context, completion: @escaping (DuoWidgetEntry) -> Void) {
    let stored = DuoWidgetSnapshot.load()
    completion(DuoWidgetEntry(date: Date(), snapshot: context.isPreview ? (stored ?? .preview) : stored))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<DuoWidgetEntry>) -> Void) {
    let now = Date()
    let snapshot = DuoWidgetSnapshot.load()
    var entries = [DuoWidgetEntry(date: now, snapshot: snapshot)]
    // A second entry at midnight swaps yesterday's statuses for the stale copy
    // even when the app isn't opened.
    let calendar = Calendar.current
    if let midnight = calendar.nextDate(
      after: now,
      matching: DateComponents(hour: 0, minute: 0, second: 5),
      matchingPolicy: .nextTime
    ) {
      entries.append(DuoWidgetEntry(date: midnight, snapshot: snapshot))
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

/// Brand palette (docs/design/BRAND.md), light and dark like the Android widget.
enum DuoWidgetColors {
  static let primary = dynamic(light: 0xD92653, dark: 0xFF6F8E)
  static let background = dynamic(light: 0xFFF8F6, dark: 0x221619)
  static let card = dynamic(light: 0xFFEDEA, dark: 0x35252A)
  static let text = dynamic(light: 0x2B1A1E, dark: 0xF7ECEE)
  static let secondary = dynamic(light: 0x7A6266, dark: 0xC4AEB2)

  private static func dynamic(light: UInt32, dark: UInt32) -> Color {
    Color(UIColor { traits in
      rgb(traits.userInterfaceStyle == .dark ? dark : light)
    })
  }

  private static func rgb(_ hex: UInt32) -> UIColor {
    UIColor(
      red: CGFloat((hex >> 16) & 0xFF) / 255,
      green: CGFloat((hex >> 8) & 0xFF) / 255,
      blue: CGFloat(hex & 0xFF) / 255,
      alpha: 1
    )
  }
}

/// Tapping opens the app. `homeWidget` lets home_widget report the tap to Dart
/// (HomeScreen goes back to the Now tab); the path is the splash route, so a
/// cold start goes through the usual sign-in check.
let duoWidgetOpenURL = URL(string: "onmybehalf://app/?homeWidget=open")!

struct DuoWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: DuoWidgetEntry

  var body: some View {
    content
      .widgetURL(duoWidgetOpenURL)
      .duoWidgetBackground(isAccessory: isAccessory)
  }

  private var isAccessory: Bool {
    switch family {
    case .accessoryCircular, .accessoryRectangular, .accessoryInline: return true
    default: return false
    }
  }

  @ViewBuilder private var content: some View {
    switch family {
    case .accessoryCircular: DuoCircularView(snapshot: entry.snapshot, now: entry.date)
    case .accessoryRectangular: DuoRectangularView(snapshot: entry.snapshot, now: entry.date)
    case .accessoryInline: DuoInlineView(snapshot: entry.snapshot)
    case .systemMedium: DuoMediumView(snapshot: entry.snapshot, now: entry.date)
    default: DuoSmallView(snapshot: entry.snapshot, now: entry.date)
    }
  }
}

// MARK: - Shared pieces

private struct Statuses {
  let meText: String
  let partnerText: String
  let meStatus: String
  let partnerStatus: String
  let stale: Bool

  init(_ snapshot: DuoWidgetSnapshot, now: Date) {
    stale = snapshot.isStale(at: now)
    meText = stale ? "–" : snapshot.me.text
    partnerText = stale ? "–" : snapshot.partner.text
    meStatus = stale ? "" : snapshot.me.status
    partnerStatus = stale ? "" : snapshot.partner.status
  }
}

private func statusColor(_ status: String) -> Color {
  switch status {
  case "done", "done_proof": return DuoWidgetColors.primary
  case "pending": return DuoWidgetColors.text
  default: return DuoWidgetColors.secondary
  }
}

private func statusSymbol(_ status: String) -> String {
  switch status {
  case "done", "done_proof": return "checkmark.circle.fill"
  case "rest": return "moon.zzz.fill"
  case "pending": return "circle"
  default: return "minus.circle"
  }
}

private struct PlaceholderView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("placeholder_title")
        .font(.headline)
        .foregroundColor(DuoWidgetColors.primary)
      Text("placeholder_body")
        .font(.caption)
        .foregroundColor(DuoWidgetColors.secondary)
        .fixedSize(horizontal: false, vertical: true)
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

private struct BadgeView: View {
  let text: String
  var body: some View {
    Text(text)
      .font(.caption2.weight(.semibold))
      .foregroundColor(DuoWidgetColors.primary)
      .lineLimit(1)
      .minimumScaleFactor(0.8)
  }
}

private struct PersonRow: View {
  let name: String
  let text: String
  let status: String

  var body: some View {
    HStack(spacing: 4) {
      Text(name)
        .font(.caption)
        .foregroundColor(DuoWidgetColors.secondary)
        .lineLimit(1)
      Spacer(minLength: 4)
      Text(text)
        .font(.caption.weight(.semibold))
        .foregroundColor(statusColor(status))
        .lineLimit(1)
    }
  }
}

// MARK: - Home screen

struct DuoSmallView: View {
  let snapshot: DuoWidgetSnapshot?
  let now: Date

  var body: some View {
    if let snapshot {
      let s = Statuses(snapshot, now: now)
      VStack(alignment: .leading, spacing: 6) {
        Text(snapshot.headline)
          .font(.headline)
          .foregroundColor(DuoWidgetColors.text)
          .lineLimit(2)
          .minimumScaleFactor(0.8)
        if s.stale {
          BadgeView(text: snapshot.staleText)
        } else if let badge = snapshot.badge {
          BadgeView(text: badge)
        }
        Spacer(minLength: 0)
        PersonRow(name: snapshot.me.name, text: s.meText, status: s.meStatus)
        PersonRow(name: snapshot.partner.name, text: s.partnerText, status: s.partnerStatus)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    } else {
      PlaceholderView()
    }
  }
}

struct DuoMediumView: View {
  let snapshot: DuoWidgetSnapshot?
  let now: Date

  var body: some View {
    if let snapshot {
      let s = Statuses(snapshot, now: now)
      VStack(alignment: .leading, spacing: 8) {
        HStack(alignment: .firstTextBaseline) {
          Text(snapshot.headline)
            .font(.headline)
            .foregroundColor(DuoWidgetColors.text)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
          Spacer(minLength: 6)
          if s.stale {
            BadgeView(text: snapshot.staleText)
          } else if let badge = snapshot.badge {
            BadgeView(text: badge)
          }
        }
        HStack(spacing: 8) {
          PersonCard(name: snapshot.me.name, text: s.meText, status: s.meStatus)
          PersonCard(name: snapshot.partner.name, text: s.partnerText, status: s.partnerStatus)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    } else {
      PlaceholderView()
    }
  }
}

private struct PersonCard: View {
  let name: String
  let text: String
  let status: String

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(name)
        .font(.caption)
        .foregroundColor(DuoWidgetColors.secondary)
        .lineLimit(1)
      Spacer(minLength: 0)
      HStack(spacing: 4) {
        Image(systemName: statusSymbol(status))
          .font(.caption)
          .foregroundColor(statusColor(status))
        Text(text)
          .font(.subheadline.weight(.semibold))
          .foregroundColor(statusColor(status))
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
    }
    .padding(10)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(RoundedRectangle(cornerRadius: 12).fill(DuoWidgetColors.card))
  }
}

// MARK: - Lock screen

struct DuoCircularView: View {
  let snapshot: DuoWidgetSnapshot?
  let now: Date

  var body: some View {
    ZStack {
      AccessoryWidgetBackground()
      if let snapshot {
        let doneToday = snapshot.duoDone && !snapshot.isStale(at: now)
        VStack(spacing: 0) {
          Image(systemName: doneToday ? "heart.fill" : "heart")
            .font(.caption2)
          Text("\(snapshot.streak)")
            .font(.title3.weight(.bold))
            .minimumScaleFactor(0.6)
            .lineLimit(1)
        }
        .widgetAccentable()
      } else {
        Image(systemName: "heart")
          .font(.title3)
          .widgetAccentable()
      }
    }
  }
}

struct DuoRectangularView: View {
  let snapshot: DuoWidgetSnapshot?
  let now: Date

  var body: some View {
    if let snapshot {
      let s = Statuses(snapshot, now: now)
      VStack(alignment: .leading, spacing: 1) {
        Text(snapshot.headline)
          .font(.headline)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
          .widgetAccentable()
        if s.stale {
          Text(snapshot.staleText).font(.caption).lineLimit(1)
        } else {
          Text("\(snapshot.me.name) \(s.meText)").font(.caption).lineLimit(1)
          Text("\(snapshot.partner.name) \(s.partnerText)").font(.caption).lineLimit(1)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    } else {
      VStack(alignment: .leading, spacing: 1) {
        Text("placeholder_title").font(.headline).widgetAccentable()
        Text("placeholder_body").font(.caption).lineLimit(2)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

struct DuoInlineView: View {
  let snapshot: DuoWidgetSnapshot?

  var body: some View {
    if let snapshot {
      Label(snapshot.headline, systemImage: snapshot.duoDone ? "heart.fill" : "heart")
    } else {
      Label {
        Text("placeholder_title")
      } icon: {
        Image(systemName: "heart")
      }
    }
  }
}

// MARK: - Background

extension View {
  /// iOS 17 requires `containerBackground`; iOS 16 draws the background itself.
  @ViewBuilder
  func duoWidgetBackground(isAccessory: Bool) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      if isAccessory {
        containerBackground(for: .widget) { Color.clear }
      } else {
        containerBackground(for: .widget) { DuoWidgetColors.background }
      }
    } else if isAccessory {
      self
    } else {
      padding().background(DuoWidgetColors.background)
    }
  }
}

// MARK: - Widget

struct DuoWidget: Widget {
  /// Same as `kDuoWidgetIosKind` in Dart.
  let kind = "DuoWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: DuoWidgetProvider()) { entry in
      DuoWidgetView(entry: entry)
    }
    .configurationDisplayName(Text("widget_display_name"))
    .description(Text("widget_description"))
    .supportedFamilies([
      .systemSmall,
      .systemMedium,
      .accessoryCircular,
      .accessoryRectangular,
      .accessoryInline,
    ])
  }
}

@main
struct DuoWidgetBundle: WidgetBundle {
  var body: some Widget {
    DuoWidget()
  }
}
