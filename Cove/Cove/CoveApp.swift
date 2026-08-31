import Foundation
import SwiftUI
import SwiftData

@main
struct CoveApp: App {
    private let containerResult: Result<ModelContainer, Error>

    init() {
        containerResult = Result {
            let schema = Schema(versionedSchema: CohortSchemaV1.self)
            let usesEphemeralStore = ProcessInfo.processInfo.arguments.contains("--ui-testing-memory")
            let configuration = ModelConfiguration(
                "CoveCohortV1",
                schema: schema,
                isStoredInMemoryOnly: usesEphemeralStore
            )
            let container = try ModelContainer(
                for: schema,
                migrationPlan: CoveMigrationPlan.self,
                configurations: [configuration]
            )
            container.mainContext.autosaveEnabled = false
            return container
        }
    }

    var body: some Scene {
        WindowGroup {
            switch containerResult {
            case .success(let container):
                ContentView()
                    .modelContainer(container)
            case .failure:
                LocalStoreRecoveryView()
            }
        }
    }
}

private struct LocalStoreRecoveryView: View {
    var body: some View {
        ZStack {
            CoveBackdrop()

            VStack(spacing: 18) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.coveCoral)
                    .accessibilityHidden(true)
                Text("Your local data could not be opened safely.")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                Text("Cove did not delete or replace it. Contact the study owner before reinstalling so the existing store can be preserved.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .coveCard()
            .padding(24)
        }
    }
}
