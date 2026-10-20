import Foundation
import UIKit

@MainActor
enum ShareSheet {
    /// Presents the system share sheet. Pass `waitForMenuDismissal` when the tap came from a `Menu`, which is still on screen for this turn.
    static func present(_ url: URL, waitForMenuDismissal: Bool = false) {
        Task { @MainActor in
            if waitForMenuDismissal {
                try? await Task.sleep(for: .milliseconds(350))
            }
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
            guard let root = scene?.keyWindow?.rootViewController ?? scene?.windows.first?.rootViewController else { return }
            var top = root
            while let presented = top.presentedViewController {
                top = presented
            }
            let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            top.present(activity, animated: true)
        }
    }
}

/// Builds CSV/PDF copies of the pilot log. IACRA credentials and document files
/// are never included. Files go to the temp folder with complete protection.
/// Call `csvFile` / `pdfFile` from a tap, not from `body`, so the files are not rewritten on every redraw.
@MainActor
enum Exporter {
    static func csvEscape(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") {
            return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return s
    }

    static func csv(flights: [Flight]) -> String {
        var lines = ["Date,Time,Drone,Duration (min),Location,Latitude,Longitude,Purpose,Weather,Notes"]
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"
        for f in flights {
            let cols: [String] = [
                df.string(from: f.start),
                tf.string(from: f.start),
                f.drone?.displayName ?? "",
                String(f.durationMinutes),
                f.locationName,
                f.latitude.map { String(format: "%.5f", $0) } ?? "",
                f.longitude.map { String(format: "%.5f", $0) } ?? "",
                f.purpose,
                f.weather,
                f.notes
            ]
            lines.append(cols.map(csvEscape).joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func writeTemp(_ data: Data, name: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            return url
        } catch {
            return nil
        }
    }

    static func csvFile(flights: [Flight]) -> URL? {
        guard let data = csv(flights: flights).data(using: .utf8) else { return nil }
        return writeTemp(data, name: "PilotLog.csv")
    }

    static func pdfFile(flights: [Flight], pilotName: String) -> URL? {
        let page = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        let total = flights.reduce(0) { $0 + $1.durationMinutes }
        var lines: [String] = []
        lines.append("Pilot Log" + (pilotName.isEmpty ? "" : " — \(pilotName)"))
        lines.append("Flights: \(flights.count)    Total time: \(formatMinutes(total))")
        lines.append("")
        for f in flights {
            let date = f.start.formatted(date: .abbreviated, time: .shortened)
            var line = "\(date)  ·  \(formatMinutes(f.durationMinutes))  ·  \(f.drone?.displayName ?? "—")"
            if !f.locationName.isEmpty { line += "  ·  \(f.locationName)" }
            lines.append(line)
            let detail = [f.purpose, f.weather, f.notes].filter { !$0.isEmpty }.joined(separator: "  ·  ")
            if !detail.isEmpty { lines.append("     " + detail) }
        }
        lines.append("")
        lines.append(AppConfig.disclaimer)

        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = 40
            for (i, line) in lines.enumerated() {
                if y > 750 {
                    ctx.beginPage()
                    y = 40
                }
                let font = i == 0 ? UIFont.boldSystemFont(ofSize: 18) : UIFont.systemFont(ofSize: 10)
                let rect = CGRect(x: 40, y: y, width: page.width - 80, height: 40)
                (line as NSString).draw(with: rect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine],
                                        attributes: [.font: font], context: nil)
                y += i == 0 ? 28 : 15
            }
        }
        return writeTemp(data, name: "PilotLog.pdf")
    }
}
