import SwiftUI

/// Settings view for Obsidian integration
struct ObsidianSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var obsidianService = ObsidianService()
    @State private var vaultName = ""
    @State private var showingExportSheet = false

    var body: some View {
        NavigationStack {
            List {
                connectionSection
                settingsSection
                exportSection
                infoSection
            }
            .navigationTitle("Obsidian")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Connection Section

    private var connectionSection: some View {
        Section {
            if obsidianService.isConfigured {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.zenGreen)
                    VStack(alignment: .leading) {
                        Text("Connected")
                            .foregroundColor(.deepText)
                        if let path = obsidianService.vaultPath {
                            Text(path)
                                .font(.caption)
                                .foregroundColor(.mutedText)
                        }
                    }
                    Spacer()
                    Button("Disconnect") {
                        obsidianService.disconnect()
                        vaultName = ""
                    }
                    .foregroundColor(.coralAlert)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Vault Name", text: $vaultName)
                        .textFieldStyle(.roundedBorder)

                    Text("Enter your Obsidian vault name to enable export features.")
                        .font(.caption)
                        .foregroundColor(.mutedText)

                    Button {
                        obsidianService.configure(vaultPath: vaultName)
                    } label: {
                        HStack {
                            Image(systemName: "link")
                            Text("Connect Vault")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(vaultName.isEmpty ? Color.mistGray : Color.calmSea)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(vaultName.isEmpty)
                }
            }

            if !ObsidianService.isObsidianInstalled {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.warmSand)
                    Text("Obsidian app not detected")
                        .font(.caption)
                        .foregroundColor(.warmSand)
                }
            }
        } header: {
            Text("Vault Connection")
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        Section {
            HStack {
                Text("Daily Notes Folder")
                Spacer()
                TextField("Folder", text: Binding(
                    get: { obsidianService.dailyNotesFolder },
                    set: { obsidianService.dailyNotesFolder = $0 }
                ))
                .multilineTextAlignment(.trailing)
                .foregroundColor(.secondary)
            }

            HStack {
                Text("Tasks Folder")
                Spacer()
                TextField("Folder", text: Binding(
                    get: { obsidianService.taskNotesFolder },
                    set: { obsidianService.taskNotesFolder = $0 }
                ))
                .multilineTextAlignment(.trailing)
                .foregroundColor(.secondary)
            }

            Picker("Date Format", selection: Binding(
                get: { obsidianService.dailyNoteDateFormat },
                set: { obsidianService.dailyNoteDateFormat = $0 }
            )) {
                Text("2024-01-15").tag("yyyy-MM-dd")
                Text("Jan 15, 2024").tag("MMM dd, yyyy")
                Text("15-01-2024").tag("dd-MM-yyyy")
            }
        } header: {
            Text("Export Settings")
        }
    }

    // MARK: - Export Section

    private var exportSection: some View {
        Section {
            Button {
                obsidianService.openDailyNoteInObsidian()
            } label: {
                Label("Open Today's Note", systemImage: "doc.text")
            }
            .disabled(!obsidianService.isConfigured || !ObsidianService.isObsidianInstalled)

            Button {
                showingExportSheet = true
            } label: {
                Label("Export Options", systemImage: "square.and.arrow.up")
            }
            .disabled(!obsidianService.isConfigured)
        } header: {
            Text("Quick Actions")
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportOptionsSheet(obsidianService: obsidianService)
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label("Export tasks as markdown", systemImage: "doc.plaintext")
                Label("Create daily note templates", systemImage: "calendar")
                Label("Generate weekly summaries", systemImage: "chart.bar")
                Label("Link to your knowledge base", systemImage: "link")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        } header: {
            Text("Features")
        } footer: {
            Text("Cove exports tasks in Obsidian-compatible markdown with YAML frontmatter for easy organization.")
        }
    }
}

// MARK: - Export Options Sheet

struct ExportOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let obsidianService: ObsidianService

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        obsidianService.openDailyNoteInObsidian()
                        dismiss()
                    } label: {
                        Label("Today's Daily Note", systemImage: "calendar")
                    }

                    Button {
                        // Would need contract data passed in
                    } label: {
                        Label("Current Contract", systemImage: "doc.text")
                    }
                } header: {
                    Text("Quick Export")
                }

                Section {
                    Label("Export All Tasks", systemImage: "tray.full")
                    Label("Export Week Summary", systemImage: "chart.bar")
                    Label("Export Archive", systemImage: "archivebox")
                } header: {
                    Text("Bulk Export")
                } footer: {
                    Text("Bulk exports will be saved to your Files app for import into Obsidian.")
                }
            }
            .navigationTitle("Export to Obsidian")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Task Export Button (for TaskCardView)

struct ObsidianExportButton: View {
    let task: CoveTask
    @State private var obsidianService = ObsidianService()
    @State private var showingShareSheet = false
    @State private var exportData: Data?
    @State private var exportFilename: String = ""

    var body: some View {
        Button {
            if let result = obsidianService.exportTaskToFile(task) {
                exportData = result.data
                exportFilename = result.filename
                showingShareSheet = true
            }
        } label: {
            Label("Export to Obsidian", systemImage: "square.and.arrow.up")
        }
        .sheet(isPresented: $showingShareSheet) {
            if let data = exportData {
                ShareSheet(items: [MarkdownFile(data: data, filename: exportFilename)])
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Markdown File for Sharing

class MarkdownFile: NSObject, UIActivityItemSource {
    let data: Data
    let filename: String

    init(data: Data, filename: String) {
        self.data = data
        self.filename = filename
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        filename
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        // Create temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: tempURL)
        return tempURL
    }

    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        "net.daringfireball.markdown"
    }
}

#Preview {
    ObsidianSettingsView()
}
