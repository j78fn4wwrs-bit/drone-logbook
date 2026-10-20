import Foundation
import SwiftData

enum DroneStatus: String, CaseIterable, Identifiable {
    case active, serviceDue, grounded
    var id: String { rawValue }
    var label: String {
        switch self {
        case .active: return "Active"
        case .serviceDue: return "Service due"
        case .grounded: return "Grounded"
        }
    }
}

@Model
final class Drone {
    var uuid: UUID = UUID()
    var name: String = ""
    var make: String = ""
    var model: String = ""
    var serialNumber: String = ""
    var registrationNumber: String = ""
    /// Remote ID serial: the drone's serial (standard Remote ID) or the broadcast module's serial.
    var remoteIDSerial: String = ""
    var purchaseDate: Date? = nil
    var firmwareVersion: String = ""
    var statusRaw: String = DroneStatus.active.rawValue
    var notes: String = ""
    @Attribute(.externalStorage) var photoData: Data? = nil
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \MaintenanceEntry.drone)
    var maintenance: [MaintenanceEntry] = []

    @Relationship(deleteRule: .nullify, inverse: \Flight.drone)
    var flights: [Flight] = []

    init(name: String = "") {
        self.name = name
    }

    var status: DroneStatus {
        get { DroneStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var displayName: String {
        if !name.isEmpty { return name }
        let mm = [make, model].filter { !$0.isEmpty }.joined(separator: " ")
        return mm.isEmpty ? "Unnamed drone" : mm
    }

    var makeModel: String {
        [make, model].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    var totalMinutes: Int { flights.reduce(0) { $0 + $1.durationMinutes } }
}

enum MaintenanceKind: String, CaseIterable, Identifiable {
    case maintenance, modification, battery, props, firmware, repair, retired
    var id: String { rawValue }
    var label: String {
        switch self {
        case .maintenance: return "Maintenance"
        case .modification: return "Modification"
        case .battery: return "Battery"
        case .props: return "Props"
        case .firmware: return "Firmware"
        case .repair: return "Repair"
        case .retired: return "Retired"
        }
    }
    var symbol: String {
        switch self {
        case .battery: return "battery.75percent"
        case .props: return "fanblades"
        case .firmware: return "arrow.triangle.2.circlepath"
        case .retired: return "xmark.octagon"
        default: return "wrench.and.screwdriver"
        }
    }
    /// Filter group for the segmented control.
    var group: MaintenanceFilter {
        switch self {
        case .battery: return .batteries
        case .props: return .props
        default: return .aircraft
        }
    }
}

enum MaintenanceFilter: String, CaseIterable, Identifiable {
    case all, aircraft, batteries, props
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

@Model
final class MaintenanceEntry {
    var date: Date = Date()
    var kindRaw: String = MaintenanceKind.maintenance.rawValue
    var component: String = ""
    var cycles: Int? = nil
    var notes: String = ""
    var drone: Drone? = nil

    init(kind: MaintenanceKind = .maintenance, drone: Drone? = nil) {
        self.kindRaw = kind.rawValue
        self.drone = drone
    }

    var kind: MaintenanceKind {
        get { MaintenanceKind(rawValue: kindRaw) ?? .maintenance }
        set { kindRaw = newValue.rawValue }
    }
}

@Model
final class Flight {
    var start: Date = Date()
    var durationMinutes: Int = 0
    var locationName: String = ""
    var latitude: Double? = nil
    var longitude: Double? = nil
    var purpose: String = ""
    var weather: String = ""
    var notes: String = ""
    var drone: Drone? = nil

    init(start: Date = Date()) {
        self.start = start
    }
}

enum DocumentKind: String, CaseIterable, Identifiable {
    case part107, trust, registration, remoteID, waiver, insurance, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .part107: return "Part 107 Certificate"
        case .trust: return "TRUST Certificate"
        case .registration: return "FAA Registration"
        case .remoteID: return "Remote ID Declaration"
        case .waiver: return "Waiver / LAANC"
        case .insurance: return "Insurance"
        case .other: return "Other"
        }
    }
    var symbol: String {
        switch self {
        case .part107, .insurance: return "checkmark.shield"
        case .trust: return "graduationcap"
        case .registration: return "number.square"
        case .remoteID: return "dot.radiowaves.left.and.right"
        case .waiver: return "doc.badge.clock"
        case .other: return "doc.text"
        }
    }
    var isCertificate: Bool {
        switch self {
        case .part107, .trust, .registration, .remoteID: return true
        default: return false
        }
    }
}

@Model
final class DocumentRecord {
    var kindRaw: String = DocumentKind.other.rawValue
    var title: String = ""
    var number: String = ""
    var issueDate: Date? = nil
    var expiryDate: Date? = nil
    /// File name inside the app's protected Vault folder (not the data itself).
    var fileName: String? = nil
    var notes: String = ""
    var createdAt: Date = Date()

    init(kind: DocumentKind = .other) {
        self.kindRaw = kind.rawValue
    }

    var kind: DocumentKind {
        get { DocumentKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }

    var displayTitle: String { title.isEmpty ? kind.label : title }
}
