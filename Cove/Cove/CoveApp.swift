import SwiftUI
import SwiftData

@main
struct CoveApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CoveTask.self,
            DailyContract.self,
            UserProfile.self,
            CapturedInput.self,
            SkillCategory.self,
            DailyActivity.self,
            Achievement.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
