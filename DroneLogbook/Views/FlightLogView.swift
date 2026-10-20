import SwiftUI
import SwiftData
import MapKit
import CoreLocation
import MJKit

struct FlightLogView: View {
    @EnvironmentObject private var store: MJStore
    @EnvironmentObject private var profileStore: PilotProfileStore
    @Environment(\.modelContext) private var context
    @Query(sort: \Flight.start, order: .reverse) private var flights: [Flight]
    @State private var search = ""
    @State private var showAdd = false
    @State private var editing: Flight?
    @State private var showPaywall = false

    private var filtered: [Flight] {
        guard !search.isEmpty else { return flights }
        return flights.filter { f in
            [f.locationName, f.purpose, f.notes, f.weather, f.drone?.displayName ?? ""]
                .contains { $0.localizedCaseInsensitiveContains(search) }
        }
    }

    private var totalMinutes: Int { flights.reduce(0) { $0 + $1.durationMinutes } }

    private var thisMonthCount: Int {
        let cal = Calendar.current
        return flights.filter { cal.isDate($0.start, equalTo: Date(), toGranularity: .month) }.count
    }

    private var months: [MonthGroup<Flight>] {
        MonthGroup.make(filtered, date: \.start)
    }

    var body: some View {
        NavigationStack {
            Group {
                if flights.isEmpty {
                    ContentUnavailableView {
                        Label("No flights logged", systemImage: "book.closed")
                    } description: {
                        Text("Log date, time, location, drone and duration for every flight.")
                    } actions: {
                        Button("Log a Flight") { showAdd = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        Section {
                            HStack(spacing: 8) {
                                StatTile(title: "Flights", value: "\(flights.count)")
                                StatTile(title: "Hours", value: String(format: "%.1f", Double(totalMinutes) / 60))
                                StatTile(title: "This month", value: "\(thisMonthCount)")
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        }
                        ForEach(months) { month in
                            Section(month.title) {
                                ForEach(month.items) { flight in
                                    Button { editing = flight } label: { FlightRow(flight: flight) }
                                        .buttonStyle(.plain)
                                }
                                .onDelete { offsets in
                                    for i in offsets { context.delete(month.items[i]) }
                                }
                            }
                        }
                        Color.clear.frame(height: 60).listRowBackground(Color.clear)
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $search)
                }
            }
            .navigationTitle("Pilot Log")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if store.isPro && !flights.isEmpty {
                        Menu {
                            Button {
                                if let csv = Exporter.csvFile(flights: flights) {
                                    ShareSheet.present(csv, waitForMenuDismissal: true)
                                }
                            } label: {
                                Label("Export CSV", systemImage: "tablecells")
                            }
                            Button {
                                if let pdf = Exporter.pdfFile(flights: flights, pilotName: profileStore.profile.name) {
                                    ShareSheet.present(pdf, waitForMenuDismissal: true)
                                }
                            } label: {
                                Label("Export PDF", systemImage: "doc.richtext")
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    } else if !flights.isEmpty {
                        Button { showPaywall = true } label: { Image(systemName: "square.and.arrow.up") }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Log a flight")
                }
            }
            .sheet(isPresented: $showAdd) { FlightEditView(flight: nil) }
            .sheet(item: $editing) { flight in FlightEditView(flight: flight) }
            .sheet(isPresented: $showPaywall) { UpgradeSheet() }
        }
    }
}

struct StatTile: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.title2.weight(.bold).monospacedDigit()).foregroundStyle(Color.textPrimary)
            Text(title).font(.footnote).foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct FlightRow: View {
    let flight: Flight
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Text(flight.start.formatted(.dateTime.month(.abbreviated)).uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.danger)
                Text(flight.start.formatted(.dateTime.day()))
                    .font(.title2.bold())
                    .foregroundStyle(Color.textPrimary)
            }
            .frame(width: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(flight.locationName.isEmpty ? "Unknown location" : flight.locationName)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                Text([flight.drone?.displayName ?? "No drone", flight.purpose].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(formatMinutes(flight.durationMinutes))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Color.textSecondary)
        }
        .contentShape(Rectangle())
    }
}

struct FlightEditView: View {
    static let purposes = ["Recreational", "Commercial", "Photo/Video", "Inspection", "Mapping", "Training", "Other"]

    let flight: Flight?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Drone.createdAt) private var drones: [Drone]
    @StateObject private var location = MainActor.assumeIsolated { LocationFetcher() }

    @State private var start: Date
    @State private var minutes: Int
    @State private var droneID: UUID?
    @State private var locationName: String
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var purpose: String
    @State private var weather: String
    @State private var notes: String

    init(flight: Flight?) {
        self.flight = flight
        _start = State(initialValue: flight?.start ?? Date())
        _minutes = State(initialValue: flight?.durationMinutes ?? 15)
        _droneID = State(initialValue: flight?.drone?.uuid)
        _locationName = State(initialValue: flight?.locationName ?? "")
        _latitude = State(initialValue: flight?.latitude)
        _longitude = State(initialValue: flight?.longitude)
        _purpose = State(initialValue: flight?.purpose ?? "Recreational")
        _weather = State(initialValue: flight?.weather ?? "")
        _notes = State(initialValue: flight?.notes ?? "")
    }

    private var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private var selectedDrone: Drone? {
        guard let droneID else { return nil }
        return drones.first { $0.uuid == droneID }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let coordinate {
                        FlightMap(coordinate: coordinate)
                            .id("\(coordinate.latitude),\(coordinate.longitude)")
                    }
                    Button {
                        location.request()
                    } label: {
                        if location.isLocating {
                            HStack { ProgressView(); Text("Locating…") }
                        } else {
                            Label("Use Current Location", systemImage: "location.fill")
                        }
                    }
                    if location.failed {
                        Text("Location unavailable. Type the place below.")
                            .font(.footnote)
                            .foregroundStyle(Color.textSecondary)
                    }
                    TextField("Location name (e.g. Trinity Park)", text: $locationName)
                } header: {
                    Text("Location")
                }
                Section("Flight") {
                    DatePicker("Date & time", selection: $start)
                    Picker("Drone", selection: $droneID) {
                        Text("Choose…").tag(nil as UUID?)
                        ForEach(drones) { d in
                            Text(d.displayName).tag(d.uuid as UUID?)
                        }
                    }
                    Stepper(value: $minutes, in: 0...600, step: 1) {
                        LabeledContent("Duration", value: formatMinutes(minutes))
                    }
                    Picker("Purpose", selection: $purpose) {
                        ForEach(Self.purposes, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Weather (e.g. Clear, 8 mph wind, 72°F)", text: $weather)
                }
                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 80)
                }
                if drones.isEmpty {
                    Section {
                        Text("Add a drone in the Hangar tab first.")
                            .foregroundStyle(Color.warning)
                    }
                }
            }
            .navigationTitle(flight == nil ? "Log Flight" : "Edit Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(selectedDrone == nil)
                }
            }
            .onAppear { selectDefaultDrone() }
            .onChange(of: drones.count) { _, _ in selectDefaultDrone() }
            .onReceive(location.$coordinate) { coord in
                guard let coord else { return }
                latitude = coord.latitude
                longitude = coord.longitude
                if locationName.isEmpty { locationName = coord.shortString }
            }
        }
    }

    private func selectDefaultDrone() {
        if flight == nil, droneID == nil { droneID = drones.first?.uuid }
    }

    private func save() {
        let target: Flight
        if let flight {
            target = flight
        } else {
            target = Flight()
            context.insert(target)
        }
        target.start = start
        target.durationMinutes = minutes
        target.drone = selectedDrone
        target.locationName = locationName
        target.latitude = latitude
        target.longitude = longitude
        target.purpose = purpose
        target.weather = weather
        target.notes = notes
        dismiss()
    }
}

/// Split out of the flight form so `Map(initialPosition:)` and `Marker` type-check on their own.
private struct FlightMap: View {
    let coordinate: CLLocationCoordinate2D

    var body: some View {
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 800, longitudinalMeters: 800)
        Map(initialPosition: .region(region)) {
            Marker("Flight", coordinate: coordinate)
        }
        .frame(height: 130)
        .listRowInsets(EdgeInsets())
        .allowsHitTesting(false)
    }
}
