import SwiftData
import SwiftUI

struct StudyView: View {
    let participant: CohortParticipant

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudyEvent.occurredAt) private var events: [StudyEvent]
    @Query(sort: \WeeklyCheckIn.studyWeek) private var checkIns: [WeeklyCheckIn]
    @Query(sort: \FocusItem.createdAt, order: .reverse) private var items: [FocusItem]
    @State private var helpfulness = 3
    @State private var wouldMiss = 3
    @State private var friction = FrictionReason.none
    @State private var willingToPay = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @State private var confirmsDeletion = false

    private var currentWeek: Int {
        StudyWeek.number(enrolledAt: participant.enrolledAt, at: Date())
    }

    private var participantEvents: [StudyEvent] {
        events.filter { $0.participantID == participant.id }
    }

    private var participantCheckIns: [WeeklyCheckIn] {
        checkIns.filter { $0.participantID == participant.id }
    }

    private var snapshot: StudyMetricsSnapshot {
        StudyMetrics.snapshot(events: participantEvents, checkIns: participantCheckIns)
    }

    private var currentCheckIn: WeeklyCheckIn? {
        participantCheckIns.first { $0.studyWeek == currentWeek }
    }

    private var reportJSON: String? {
        try? CohortReport.make(
            participant: participant,
            events: participantEvents,
            checkIns: participantCheckIns
        ).encodedJSON()
    }

    var body: some View {
        ZStack {
            CoveBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    evidenceCard
                    checkInCard
                    localDataCard
                    privacyCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
        .navigationBarHidden(true)
        .alert(
            "Erase everything in Cove?",
            isPresented: $confirmsDeletion,
            actions: {
                Button("Cancel", role: .cancel) {}
                Button("Erase all local data", role: .destructive) { eraseAllData() }
            },
            message: {
                Text("This removes entries, tasks, check-ins, consent, and the study ledger from this app. It cannot recall reports you already shared.")
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
            Text("LOCAL STUDY LEDGER")
                .font(.caption.weight(.bold))
                .tracking(1.6)
                .foregroundStyle(Color.coveOcean)
            Text(currentWeek <= 4 ? "Study week \(currentWeek) of 4" : "Four-week window complete")
                .font(.largeTitle.weight(.black))
            Text("Participant \(participant.id.uuidString.prefix(8)) · consent \(participant.consentVersion)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Anonymous participant identifier \(participant.id.uuidString.prefix(8))")
        }
        .padding(.top, 24)
    }

    private var evidenceCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            CoveSectionLabel(eyebrow: "Evidence", title: "What this device can prove")

            HStack(spacing: 12) {
                metricTile(value: snapshot.activated ? "Yes" : "Not yet", label: "Activated", identifier: "study.metric.activation")
                metricTile(value: "\(snapshot.retainedWeeks.count)/4", label: "Weeks used", identifier: "study.metric.retention")
                metricTile(value: "\(snapshot.feedbackWeeks.count)/4", label: "Check-ins", identifier: "study.metric.feedback")
            }

            Text("A week counts only after a captured thought is reviewed, assigned to today, and that same task is completed.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .coveCard()
    }

    @ViewBuilder
    private var checkInCard: some View {
        if (1...4).contains(currentWeek) {
            VStack(alignment: .leading, spacing: 18) {
                CoveSectionLabel(eyebrow: "About one minute", title: "Week \(currentWeek) check-in")

                ratingControl(title: "Cove helped me decide what to do", value: $helpfulness)
                ratingControl(title: "I would miss Cove if it disappeared", value: $wouldMiss)

                VStack(alignment: .leading, spacing: 8) {
                    Text("What slowed you down most?")
                        .font(.headline)
                    Picker("Biggest friction", selection: $friction) {
                        ForEach(FrictionReason.allCases, id: \.self) { reason in
                            Text(reason.title).tag(reason)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.coveOcean)
                    .disabled(currentCheckIn != nil)
                }

                if currentWeek == 4 {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle(isOn: $willingToPay) {
                            Text("After this study, I would choose Cove at $4.99 per month.")
                                .font(.headline)
                        }
                        .tint(Color.coveOcean)
                        .disabled(currentCheckIn != nil)
                        Text("This records stated willingness to pay. It is not a purchase and no charge occurs.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Button(currentCheckIn == nil ? "Save week \(currentWeek) check-in" : "Week \(currentWeek) check-in saved") {
                    submitCheckIn()
                }
                .buttonStyle(CovePrimaryButtonStyle())
                .disabled(currentCheckIn != nil)
                .opacity(currentCheckIn == nil ? 1 : 0.55)
                .accessibilityIdentifier("study.checkin.save")

                if let statusMessage = statusMessage {
                    Label(statusMessage, systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.coveOcean)
                }
            }
            .coveCard()
            .onAppear(perform: loadCurrentCheckIn)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                CoveSectionLabel(eyebrow: "Study window", title: "Check-ins are complete")
                Text("You can still review, export, or erase the local study record below.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .coveCard()
        }
    }

    private var localDataCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            CoveSectionLabel(eyebrow: "On this iPhone", title: "My local entries")

            if items.isEmpty {
                Text("No entries yet.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items.prefix(12), id: \.id) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.bucket?.systemImage ?? "questionmark.circle")
                            .foregroundStyle(Color.coveOcean)
                            .frame(width: 28, height: 28)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.rawText.isEmpty ? "Released entry" : item.rawText)
                                .font(.body)
                                .lineLimit(3)
                            Text("\((item.bucket ?? item.suggestedBucket).title) · \(item.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .coveCard()
    }

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            CoveSectionLabel(eyebrow: "You control it", title: "Export or withdraw")

            Text("The report contains anonymous event names, coarse elapsed hours, closed-choice ratings, and outcome counts. It contains no entry or task text and is never sent automatically.")
                .font(.body)
                .foregroundStyle(.secondary)

            if let reportJSON = reportJSON {
                ShareLink(
                    item: reportJSON,
                    subject: Text("Cove four-week study report"),
                    message: Text("Content-free local study evidence from Cove.")
                ) {
                    Label("Share anonymous report", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(CoveSecondaryButtonStyle())
                .accessibilityIdentifier("study.report.share")
            } else {
                Text("The report is temporarily unavailable.")
                    .font(.subheadline)
                    .foregroundStyle(Color.coveCoral)
            }

            Button(
                role: .destructive,
                action: { confirmsDeletion = true },
                label: {
                    Label("Erase all local data", systemImage: "trash")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
            )
            .accessibilityIdentifier("study.erase")
        }
        .coveCard()
    }

    private func metricTile(value: String, label: String, identifier: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.black))
                .foregroundStyle(Color.coveOcean)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 76)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.coveSeaGlass.opacity(0.12))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
        .accessibilityIdentifier(identifier)
    }

    private func ratingControl(title: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { rating in
                    Button("\(rating)") {
                        value.wrappedValue = rating
                    }
                    .font(.headline)
                    .foregroundStyle(value.wrappedValue == rating ? Color.white : Color.primary)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(value.wrappedValue == rating ? Color.coveAction : Color.primary.opacity(0.05))
                    )
                    .accessibilityLabel("\(title), \(rating) of 5")
                    .accessibilityValue(value.wrappedValue == rating ? "Selected" : "Not selected")
                    .disabled(currentCheckIn != nil)
                }
            }
            Text("1 = not at all · 5 = strongly")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func loadCurrentCheckIn() {
        guard let checkIn = currentCheckIn else { return }
        helpfulness = checkIn.helpfulness
        wouldMiss = checkIn.wouldMiss
        friction = checkIn.friction
        willingToPay = checkIn.willingToPay
    }

    private func submitCheckIn() {
        do {
            _ = try CohortStore.submitCheckIn(
                participant: participant,
                helpfulness: helpfulness,
                wouldMiss: wouldMiss,
                friction: friction,
                willingToPay: currentWeek == 4 && willingToPay,
                in: modelContext
            )
            statusMessage = "Week \(currentWeek) saved on this iPhone."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func eraseAllData() {
        do {
            try CohortStore.deleteAllData(in: modelContext)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
