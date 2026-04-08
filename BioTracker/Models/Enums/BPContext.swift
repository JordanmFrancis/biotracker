import Foundation

enum BPContext: String, Codable, CaseIterable, Identifiable {
    case restDayAM = "Rest Day AM"
    case postWorkout = "Post-Workout"
    case random = "Random"
    case postMeal = "Post-Meal"
    case preBed = "Pre-Bed"

    var id: String { rawValue }
}
