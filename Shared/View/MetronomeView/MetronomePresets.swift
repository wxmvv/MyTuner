import SwiftUI
import UniformTypeIdentifiers

struct MetronomePreset: Codable, Equatable, Identifiable {
    var id = UUID()
    var name: String
    var settings: MetronomeSettings
}

private struct PresetArchive: Codable {
    let version: Int
    let presets: [MetronomePreset]

    init(_ presets: [MetronomePreset]) {
        self.version = 1
        self.presets = presets
    }

    static func read(_ data: Data) throws -> [MetronomePreset] {
        let archive = try JSONDecoder().decode(Self.self, from: data)
        guard archive.version == 1 else { throw PresetFileError.unsupportedVersion }
        let ids = Set(archive.presets.map(\.id))
        guard ids.count == archive.presets.count,
              archive.presets.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        else { throw PresetFileError.invalidFile }
        return archive.presets
    }
}

private enum PresetFileError: LocalizedError {
    case invalidFile
    case unsupportedVersion

    var errorDescription: String? {
        switch self {
        case .invalidFile: return String(localized: "Choose a MyTuner preset file.")
        case .unsupportedVersion: return String(localized: "This preset file uses an unsupported version.")
        }
    }
}

final class MetronomePresetLibrary: ObservableObject {
    @Published private(set) var presets: [MetronomePreset]
    @Published private(set) var selectedID: UUID?

    private let defaults: UserDefaults
    private let libraryKey = "metronomePresetLibrary"
    private let selectionKey = "metronomeSelectedPreset"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        presets = defaults.data(forKey: libraryKey).flatMap { try? PresetArchive.read($0) } ?? []
        selectedID = defaults.string(forKey: selectionKey).flatMap(UUID.init(uuidString:))
    }

    func currentName(for settings: MetronomeSettings) -> String? {
        presets.first { $0.id == selectedID && $0.settings == settings }?.name
    }

    func select(_ preset: MetronomePreset) {
        selectedID = preset.id
        defaults.set(preset.id.uuidString, forKey: selectionKey)
    }

    func save(_ preset: MetronomePreset) throws {
        var updated = presets
        if let index = updated.firstIndex(where: { $0.id == preset.id }) {
            updated[index] = preset
        } else {
            updated.append(preset)
        }
        try persist(updated)
    }

    func delete(_ preset: MetronomePreset) throws {
        try persist(presets.filter { $0.id != preset.id })
        if selectedID == preset.id {
            selectedID = nil
            defaults.removeObject(forKey: selectionKey)
        }
    }

    /// Preserve both versions when the same song has been edited on two devices.
    func merge(_ data: Data) throws -> Int {
        let incoming: [MetronomePreset]
        do {
            incoming = try PresetArchive.read(data)
        } catch is DecodingError {
            throw PresetFileError.invalidFile
        }
        var updated = presets
        for var preset in incoming {
            if updated.contains(where: { $0.id == preset.id }) {
                if updated.contains(where: { $0.name == preset.name && $0.settings == preset.settings }) {
                    continue
                }
                preset.id = UUID()
            }
            updated.append(preset)
        }
        let added = updated.count - presets.count
        if added > 0 { try persist(updated) }
        return added
    }

    private func persist(_ updated: [MetronomePreset]) throws {
        let data = try JSONEncoder().encode(PresetArchive(updated))
        defaults.set(data, forKey: libraryKey)
        presets = updated
    }
}

private struct PresetDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var presets: [MetronomePreset]

    init(presets: [MetronomePreset]) {
        self.presets = presets
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw PresetFileError.invalidFile }
        presets = try PresetArchive.read(data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return FileWrapper(regularFileWithContents: try encoder.encode(PresetArchive(presets)))
    }

    static func load(from url: URL) async throws -> Data {
        try await Task.detached(priority: .userInitiated) {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            var coordinationError: NSError?
            var result: Result<Data, Error> = .failure(PresetFileError.invalidFile)
            NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { file in
                result = Result { try Data(contentsOf: file) }
            }
            if let coordinationError { throw coordinationError }
            return try result.get()
        }.value
    }
}

struct MetronomePresetsView: View {
    @Binding var settings: MetronomeSettings
    @ObservedObject var library: MetronomePresetLibrary

    @Environment(\.dismiss) private var dismiss
    @State private var editing: MetronomePreset?
    @State private var importing = false
    @State private var exporting = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        editing = MetronomePreset(name: "", settings: settings)
                    } label: {
                        Label("New preset", systemImage: "plus.circle")
                    }

                    ForEach(library.presets) { preset in
                        HStack {
                            Button {
                                library.select(preset)
                                settings = preset.settings
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(verbatim: preset.name).foregroundStyle(.primary)
                                        Text(verbatim: "\(preset.settings.tempo) BPM · \(preset.settings.numerator)/\(preset.settings.denominator)")
                                            .font(.subheadline.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if isCurrent(preset) {
                                        Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(isCurrent(preset) ? .isSelected : [])

                            Menu {
                                Button {
                                    editing = preset
                                } label: {
                                    Label("Edit preset", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    remove(preset)
                                } label: {
                                    Label("Delete preset", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Preset actions")
                        }
                        .swipeActions {
                            Button(role: .destructive) { remove(preset) } label: {
                                Label("Delete preset", systemImage: "trash")
                            }
                        }
                    }
                }

                Section {
                    Button { importing = true } label: {
                        Label("Import presets", systemImage: "square.and.arrow.down")
                    }
                    Button { exporting = true } label: {
                        Label("Export presets", systemImage: "square.and.arrow.up")
                    }
                    .disabled(library.presets.isEmpty)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Song presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $editing) { preset in
                PresetEditor(preset: preset, current: settings) { updated in
                    let existing = library.presets.first { $0.id == updated.id }
                    let apply = existing.map(isCurrent) ?? true
                    try library.save(updated)
                    if apply {
                        library.select(updated)
                        settings = updated.settings
                    }
                }
                .presentationBackground(Material.regular)
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                Task { @MainActor in
                    do {
                        let data = try await PresetDocument.load(from: result.get())
                        let added = try library.merge(data)
                        message = added > 0 ? String(localized: "Presets added: \(added)") :
                            String(localized: "No new presets to import.")
                    } catch { report(error) }
                }
            }
            .fileExporter(isPresented: $exporting, document: PresetDocument(presets: library.presets),
                          contentType: .json, defaultFilename: "MyTuner Presets") { result in
                if case let .failure(error) = result { report(error) }
            }
            .alert("Song presets", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(verbatim: message ?? "")
            }
        }
    }

    private func isCurrent(_ preset: MetronomePreset) -> Bool {
        library.selectedID == preset.id && settings == preset.settings
    }

    private func remove(_ preset: MetronomePreset) {
        do { try library.delete(preset) } catch { report(error) }
    }

    private func report(_ error: Error) {
        let nsError = error as NSError
        guard nsError.domain != NSCocoaErrorDomain || nsError.code != NSUserCancelledError else { return }
        message = error.localizedDescription
    }
}

private struct PresetEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: MetronomePreset
    @State private var errorMessage: String?
    private let current: MetronomeSettings
    private let isNew: Bool
    private let save: (MetronomePreset) throws -> Void

    init(preset: MetronomePreset, current: MetronomeSettings, save: @escaping (MetronomePreset) throws -> Void) {
        _draft = State(initialValue: preset)
        self.current = current
        self.isNew = preset.name.isEmpty
        self.save = save
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Song name", text: $draft.name)
                }
                Section {
                    Stepper(value: $draft.settings.tempo, in: MetronomeSettings.tempoRange) {
                        LabeledContent("Tempo") { Text(verbatim: "\(draft.settings.tempo) BPM") }
                    }
                    Stepper(value: $draft.settings.numerator, in: MetronomeSettings.beatRange) {
                        LabeledContent("Beats per measure") { Text(verbatim: "\(draft.settings.numerator)") }
                    }
                    Picker("Beat unit", selection: $draft.settings.denominator) {
                        ForEach(MetronomeSettings.denominators, id: \.self) { unit in
                            Text(verbatim: "1/\(unit)").tag(unit)
                        }
                    }
                    Picker("Click sound", selection: $draft.settings.sound) {
                        ForEach(ClickSound.allCases, id: \.self) { sound in
                            Text(LocalizedStringKey(sound.title)).tag(sound)
                        }
                    }
                    DisclosureGroup("Beat pattern") {
                        ForEach(draft.settings.beats.indices, id: \.self) { index in
                            Picker("Beat \(index + 1)", selection: Binding(
                                get: { draft.settings.beats.indices.contains(index) ? draft.settings.beats[index] : .normal },
                                set: { if draft.settings.beats.indices.contains(index) { draft.settings.beats[index] = $0 } }
                            )) {
                                ForEach(BeatAccent.allCases, id: \.self) { accent in
                                    Text(LocalizedStringKey(accent.title)).tag(accent)
                                }
                            }
                        }
                    }
                    Button("Use current rhythm") { draft.settings = current }
                        .disabled(draft.settings == current)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(isNew ? Text("New preset") : Text("Edit preset"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        do {
                            try save(draft)
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                    .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Song presets", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(verbatim: errorMessage ?? "")
            }
        }
    }
}
