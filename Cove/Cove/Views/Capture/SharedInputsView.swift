import SwiftUI
import SwiftData

/// View for displaying and importing inputs received from the Share Extension
struct SharedInputsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var shareService = ShareExtensionService()
    @State private var pendingInputs: [SharedInput] = []
    @State private var selectedInputs: Set<String> = []
    @State private var isImporting = false
    @State private var importedCount = 0

    var body: some View {
        NavigationStack {
            Group {
                if pendingInputs.isEmpty {
                    emptyStateView
                } else {
                    inputsListView
                }
            }
            .navigationTitle("Shared Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if !pendingInputs.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Import Selected") {
                            importSelectedInputs()
                        }
                        .disabled(selectedInputs.isEmpty || isImporting)
                    }
                }
            }
            .onAppear {
                loadPendingInputs()
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Shared Items")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Share text from Notes, Safari, or other apps using the Share menu and select \"Send to Cove\"")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Instructions
            VStack(alignment: .leading, spacing: 12) {
                instructionRow(number: 1, text: "Open Apple Notes or Safari")
                instructionRow(number: 2, text: "Select text or tap Share")
                instructionRow(number: 3, text: "Choose \"Send to Cove\"")
                instructionRow(number: 4, text: "Items appear here for import")
            }
            .padding(.top, 24)
        }
        .padding()
    }

    private func instructionRow(number: Int, text: String) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.deepOcean)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
        }
    }

    // MARK: - Inputs List

    private var inputsListView: some View {
        List {
            Section {
                ForEach(pendingInputs) { input in
                    SharedInputRow(
                        input: input,
                        isSelected: selectedInputs.contains(input.id),
                        onToggle: { toggleSelection(input.id) }
                    )
                }
            } header: {
                HStack {
                    Text("\(pendingInputs.count) item\(pendingInputs.count == 1 ? "" : "s") waiting")
                    Spacer()
                    Button(selectedInputs.count == pendingInputs.count ? "Deselect All" : "Select All") {
                        toggleSelectAll()
                    }
                    .font(.caption)
                }
            } footer: {
                Text("Selected items will be imported to your capture inbox for AI classification.")
            }

            if importedCount > 0 {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.zenGreen)
                        Text("\(importedCount) item\(importedCount == 1 ? "" : "s") imported")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func loadPendingInputs() {
        pendingInputs = shareService.fetchPendingInputs()
    }

    private func toggleSelection(_ id: String) {
        if selectedInputs.contains(id) {
            selectedInputs.remove(id)
        } else {
            selectedInputs.insert(id)
        }
    }

    private func toggleSelectAll() {
        if selectedInputs.count == pendingInputs.count {
            selectedInputs.removeAll()
        } else {
            selectedInputs = Set(pendingInputs.map { $0.id })
        }
    }

    private func importSelectedInputs() {
        isImporting = true

        let inputsToImport = pendingInputs.filter { selectedInputs.contains($0.id) }

        for input in inputsToImport {
            _ = shareService.importAsCapture(input, modelContext: modelContext)
            shareService.clearPendingInput(id: input.id)
        }

        importedCount += inputsToImport.count
        selectedInputs.removeAll()
        loadPendingInputs()
        isImporting = false

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Row View

struct SharedInputRow: View {
    let input: SharedInput
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.deepOcean : Color.secondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    // Preview text
                    Text(input.text)
                        .font(.subheadline)
                        .lineLimit(3)
                        .foregroundStyle(.primary)

                    // Metadata
                    HStack(spacing: 8) {
                        Label(input.sourceDisplayName, systemImage: "square.and.arrow.down")
                        Text("•")
                        Text(input.formattedTimestamp)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SharedInputsView()
}
