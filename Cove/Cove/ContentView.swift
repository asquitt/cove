import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \CohortParticipant.enrolledAt) private var participants: [CohortParticipant]

    var body: some View {
        Group {
            if let participant = participants.first(where: {
                $0.consentVersion == CohortStore.consentVersion
            }) {
                CohortRootView(participant: participant)
            } else {
                StudyOnboardingView()
            }
        }
    }
}
