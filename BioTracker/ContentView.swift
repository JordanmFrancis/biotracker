import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "square.grid.2x2.fill") {
                DashboardView()
            }

            Tab("Trends", systemImage: "chart.xyaxis.line") {
                TrendsView()
            }

            Tab("Timeline", systemImage: "calendar.badge.clock") {
                TimelineView()
            }

            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            BloodDraw.self,
            Biomarker.self,
            BiomarkerReading.self
        ], inMemory: true)
}
