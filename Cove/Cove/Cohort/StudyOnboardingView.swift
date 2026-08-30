import SwiftData
import SwiftUI

struct StudyOnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var acceptsStudy = false
    @State private var confirmsAdult = false
    @State private var showsDetails = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            CoveBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("COVE / FOUR-WEEK FIELD STUDY")
                            .font(.caption.weight(.bold))
                            .tracking(1.6)
                            .foregroundStyle(Color.coveOcean)

                        Text("A calmer way to choose today.")
                            .font(.largeTitle.weight(.black))
                            .foregroundStyle(.primary)

                        Text("Capture one thought, decide where it belongs, and protect today with a firm 3 + 2 limit.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        privacyRow(
                            icon: "iphone",
                            title: "Your words stay here",
                            detail: "Entries remain in local app storage on this iPhone. Cove has no account, cloud service, external AI, or analytics SDK."
                        )
                        privacyRow(
                            icon: "chart.bar.doc.horizontal",
                            title: "Evidence is counts, not content",
                            detail: "The study ledger stores journey steps, ratings, and coarse elapsed hours. It never exports entry or task text."
                        )
                        privacyRow(
                            icon: "square.and.arrow.up",
                            title: "Nothing uploads automatically",
                            detail: "You choose whether to share a pseudonymous report. It has a stable study ID and product-interaction data, but no entry or task text."
                        )
                    }
                    .coveCard()

                    DisclosureGroup("Read study details", isExpanded: $showsDetails) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Purpose")
                                .font(.headline)
                            Text("Learn whether Cove's capture and 3 + 2 interaction helps adults with ADHD return weekly for four weeks.")
                            Text("Not medical care")
                                .font(.headline)
                            Text("Cove does not diagnose, treat, or replace professional support. Stop using it if it creates distress.")
                            Text("Shared report")
                                .font(.headline)
                            Text("The study owner may link a report to you through the channel you use to send it. Shared copies are retained for no more than 90 days after the cohort closes, then deleted.")
                            Text("Withdrawal")
                                .font(.headline)
                            Text("Use Erase all local data in Study at any time. This cannot recall a shared copy; ask the study owner through your enrollment channel to delete that copy early.")
                        }
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.top, 12)
                    }
                    .tint(Color.coveOcean)
                    .coveCard()

                    VStack(spacing: 16) {
                        Toggle("I am 18 or older and joining this product study voluntarily.", isOn: $confirmsAdult)
                            .accessibilityIdentifier("consent.adult")
                        Toggle("I understand what stays local, what an exported report contains, and how to erase my data.", isOn: $acceptsStudy)
                            .accessibilityIdentifier("consent.study")
                    }
                    .font(.body)
                    .tint(Color.coveOcean)
                    .coveCard()

                    Button("Agree and begin") {
                        enroll()
                    }
                    .buttonStyle(CovePrimaryButtonStyle())
                    .disabled(!confirmsAdult || !acceptsStudy)
                    .opacity(confirmsAdult && acceptsStudy ? 1 : 0.45)
                    .accessibilityIdentifier("consent.begin")

                    Text("Consent version: \(CohortStore.consentVersion)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
            }
        }
        .alert(
            "Could not begin",
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

    private func privacyRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.coveOcean)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func enroll() {
        do {
            _ = try CohortStore.enroll(in: modelContext)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
