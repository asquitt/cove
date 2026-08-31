import SwiftUI

struct CohortRootView: View {
    let participant: CohortParticipant

    var body: some View {
        TabView {
            NavigationStack {
                TodayView(participant: participant)
            }
            .tabItem {
                Label("Today", systemImage: "sun.max.fill")
            }

            NavigationStack {
                StudyView(participant: participant)
            }
            .tabItem {
                Label("Study", systemImage: "checklist")
            }
        }
        .tint(Color.coveOcean)
    }
}
