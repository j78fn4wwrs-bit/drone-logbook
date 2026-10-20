import SwiftUI
import SwiftData
import PhotosUI
import UIKit
import MJKit

struct HangarView: View {
    @EnvironmentObject private var store: MJStore
    @Query(sort: \Drone.createdAt) private var drones: [Drone]
    @Query(sort: \MaintenanceEntry.date, order: .reverse) private var allMaintenance: [MaintenanceEntry]
    @State private var showAdd = false
    @State private var showPaywall = false

    private var batteryAndProps: [MaintenanceEntry] {
        Array(allMaintenance.filter { $0.kind == .battery || $0.kind == .props }.prefix(5))
    }

    var body: some View {
        NavigationStack {
            Group {
                if drones.isEmpty {
                    ContentUnavailableView {
                        Label("No drones yet", systemImage: "airplane")
                    } description: {
                        Text("Add your drone's serial, FAA registration and Remote ID serial.")
                    } actions: {
                        Button("Add Drone") { addTapped() }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(drones) { drone in
                                NavigationLink {
                                    DroneDetailView(drone: drone)
                                } label: {
                                    DroneCard(drone: drone)
                                }
                                .buttonStyle(.plain)
                            }
                            if !batteryAndProps.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Batteries & Props")
                                        .font(.headline)
                                        .padding(.top, 12)
                                    ForEach(batteryAndProps) { entry in
                                        MaintenanceRow(entry: entry)
                                            .padding(12)
                                            .background(Color.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 80)
                    }
                    .background(Color.bg)
                }
            }
            .navigationTitle("Hangar")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { addTapped() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add drone")
                }
            }
            .sheet(isPresented: $showAdd) {
                DroneEditView(drone: nil)
            }
            .sheet(isPresented: $showPaywall) {
                UpgradeSheet()
            }
        }
    }

    private func addTapped() {
        if drones.count >= 1 && !store.isPro {
            showPaywall = true
        } else {
            showAdd = true
        }
    }
}

struct DroneThumb: View {
    let drone: Drone
    var size: CGFloat = 72

    var body: some View {
        Group {
            if let data = drone.photoData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "airplane")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(Color.brand)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.surface2)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct DroneCard: View {
    let drone: Drone

    var body: some View {
        HStack(spacing: 12) {
            DroneThumb(drone: drone)
            VStack(alignment: .leading, spacing: 4) {
                Text(drone.displayName).font(.headline).foregroundStyle(Color.textPrimary)
                if !drone.makeModel.isEmpty {
                    Text(drone.makeModel).font(.subheadline).foregroundStyle(Color.textSecondary)
                }
                Text("Reg \(drone.registrationNumber.isEmpty ? "—" : drone.registrationNumber) · \(formatMinutes(drone.totalMinutes))")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            StatusChip(text: drone.status.label, color: statusColor)
        }
        .padding(12)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var statusColor: Color {
        switch drone.status {
        case .active: return .success
        case .serviceDue: return .warning
        case .grounded: return .danger
        }
    }
}

struct DroneDetailView: View {
    @Bindable var drone: Drone
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("referenceCardDroneUUID") private var referenceCardDroneUUID = ""
    @State private var showEdit = false
    @State private var showAddMaintenance = false
    @State private var confirmDelete = false

    private var recent: [MaintenanceEntry] {
        Array(drone.maintenance.sorted { $0.date > $1.date }.prefix(3))
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    DroneThumb(drone: drone, size: 88)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(drone.displayName).font(.title2.bold())
                        Text("\(drone.flights.count) flights · \(formatMinutes(drone.totalMinutes))")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(Color.textSecondary)
                        if referenceCardDroneUUID == drone.uuid.uuidString {
                            StatusChip(text: "On Quick-Reference Card", color: .brand)
                        }
                    }
                }
            }
            Section("Aircraft") {
                LabeledContent("Make", value: drone.make.isEmpty ? "—" : drone.make)
                LabeledContent("Model", value: drone.model.isEmpty ? "—" : drone.model)
                LabeledContent("Serial", value: drone.serialNumber.isEmpty ? "—" : drone.serialNumber)
                LabeledContent("FAA Reg", value: drone.registrationNumber.isEmpty ? "—" : drone.registrationNumber)
                LabeledContent("Remote ID serial", value: drone.remoteIDSerial.isEmpty ? "—" : drone.remoteIDSerial)
                LabeledContent("Firmware", value: drone.firmwareVersion.isEmpty ? "—" : drone.firmwareVersion)
                LabeledContent("Purchased", value: drone.purchaseDate?.shortDate ?? "—")
            }
            Section {
                if recent.isEmpty {
                    Text("No maintenance logged yet.").foregroundStyle(Color.textSecondary)
                }
                ForEach(recent) { entry in
                    MaintenanceRow(entry: entry)
                }
                NavigationLink("See all") {
                    MaintenanceListView(drone: drone)
                }
            } header: {
                HStack {
                    Text("Recent maintenance")
                    Spacer()
                    Button { showAddMaintenance = true } label: { Image(systemName: "plus") }
                }
            }
            Section {
                Button("Delete Drone", role: .destructive) { confirmDelete = true }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(drone.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit") { showEdit = true }
                    Button("Set as active drone for Quick-Reference Card") {
                        referenceCardDroneUUID = drone.uuid.uuidString
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEdit) { DroneEditView(drone: drone) }
        .sheet(isPresented: $showAddMaintenance) { MaintenanceEditView(drone: drone) }
        .confirmationDialog("Delete this drone and its maintenance log?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(drone)
                dismiss()
            }
        }
    }
}

struct MaintenanceRow: View {
    let entry: MaintenanceEntry

    var body: some View {
        HStack(spacing: 12) {
            IconTile(symbol: entry.kind.symbol, color: color)
            VStack(alignment: .leading) {
                Text(entry.component.isEmpty ? entry.kind.label : entry.component)
                    .foregroundStyle(Color.textPrimary)
                Text(subtitle).font(.footnote).foregroundStyle(Color.textSecondary)
            }
            Spacer()
        }
    }

    private var subtitle: String {
        var parts = [entry.kind.label, entry.date.shortDate]
        if let c = entry.cycles { parts.append("\(c) cycles") }
        if let d = entry.drone { parts.append(d.displayName) }
        return parts.joined(separator: " · ")
    }

    private var color: Color {
        switch entry.kind {
        case .props: return .accentBeacon
        case .battery: return .success
        case .firmware: return .brand
        case .retired: return .danger
        default: return .textSecondary
        }
    }
}

struct MaintenanceListView: View {
    let drone: Drone
    @Environment(\.modelContext) private var context
    @State private var filter: MaintenanceFilter = .all
    @State private var showAdd = false

    private var entries: [MaintenanceEntry] {
        drone.maintenance
            .filter { filter == .all || $0.kind.group == filter }
            .sorted { $0.date > $1.date }
    }

    private var months: [MonthGroup<MaintenanceEntry>] {
        MonthGroup.make(entries, date: \.date)
    }

    var body: some View {
        List {
            Picker("Filter", selection: $filter) {
                ForEach(MaintenanceFilter.allCases) { f in Text(f.label).tag(f) }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            ForEach(months) { month in
                Section(month.title) {
                    ForEach(month.items) { entry in
                        MaintenanceRow(entry: entry)
                    }
                    .onDelete { offsets in
                        for i in offsets { context.delete(month.items[i]) }
                    }
                }
            }
        }
        .navigationTitle("Maintenance")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAdd) { MaintenanceEditView(drone: drone) }
    }
}

struct MaintenanceEditView: View {
    let drone: Drone
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var kind: MaintenanceKind = .maintenance
    @State private var component = ""
    @State private var date = Date()
    @State private var cycles: Int?
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $kind) {
                    ForEach(MaintenanceKind.allCases) { k in
                        Label(k.label, systemImage: k.symbol).tag(k)
                    }
                }
                TextField("Component (e.g. Battery #2, front props)", text: $component)
                DatePicker("Date", selection: $date, displayedComponents: .date)
                if kind == .battery {
                    TextField("Charge cycles", value: $cycles, format: .number)
                        .keyboardType(.numberPad)
                }
                TextField("Notes", text: $notes, axis: .vertical)
            }
            .navigationTitle("Log Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let entry = MaintenanceEntry(kind: kind, drone: drone)
                        entry.component = component
                        entry.date = date
                        entry.cycles = kind == .battery ? cycles : nil
                        entry.notes = notes
                        context.insert(entry)
                        if kind == .firmware, !component.isEmpty {
                            drone.firmwareVersion = component
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DroneEditView: View {
    let drone: Drone?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var make: String
    @State private var model: String
    @State private var serial: String
    @State private var registration: String
    @State private var remoteID: String
    @State private var purchaseDate: Date?
    @State private var firmware: String
    @State private var status: DroneStatus
    @State private var notes: String
    @State private var photoData: Data?
    @State private var photoItem: PhotosPickerItem?

    init(drone: Drone?) {
        self.drone = drone
        _name = State(initialValue: drone?.name ?? "")
        _make = State(initialValue: drone?.make ?? "")
        _model = State(initialValue: drone?.model ?? "")
        _serial = State(initialValue: drone?.serialNumber ?? "")
        _registration = State(initialValue: drone?.registrationNumber ?? "")
        _remoteID = State(initialValue: drone?.remoteIDSerial ?? "")
        _purchaseDate = State(initialValue: drone?.purchaseDate)
        _firmware = State(initialValue: drone?.firmwareVersion ?? "")
        _status = State(initialValue: drone?.status ?? .active)
        _notes = State(initialValue: drone?.notes ?? "")
        _photoData = State(initialValue: drone?.photoData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Drone") {
                    TextField("Nickname", text: $name)
                    TextField("Make (e.g. DJI)", text: $make)
                    TextField("Model (e.g. Mini 4 Pro)", text: $model)
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(photoData == nil ? "Add Photo" : "Change Photo", systemImage: "photo")
                    }
                }
                Section {
                    TextField("Serial number", text: $serial)
                    TextField("FAA registration number", text: $registration)
                    TextField("Remote ID serial", text: $remoteID)
                } header: {
                    Text("Identification")
                } footer: {
                    Text("Remote ID serial is the drone's serial number (standard Remote ID) or the broadcast module's serial number.")
                }
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .monospacedDigit()
                Section("Details") {
                    OptionalDateRow(title: "Purchase date", date: $purchaseDate)
                    TextField("Firmware version", text: $firmware)
                    Picker("Status", selection: $status) {
                        ForEach(DroneStatus.allCases) { s in Text(s.label).tag(s) }
                    }
                    TextField("Notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(drone == nil ? "Add Drone" : "Edit Drone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        let target = CGSize(width: 600, height: 600 * image.size.height / max(image.size.width, 1))
                        let resized = UIGraphicsImageRenderer(size: target).image { _ in
                            image.draw(in: CGRect(origin: .zero, size: target))
                        }
                        photoData = resized.jpegData(compressionQuality: 0.8)
                    }
                }
            }
        }
    }

    private func save() {
        let target: Drone
        if let drone {
            target = drone
        } else {
            target = Drone()
            context.insert(target)
        }
        target.name = name
        target.make = make
        target.model = model
        target.serialNumber = serial
        target.registrationNumber = registration
        target.remoteIDSerial = remoteID
        target.purchaseDate = purchaseDate
        target.firmwareVersion = firmware
        target.status = status
        target.notes = notes
        target.photoData = photoData
        dismiss()
    }
}
