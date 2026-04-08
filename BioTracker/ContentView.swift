import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Health", systemImage: "heart.text.square.fill") {
                HealthView()
            }

            Tab("Timeline", systemImage: "calendar.badge.clock") {
                TimelineView()
            }

            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        .tint(.brandAccent)
        .preferredColorScheme(.dark)
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
