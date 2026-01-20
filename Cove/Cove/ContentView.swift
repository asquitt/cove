import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            ContractView()
                .tabItem {
                    Label("Contract", systemImage: "doc.text.fill")
                }
                .tag(1)

            CaptureView()
                .tabItem {
                    Label("Capture", systemImage: "plus.circle.fill")
                }
                .tag(2)

            CalendarView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(3)

            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
                .tag(4)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(5)
        }
        .tint(.deepOcean)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [CoveTask.self, DailyContract.self, UserProfile.self, CapturedInput.self, SkillCategory.self, DailyActivity.self, Achievement.self], inMemory: true)
}
