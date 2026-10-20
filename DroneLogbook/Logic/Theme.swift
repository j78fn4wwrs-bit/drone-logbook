import SwiftUI

extension Color {
    static let bg = Color("bg")
    static let surface = Color("surface")
    static let surface2 = Color("surface2")
    static let textPrimary = Color("textPrimary")
    static let textSecondary = Color("textSecondary")
    static let separatorLine = Color("separator")
    static let brand = Color("brand")
    static let accentBeacon = Color("accent")
    static let success = Color("success")
    static let warning = Color("warning")
    static let danger = Color("danger")
    static let officerCardTop = Color("officerCardTop")
    static let officerCardBottom = Color("officerCardBottom")
}

enum ExpiryStatus {
    case valid, expiring, expired, noExpiry

    init(_ date: Date?, now: Date = Date()) {
        guard let date else { self = .noExpiry; return }
        if date < now { self = .expired; return }
        let soon = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now
        self = date <= soon ? .expiring : .valid
    }

    var label: String {
        switch self {
        case .valid: return "Valid"
        case .expiring: return "Expiring"
        case .expired: return "Expired"
        case .noExpiry: return "No expiry"
        }
    }

    var color: Color {
        switch self {
        case .valid: return .success
        case .expiring: return .warning
        case .expired: return .danger
        case .noExpiry: return .textSecondary
        }
    }
}

struct StatusChip: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .background(color.opacity(0.16), in: Capsule())
    }
}

struct IconTile: View {
    let symbol: String
    let color: Color
    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

/// Optional date editor row for Forms.
struct OptionalDateRow: View {
    let title: String
    @Binding var date: Date?

    var body: some View {
        Toggle(title, isOn: Binding(
            get: { date != nil },
            set: { on in date = on ? (date ?? Date()) : nil }
        ))
        if let current = date {
            DatePicker("Date", selection: Binding(get: { current }, set: { date = $0 }), displayedComponents: .date)
        }
    }
}

extension Date {
    var shortDate: String { formatted(date: .abbreviated, time: .omitted) }
}

func formatMinutes(_ minutes: Int) -> String {
    let h = minutes / 60
    let m = minutes % 60
    return h > 0 ? "\(h)h \(m)m" : "\(m)m"
}

/// Items grouped by calendar month, newest first (input must already be sorted).
struct MonthGroup<Item>: Identifiable {
    let title: String
    var items: [Item]
    var id: String { title }

    static func make(_ items: [Item], date: (Item) -> Date) -> [MonthGroup<Item>] {
        var result: [MonthGroup<Item>] = []
        for item in items {
            let key = date(item).formatted(.dateTime.month(.wide).year())
            if let last = result.indices.last, result[last].title == key {
                result[last].items.append(item)
            } else {
                result.append(MonthGroup(title: key, items: [item]))
            }
        }
        return result
    }
}
