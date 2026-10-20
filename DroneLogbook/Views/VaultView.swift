import SwiftUI
import SwiftData
import PhotosUI
import PDFKit
import UniformTypeIdentifiers

struct VaultView: View {
    @Query(sort: \DocumentRecord.createdAt) private var documents: [DocumentRecord]
    @State private var showAdd = false

    private var certificates: [DocumentRecord] { documents.filter { $0.kind.isCertificate } }
    private var others: [DocumentRecord] { documents.filter { !$0.kind.isCertificate } }

    var body: some View {
        NavigationStack {
            List {
                if documents.isEmpty {
                    Section {
                        ContentUnavailableView {
                            Label("No documents", systemImage: "doc.text")
                        } description: {
                            Text("Scan your Part 107, TRUST and registration.")
                        } actions: {
                            Button("Add Document") { showAdd = true }
                                .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity, minHeight: 280)
                        .listRowBackground(Color.clear)
                    }
                }
                if !certificates.isEmpty {
                    Section("Certificates") {
                        ForEach(certificates) { doc in row(doc) }
                    }
                }
                if !others.isEmpty {
                    Section("Waivers & Insurance") {
                        ForEach(others) { doc in row(doc) }
                    }
                }
                Section("Secure") {
                    NavigationLink {
                        IACRAVaultView()
                    } label: {
                        HStack(spacing: 12) {
                            IconTile(symbol: "faceid", color: .textPrimary)
                            VStack(alignment: .leading) {
                                Text("IACRA Login")
                                Text("Username and FTN · Face ID").font(.footnote).foregroundStyle(Color.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "lock.fill").foregroundStyle(Color.textSecondary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Vault")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add document")
                }
            }
            .sheet(isPresented: $showAdd) {
                DocumentEditView(document: nil)
            }
        }
    }

    private func row(_ doc: DocumentRecord) -> some View {
        NavigationLink {
            DocumentDetailView(document: doc)
        } label: {
            HStack(spacing: 12) {
                IconTile(symbol: doc.kind.symbol, color: doc.kind.isCertificate ? .brand : .accentBeacon)
                VStack(alignment: .leading) {
                    Text(doc.displayTitle)
                    Text(subtitle(doc)).font(.footnote).foregroundStyle(Color.textSecondary)
                }
                Spacer()
                let status = ExpiryStatus(doc.expiryDate)
                StatusChip(text: status.label, color: status.color)
            }
        }
    }

    private func subtitle(_ doc: DocumentRecord) -> String {
        if let e = doc.expiryDate { return "Expires \(e.shortDate)" }
        if let i = doc.issueDate { return "Issued \(i.shortDate)" }
        return doc.kind.label
    }
}

struct DocumentDetailView: View {
    @Bindable var document: DocumentRecord
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var showFull = false
    @State private var confirmDelete = false

    var body: some View {
        Form {
            if let name = document.fileName {
                Section {
                    Button { showFull = true } label: {
                        DocumentFileView(fileName: name)
                            .frame(height: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    ShareLink(item: DocumentVault.url(for: name)) {
                        Label("Share Copy", systemImage: "square.and.arrow.up")
                    }
                }
            }
            Section("Details") {
                LabeledContent("Type", value: document.kind.label)
                if !document.number.isEmpty {
                    LabeledContent("Number", value: document.number)
                }
                LabeledContent("Issued", value: document.issueDate?.shortDate ?? "—")
                LabeledContent("Expires", value: document.expiryDate?.shortDate ?? "No expiry")
                let status = ExpiryStatus(document.expiryDate)
                LabeledContent("Status") { StatusChip(text: status.label, color: status.color) }
                if !document.notes.isEmpty {
                    Text(document.notes)
                }
            }
            Section {
                Button("Delete Document", role: .destructive) { confirmDelete = true }
            }
        }
        .navigationTitle(document.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            DocumentEditView(document: document)
        }
        .fullScreenCover(isPresented: $showFull) {
            if let name = document.fileName {
                NavigationStack {
                    DocumentFileView(fileName: name)
                        .ignoresSafeArea(edges: .bottom)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showFull = false }
                            }
                        }
                }
            }
        }
        .confirmationDialog("Delete this document?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                DocumentVault.delete(document.fileName)
                context.delete(document)
                dismiss()
            }
        }
    }
}

/// Shows an image (pinch to zoom) or PDF from the vault.
struct DocumentFileView: View {
    let fileName: String

    var body: some View {
        if DocumentVault.isPDF(fileName) {
            PDFKitView(url: DocumentVault.url(for: fileName))
        } else if let image = DocumentVault.image(for: fileName) {
            ZoomableImageView(image: image)
        } else {
            ContentUnavailableView("File unavailable", systemImage: "doc.questionmark")
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}

/// UIScrollView-backed image with pinch-to-zoom.
/// Constraints that pin the image to both the frame and the content guides fight the zoom transform, so the image is framed in layoutSubviews instead.
struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> ZoomScrollView {
        let scroll = ZoomScrollView()
        scroll.imageView.image = image
        return scroll
    }

    func updateUIView(_ uiView: ZoomScrollView, context: Context) {
        uiView.imageView.image = image
    }
}

final class ZoomScrollView: UIScrollView, UIScrollViewDelegate {
    let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        minimumZoomScale = 1
        maximumZoomScale = 6
        bouncesZoom = true
        delegate = self
        backgroundColor = .clear
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
    }

    required init?(coder: NSCoder) { return nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard zoomScale <= minimumZoomScale + 0.01 else { return }
        let target = bounds
        guard imageView.frame.size != target.size || contentSize != target.size else { return }
        imageView.frame = target
        contentSize = target.size
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
}

struct DocumentEditView: View {
    let document: DocumentRecord?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var kind: DocumentKind
    @State private var title: String
    @State private var number: String
    @State private var issueDate: Date?
    @State private var expiryDate: Date?
    @State private var notes: String
    @State private var photoItem: PhotosPickerItem?
    @State private var pendingData: Data?
    @State private var pendingExt = "jpg"
    @State private var showImporter = false
    @State private var importError = false

    init(document: DocumentRecord?) {
        self.document = document
        _kind = State(initialValue: document?.kind ?? .part107)
        _title = State(initialValue: document?.title ?? "")
        _number = State(initialValue: document?.number ?? "")
        _issueDate = State(initialValue: document?.issueDate)
        _expiryDate = State(initialValue: document?.expiryDate)
        _notes = State(initialValue: document?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Document", selection: $kind) {
                        ForEach(DocumentKind.allCases) { k in
                            Label(k.label, systemImage: k.symbol).tag(k)
                        }
                    }
                    TextField("Title (optional)", text: $title)
                    TextField("Number (optional)", text: $number)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                Section {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Choose Photo", systemImage: "photo")
                    }
                    Button {
                        showImporter = true
                    } label: {
                        Label("Import PDF or Image File", systemImage: "doc")
                    }
                    if pendingData != nil {
                        Label("New file ready to save", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(Color.success)
                    } else if document?.fileName != nil {
                        Label("File on record", systemImage: "doc.fill")
                            .foregroundStyle(Color.textSecondary)
                    }
                    if importError {
                        Text("Couldn't read that file.").foregroundStyle(Color.danger)
                    }
                } header: {
                    Text("File")
                } footer: {
                    Text("Stored only on this iPhone with complete file protection.")
                }
                Section {
                    OptionalDateRow(title: "Issue date", date: $issueDate)
                    OptionalDateRow(title: "Expiry date", date: $expiryDate)
                } header: {
                    Text("Dates")
                } footer: {
                    if kind == .registration {
                        Text("FAA registration lasts 3 years. If you leave expiry off, it's set to 3 years after the issue date.")
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(document == nil ? "Add Document" : "Edit Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let jpeg = DocumentVault.jpeg(from: data) {
                        pendingData = jpeg
                        pendingExt = "jpg"
                        importError = false
                    } else {
                        importError = true
                    }
                }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.pdf, .image]) { result in
                handleImport(result)
            }
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { importError = true; return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else { importError = true; return }
        if url.pathExtension.lowercased() == "pdf" {
            pendingData = data
            pendingExt = "pdf"
            importError = false
        } else if let jpeg = DocumentVault.jpeg(from: data) {
            pendingData = jpeg
            pendingExt = "jpg"
            importError = false
        } else {
            importError = true
        }
    }

    private func save() {
        let target: DocumentRecord
        if let document {
            target = document
        } else {
            target = DocumentRecord(kind: kind)
            context.insert(target)
        }
        target.kind = kind
        target.title = title
        target.number = number
        target.issueDate = issueDate
        var expiry = expiryDate
        if kind == .registration, expiry == nil, let issue = issueDate {
            expiry = Calendar.current.date(byAdding: .year, value: 3, to: issue)
        }
        target.expiryDate = expiry
        target.notes = notes
        if let data = pendingData, let name = DocumentVault.save(data, ext: pendingExt) {
            DocumentVault.delete(target.fileName)
            target.fileName = name
        }
        dismiss()
    }
}
