import Foundation
import UIKit

/// Document files live in Application Support/Vault with complete file protection
/// (unreadable while the iPhone is locked) and are excluded from backup.
/// Nothing is uploaded anywhere.
@MainActor
enum DocumentVault {
    static var directory: URL {
        let fm = FileManager.default
        let base = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? fm.temporaryDirectory
        let dir = base.appendingPathComponent("Vault", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true,
                                    attributes: [.protectionKey: FileProtectionType.complete])
        }
        excludeFromBackup(dir)
        return dir
    }

    static func save(_ data: Data, ext: String) -> String? {
        let name = UUID().uuidString + "." + ext
        let url = directory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            excludeFromBackup(url)
            return name
        } catch {
            return nil
        }
    }

    static func url(for name: String) -> URL {
        let url = directory.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: url.path) {
            excludeFromBackup(url)
        }
        return url
    }

    static func delete(_ name: String?) {
        guard let name else { return }
        try? FileManager.default.removeItem(at: url(for: name))
    }

    static func isPDF(_ name: String) -> Bool {
        name.lowercased().hasSuffix(".pdf")
    }

    static func image(for name: String) -> UIImage? {
        UIImage(contentsOfFile: url(for: name).path)
    }

    /// Normalizes any image data (HEIC, PNG...) to JPEG.
    static func jpeg(from data: Data) -> Data? {
        UIImage(data: data)?.jpegData(compressionQuality: 0.9)
    }

    /// Directory exclusion does not always cover files created later, so every file is marked too.
    private static func excludeFromBackup(_ url: URL) {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutable = url
        try? mutable.setResourceValues(values)
    }
}
