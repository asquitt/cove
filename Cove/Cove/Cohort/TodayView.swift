import SwiftData
import SwiftUI

struct TodayView: View {
    let participant: CohortParticipant

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusItem.createdAt, order: .reverse) private var items: [FocusItem]
    @State private var captureText = ""
    @State private var reviewItem: FocusItem?
    @State private var showsReview = false
    @State private var completionCandidate: FocusItem?
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @SwiftUI.FocusState private var captureFocused: Bool

    init(participant: CohortParticipant) {
        self.participant = participant
    }

    private var todayKey: String {
        DayKey.value(for: Date())
    }

    private var participantItems: [FocusItem] {
        items.filter { $0.participantID == participant.id }
    }

    private var todayItems: [FocusItem] {
        participantItems
            .filter { $0.planDayKey == todayKey && $0.bucket == .doNext }
            .sorted {
                if $0.roleRaw == $1.roleRaw { return $0.createdAt < $1.createdAt }
                return $0.role == .anchor
            }
    }

    private var counts: PlanCounts {
        PlanCounts(
            anchors: todayItems.filter { $0.role == .anchor }.count,
            sideQuests: todayItems.filter { $0.role == .sideQuest }.count
        )
    }

    private var itemsNeedingReview: [FocusItem] {
        participantItems.filter { $0.state == .review }
    }

    private var waitingItems: [FocusItem] {
        participantItems.filter {
            $0.bucket == .doNext &&
            $0.state == .confirmed &&
            $0.planDayKey != todayKey
        }
    }

    var body: some View {
        ZStack {
            CoveBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    captureCard
                    planCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showsReview, onDismiss: {
            reviewItem = nil
        }) {
            if let reviewItem = reviewItem {
                FocusReviewView(
                    item: reviewItem,
                    participant: participant,
                    counts: counts,
                    onSaved: { message in
                        statusMessage = message
                        captureFocused = false
                    }
                )
            }
        }
        .alert(
            "Mark complete?",
            isPresented: Binding(
                get: { completionCandidate != nil },
                set: { if !$0 { completionCandidate = nil } }
            ),
            actions: {
                Button("Cancel", role: .cancel) { completionCandidate = nil }
                Button("Complete") { completeCandidate() }
            },
            message: {
                Text(completionCandidate?.title ?? "This task")
            }
        )
        .alert(
            "Cove could not save",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            ),
            actions: {
                Button("OK", role: .cancel) { errorMessage = nil }
            },
            message: {
                Text(errorMessage ?? "Please try again.")
            }
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.coveOcean)

            Text("One thing at a time.")
                .font(.largeTitle.weight(.black))

            HStack(spacing: 10) {
                capacityPill(label: "Anchors", value: "\(counts.anchors)/3", filled: counts.anchors == 3)
                capacityPill(label: "Side quests", value: "\(counts.sideQuests)/2", filled: counts.sideQuests == 2)
            }
        }
        .padding(.top, 24)
    }

    private var captureCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            CoveSectionLabel(eyebrow: "Capture", title: "What needs your attention?")

            TextEditor(text: $captureText)
                .font(.body)
                .frame(minHeight: 112)
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.primary.opacity(0.04))
                )
                .overlay(alignment: .topLeading) {
                    if captureText.isEmpty {
                        Text("Write the thought as it is. You can sort it next.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(17)
                            .allowsHitTesting(false)
                    }
                }
                .focused($captureFocused)
                .accessibilityLabel("New thought")
                .accessibilityHint("Write up to 500 characters, then choose Review")
                .accessibilityIdentifier("capture.text")

            HStack {
                Text("\(captureText.count)/\(CohortStore.maximumCaptureLength)")
                    .font(.caption)
                    .foregroundStyle(captureText.count > CohortStore.maximumCaptureLength ? Color.coveCoral : Color.secondary)

                Spacer()

                Text("On-device only")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.coveOcean)
            }

            Button(
                action: { beginReview() },
                label: { Label("Review", systemImage: "arrow.right") }
            )
            .buttonStyle(CovePrimaryButtonStyle())
            .disabled(captureText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(captureText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            .accessibilityIdentifier("capture.review")

            if let statusMessage = statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.coveOcean)
                    .accessibilityAddTraits(.isStaticText)
            }

            if !itemsNeedingReview.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Saved for review")
                        .font(.headline)
                    Text("These thoughts are local and waiting for your decision.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(itemsNeedingReview.prefix(3), id: \.id) { item in
                        Button(
                            action: {
                                reviewItem = item
                                showsReview = true
                            },
                            label: {
                                HStack(spacing: 10) {
                                    Text(item.rawText)
                                        .font(.body)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .accessibilityHidden(true)
                                }
                                .frame(maxWidth: .infinity, minHeight: 44)
                            }
                        )
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.coveOcean)
                        .accessibilityLabel("Review saved thought: \(item.rawText)")
                    }
                }
            }
        }
        .coveCard()
    }

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            CoveSectionLabel(eyebrow: "Protected plan", title: "Today's 3 + 2")

            if todayItems.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "water.waves")
                        .font(.largeTitle)
                        .foregroundStyle(Color.coveSeaGlass)
                        .accessibilityHidden(true)
                    Text("No tasks yet")
                        .font(.headline)
                    Text("Review a thought and give it one of today's five protected spots.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                taskSection(title: "Anchors", role: .anchor)
                taskSection(title: "Side quests", role: .sideQuest)
            }

            if !waitingItems.isEmpty {
                Divider()
                waitingSection
            }
        }
        .coveCard()
    }

    private var waitingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Waiting for a spot")
                .font(.headline)
            Text("Saved or unfinished work stays here until you choose a new protected spot.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(waitingItems, id: \.id) { item in
                VStack(alignment: .leading, spacing: 10) {
                    Text(item.title)
                        .font(.body.weight(.semibold))

                    HStack(spacing: 10) {
                        backlogButton(item: item, role: .anchor)
                        backlogButton(item: item, role: .sideQuest)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.primary.opacity(0.04))
                )
            }
        }
    }

    private func backlogButton(item: FocusItem, role: PlanRole) -> some View {
        let available = counts.canAdd(role)
        return Button(role.title) {
            assign(item, as: role)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(available ? Color.coveOcean : Color.secondary)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(available ? Color.coveSeaGlass.opacity(0.15) : Color.primary.opacity(0.03))
        )
        .disabled(!available)
        .accessibilityLabel("Add \(item.title) as \(role.title)")
        .accessibilityValue(available ? "Available" : "Today's \(role.title) spots are full")
    }

    private func taskSection(title: String, role: PlanRole) -> some View {
        let roleItems = todayItems.filter { $0.role == role }
        return VStack(alignment: .leading, spacing: 10) {
            Text("\(title) · \(roleItems.count)/\(role.limit)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)

            if roleItems.isEmpty {
                Text("Open")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
            } else {
                ForEach(roleItems, id: \.id) { item in
                    taskRow(item)
                }
            }
        }
    }

    private func taskRow(_ item: FocusItem) -> some View {
        HStack(spacing: 14) {
            Button(
                action: {
                    guard item.state != .completed else { return }
                    completionCandidate = item
                },
                label: {
                    Image(systemName: item.state == .completed ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(item.state == .completed ? Color.coveOcean : Color.secondary)
                        .frame(width: 44, height: 44)
                }
            )
            .buttonStyle(.plain)
            .disabled(item.state == .completed)
            .accessibilityLabel(item.state == .completed ? "Completed" : "Mark \(item.title) complete")
            .accessibilityIdentifier("task.complete.\(item.id.uuidString)")

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.body.weight(.semibold))
                    .strikethrough(item.state == .completed)
                    .foregroundStyle(item.state == .completed ? .secondary : .primary)
                Text("About \(item.estimatedMinutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    private func capacityPill(label: String, value: String, filled: Bool) -> some View {
        HStack(spacing: 6) {
            Text(label)
            Text(value)
                .fontWeight(.bold)
        }
        .font(.subheadline)
        .foregroundStyle(filled ? Color.white : Color.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(filled ? Color.coveAction : Color.primary.opacity(0.06))
        )
        .accessibilityElement(children: .combine)
    }

    private func beginReview() {
        do {
            let item = try CohortStore.capture(
                captureText,
                participant: participant,
                in: modelContext
            )
            captureText = ""
            captureFocused = false
            reviewItem = item
            showsReview = true
            statusMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func completeCandidate() {
        guard let item = completionCandidate else { return }
        defer { completionCandidate = nil }

        do {
            if try CohortStore.complete(item, participant: participant, in: modelContext) {
                statusMessage = "Marked complete."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func assign(_ item: FocusItem, as role: PlanRole) {
        do {
            if try CohortStore.assignToToday(
                item,
                role: role,
                participant: participant,
                in: modelContext
            ) {
                statusMessage = "Added to today's protected plan."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct FocusReviewView: View {
    let item: FocusItem
    let participant: CohortParticipant
    let counts: PlanCounts
    let onSaved: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedBucket: FocusBucket
    @State private var title: String
    @State private var estimateMinutes: Int
    @State private var selectedRole: PlanRole
    @State private var errorMessage: String?

    init(
        item: FocusItem,
        participant: CohortParticipant,
        counts: PlanCounts,
        onSaved: @escaping (String) -> Void
    ) {
        self.item = item
        self.participant = participant
        self.counts = counts
        self.onSaved = onSaved
        _selectedBucket = State(initialValue: item.suggestedBucket)
        _title = State(initialValue: item.title)
        _estimateMinutes = State(initialValue: 15)
        _selectedRole = State(initialValue: counts.canAdd(.anchor) ? .anchor : .sideQuest)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CoveBackdrop()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Where should this go?")
                                .font(.largeTitle.weight(.black))
                            Text("Cove made a local starting suggestion. You make the decision.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }

                        Text(item.rawText)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .coveCard()

                        VStack(spacing: 10) {
                            ForEach(FocusBucket.allCases, id: \.self) { bucket in
                                bucketButton(bucket)
                            }
                        }

                        if selectedBucket == .doNext {
                            taskFields
                        } else if selectedBucket == .release {
                            Label(
                                "Confirming Let go erases these words immediately. Only a content-free study event remains.",
                                systemImage: "lock.shield"
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .coveCard()
                        }

                        Button(primaryActionTitle) {
                            save(role: selectedBucket == .doNext ? selectedRole : nil)
                        }
                        .buttonStyle(CovePrimaryButtonStyle())
                        .disabled(selectedBucket == .doNext && !counts.canAdd(selectedRole))
                        .opacity(selectedBucket == .doNext && !counts.canAdd(selectedRole) ? 0.45 : 1)
                        .accessibilityIdentifier("review.confirm")

                        if selectedBucket == .doNext {
                            Button("Save for later") {
                                save(role: nil)
                            }
                            .buttonStyle(CoveSecondaryButtonStyle())
                            .accessibilityIdentifier("review.later")
                        }
                    }
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert(
                "Could not save",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                ),
                actions: {
                    Button("OK", role: .cancel) { errorMessage = nil }
                },
                message: {
                    Text(errorMessage ?? "Please try again.")
                }
            )
        }
    }

    private var taskFields: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("One concrete next step")
                    .font(.headline)
                TextField("Task title", text: $title, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("review.title")
            }

            Stepper(value: $estimateMinutes, in: 5...120, step: 5) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Time estimate")
                        .font(.headline)
                    Text("About \(estimateMinutes) minutes")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Choose a protected spot")
                    .font(.headline)

                ForEach(PlanRole.allCases, id: \.self) { role in
                    roleButton(role)
                }
            }
        }
        .coveCard()
    }

    private func bucketButton(_ bucket: FocusBucket) -> some View {
        Button(
            action: { selectedBucket = bucket },
            label: {
                HStack(spacing: 14) {
                    Image(systemName: bucket.systemImage)
                        .font(.title2)
                        .frame(width: 36, height: 36)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(bucket.title)
                            .font(.headline)
                        Text(bucket.explanation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Image(systemName: selectedBucket == bucket ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .accessibilityHidden(true)
                }
                .foregroundStyle(selectedBucket == bucket ? Color.coveOcean : Color.primary)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(selectedBucket == bucket ? Color.coveSeaGlass.opacity(0.18) : Color.primary.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(selectedBucket == bucket ? Color.coveOcean : Color.clear, lineWidth: 2)
                )
            }
        )
        .buttonStyle(.plain)
        .accessibilityLabel("\(bucket.title). \(bucket.explanation)")
        .accessibilityValue(selectedBucket == bucket ? "Selected" : "Not selected")
    }

    private func roleButton(_ role: PlanRole) -> some View {
        let count = counts.count(for: role)
        let available = count < role.limit
        return Button(
            action: { selectedRole = role },
            label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(role.title)
                            .font(.headline)
                        Text(role == .anchor ? "One of today's three priorities" : "Useful if energy allows")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(count)/\(role.limit)")
                        .font(.subheadline.weight(.bold))
                    Image(systemName: selectedRole == role ? "checkmark.circle.fill" : "circle")
                        .accessibilityHidden(true)
                }
                .foregroundStyle(available ? Color.primary : Color.secondary)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(selectedRole == role && available ? Color.coveSeaGlass.opacity(0.18) : Color.primary.opacity(0.04))
                )
            }
        )
        .buttonStyle(.plain)
        .disabled(!available)
        .accessibilityValue(available ? "\(count) of \(role.limit) used" : "Full")
    }

    private var primaryActionTitle: String {
        switch selectedBucket {
        case .doNext: return "Add to today"
        case .keep: return "Keep locally"
        case .release: return "Let it go"
        }
    }

    private func save(role: PlanRole?) {
        do {
            try CohortStore.confirm(
                item,
                bucket: selectedBucket,
                title: title,
                estimateMinutes: estimateMinutes,
                role: selectedBucket == .doNext ? role : nil,
                participant: participant,
                in: modelContext
            )
            let message: String
            switch selectedBucket {
            case .doNext:
                message = role == nil ? "Saved for later." : "Added to today's protected plan."
            case .keep: message = "Saved locally."
            case .release: message = "Released and erased."
            }
            onSaved(message)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
