import SwiftUI
import SwiftData

struct StagingAreaView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<CapturedInput> { $0.status == .processed },
        sort: \CapturedInput.createdAt,
        order: .reverse
    )
    private var pendingCaptures: [CapturedInput]

    @State private var selectedCapture: CapturedInput?

    var body: some View {
        NavigationStack {
            Group {
                if pendingCaptures.isEmpty {
                    emptyState
                } else {
                    captureList
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.cloudWhite)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.mutedText.opacity(0.5))

            Text("No items to review")
                .font(.headline)
                .foregroundColor(.mutedText)

            Text("Capture something first")
                .font(.bodyMedium)
                .foregroundColor(.mutedText.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var captureList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(pendingCaptures) { capture in
                    StagingCard(capture: capture) { action in
                        handleAction(action, for: capture)
                    }
                }
            }
            .padding(Spacing.lg)
        }
    }

    private func handleAction(_ action: StagingAction, for capture: CapturedInput) {
        withAnimation(.spring(response: 0.3)) {
            switch action {
            case .confirm:
                confirmCapture(capture)
            case .dismiss:
                dismissCapture(capture)
            case .edit:
                selectedCapture = capture
            }
        }
    }

    private func confirmCapture(_ capture: CapturedInput) {
        capture.markConfirmed()

        // Create tasks from the classification result if directive
        if capture.classifiedBucket == .directive,
           let responseJSON = capture.aiResponse,
           let data = responseJSON.data(using: .utf8),
           let result = try? JSONDecoder().decode(ClassificationResult.self, from: data),
           let tasks = result.tasks {
            for suggestion in tasks {
                let task = CoveTask(
                    title: suggestion.title,
                    estimatedMinutes: suggestion.estimatedMinutes,
                    interestLevel: suggestion.interest,
                    energyRequired: suggestion.energy
                )
                modelContext.insert(task)
                capture.generatedTasks.append(task)
            }
        }
    }

    private func dismissCapture(_ capture: CapturedInput) {
        capture.markDismissed()
    }
}

// MARK: - Staging Action
enum StagingAction {
    case confirm
    case dismiss
    case edit
}

// MARK: - Staging Card
struct StagingCard: View {
    let capture: CapturedInput
    let onAction: (StagingAction) -> Void

    @State private var offset: CGFloat = 0
    @State private var isDragging = false

    private let swipeThreshold: CGFloat = 100

    var body: some View {
        ZStack {
            // Swipe backgrounds
            HStack {
                // Left swipe (dismiss)
                Rectangle()
                    .fill(Color.coralAlert.opacity(0.2))
                    .overlay(
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.coralAlert)
                            Spacer()
                        }
                        .padding(.leading, Spacing.lg)
                    )

                Spacer()

                // Right swipe (confirm)
                Rectangle()
                    .fill(Color.zenGreen.opacity(0.2))
                    .overlay(
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.zenGreen)
                        }
                        .padding(.trailing, Spacing.lg)
                    )
            }

            // Main card
            cardContent
                .offset(x: offset)
                .gesture(swipeGesture)
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                bucketBadge
                Spacer()
                Text(capture.timeAgo)
                    .font(.caption)
                    .foregroundColor(.mutedText)
            }

            // Content
            Text(capture.rawText)
                .font(.bodyMedium)
                .foregroundColor(.deepText)
                .lineLimit(3)

            // Classification info
            if let bucket = capture.classifiedBucket {
                classificationInfo(bucket)
            }

            // Action buttons
            actionButtons
        }
        .padding(Spacing.lg)
        .background(Color.white)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private var bucketBadge: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: capture.source.icon)
                .font(.caption)
            Text(capture.classifiedBucket?.displayName ?? "Processing")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(bucketColor)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(bucketColor.opacity(0.1))
        .cornerRadius(CornerRadius.full)
    }

    private var bucketColor: Color {
        switch capture.classifiedBucket {
        case .directive: return .deepOcean
        case .archive: return .warmSand
        case .venting: return .coralAlert
        case nil: return .mutedText
        }
    }

    @ViewBuilder
    private func classificationInfo(_ bucket: TaskBucket) -> some View {
        switch bucket {
        case .directive:
            if let responseJSON = capture.aiResponse,
               let data = responseJSON.data(using: .utf8),
               let result = try? JSONDecoder().decode(ClassificationResult.self, from: data),
               let tasks = result.tasks, !tasks.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(tasks.indices, id: \.self) { index in
                        taskPreview(tasks[index])
                    }
                }
            }
        case .archive:
            if let note = parseArchiveNote() {
                Text(note)
                    .font(.caption)
                    .foregroundColor(.mutedText)
                    .italic()
            }
        case .venting:
            if let response = parseVentingResponse() {
                Text(response)
                    .font(.caption)
                    .foregroundColor(.mutedText)
                    .italic()
            }
        }
    }

    private func taskPreview(_ task: TaskSuggestion) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "arrow.right.circle")
                .font(.caption)
                .foregroundColor(.calmSea)

            Text(task.title)
                .font(.caption)
                .foregroundColor(.deepText)
                .lineLimit(1)

            Spacer()

            Text("\(task.estimatedMinutes)m")
                .font(.caption2)
                .foregroundColor(.mutedText)
        }
    }

    private func parseArchiveNote() -> String? {
        guard let json = capture.aiResponse,
              let data = json.data(using: .utf8),
              let result = try? JSONDecoder().decode(ClassificationResult.self, from: data) else {
            return nil
        }
        return result.archiveNote
    }

    private func parseVentingResponse() -> String? {
        guard let json = capture.aiResponse,
              let data = json.data(using: .utf8),
              let result = try? JSONDecoder().decode(ClassificationResult.self, from: data) else {
            return nil
        }
        return result.ventingResponse
    }

    private var actionButtons: some View {
        HStack(spacing: Spacing.md) {
            Button(action: { onAction(.dismiss) }) {
                Label("Dismiss", systemImage: "xmark")
                    .font(.caption)
                    .foregroundColor(.coralAlert)
            }

            Spacer()

            Button(action: { onAction(.confirm) }) {
                Label("Confirm", systemImage: "checkmark")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.zenGreen)
                    .cornerRadius(CornerRadius.md)
            }
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                offset = value.translation.width
            }
            .onEnded { value in
                isDragging = false
                let velocity = value.predictedEndTranslation.width

                if offset > swipeThreshold || velocity > 300 {
                    withAnimation(.spring(response: 0.3)) {
                        offset = UIScreen.main.bounds.width
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onAction(.confirm)
                    }
                } else if offset < -swipeThreshold || velocity < -300 {
                    withAnimation(.spring(response: 0.3)) {
                        offset = -UIScreen.main.bounds.width
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onAction(.dismiss)
                    }
                } else {
                    withAnimation(.spring(response: 0.3)) {
                        offset = 0
                    }
                }
            }
    }
}

#Preview {
    StagingAreaView()
        .modelContainer(for: [CapturedInput.self, CoveTask.self], inMemory: true)
}
