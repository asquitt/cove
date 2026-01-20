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

            CaptureView()
                .tabItem {
                    Label("Capture", systemImage: "mic.fill")
                }
                .tag(1)

            ContractView()
                .tabItem {
                    Label("Contract", systemImage: "doc.text.fill")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(.deepOcean)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            CoveTask.self,
            DailyContract.self,
            UserProfile.self,
            CapturedInput.self
        ], inMemory: true)
}
