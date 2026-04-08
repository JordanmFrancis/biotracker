import SwiftUI
import SwiftData

@main
struct BioTrackerApp: App {
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            BloodDraw.self,
            Biomarker.self,
            BiomarkerReading.self
        ])
        let config = ModelConfiguration(
            "BioTracker",
            schema: schema,
            cloudKitDatabase: .none
        )
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    SeedService.seedIfNeeded(modelContext: modelContainer.mainContext)
                }
        }
        .modelContainer(modelContainer)
    }
}
