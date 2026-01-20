import SwiftUI

extension Color {
    // MARK: - Primary Colors
    static let deepOcean = Color(hex: "1a365d")
    static let calmSea = Color(hex: "2c5282")
    static let softWave = Color(hex: "4a90a4")

    // MARK: - State Colors
    static let zenGreen = Color(hex: "48bb78")
    static let warmSand = Color(hex: "ed8936")
    static let coralAlert = Color(hex: "fc8181")

    // MARK: - Neutral Colors
    static let cloudWhite = Color(hex: "f7fafc")
    static let mistGray = Color(hex: "e2e8f0")
    static let deepText = Color(hex: "2d3748")
    static let mutedText = Color(hex: "718096")

    // MARK: - Meltdown Mode Colors
    static let meltdownBackground = Color(hex: "1a202c")
    static let meltdownText = Color(hex: "a0aec0")
    static let meltdownAccent = Color(hex: "4a5568")

    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Interest Level Colors
extension InterestLevel {
    var color: Color {
        switch self {
        case .high: return .zenGreen
        case .medium: return .warmSand
        case .low: return .mistGray
        }
    }
}

// MARK: - Energy Level Colors
extension EnergyLevel {
    var color: Color {
        switch self {
        case .high: return .coralAlert
        case .medium: return .warmSand
        case .low: return .softWave
        }
    }
}

// MARK: - Task Status Colors
extension TaskStatus {
    var color: Color {
        switch self {
        case .pending: return .mistGray
        case .inProgress: return .softWave
        case .completed: return .zenGreen
        case .snoozed: return .warmSand
        case .cancelled: return .mutedText
        }
    }
}
