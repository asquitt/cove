import SwiftUI

extension Color {
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

    // MARK: - Adaptive Color Helper
    /// Creates an adaptive color that changes based on color scheme
    static func adaptive(light: String, dark: String) -> Color {
        Color(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(Color(hex: dark))
            default:
                return UIColor(Color(hex: light))
            }
        })
    }

    // MARK: - Primary Colors (Adaptive)
    static let deepOcean = Color.adaptive(light: "1a365d", dark: "4a90a4")
    static let calmSea = Color.adaptive(light: "2c5282", dark: "5a9fcf")
    static let softWave = Color.adaptive(light: "4a90a4", dark: "6bb5c9")

    // MARK: - State Colors (Adaptive)
    static let zenGreen = Color.adaptive(light: "48bb78", dark: "68d391")
    static let warmSand = Color.adaptive(light: "ed8936", dark: "f6ad55")
    static let coralAlert = Color.adaptive(light: "fc8181", dark: "feb2b2")

    // MARK: - Neutral Colors (Adaptive)
    static let cloudWhite = Color.adaptive(light: "f7fafc", dark: "1a202c")
    static let mistGray = Color.adaptive(light: "e2e8f0", dark: "2d3748")
    static let deepText = Color.adaptive(light: "2d3748", dark: "e2e8f0")
    static let mutedText = Color.adaptive(light: "718096", dark: "a0aec0")

    // MARK: - Card & Surface Colors (Adaptive)
    static let cardBackground = Color.adaptive(light: "ffffff", dark: "2d3748")
    static let surfaceBackground = Color.adaptive(light: "f7fafc", dark: "1a202c")

    // MARK: - Meltdown Mode Colors (Fixed - always dark)
    static let meltdownBackground = Color(hex: "1a202c")
    static let meltdownText = Color(hex: "a0aec0")
    static let meltdownAccent = Color(hex: "4a5568")
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
