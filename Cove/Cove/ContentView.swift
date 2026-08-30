import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \CohortParticipant.enrolledAt) private var participants: [CohortParticipant]

    var body: some View {
        Group {
            if let participant = participants.first {
                CohortRootView(participant: participant)
            } else {
                StudyOnboardingView()
            }
        }
    }
}
