import Foundation
import SwiftData

@Model
final class SkillCategory {
    var id: UUID
    var skillType: SkillType
    var totalXP: Int
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \UserProfile.skillCategories)
    var userProfile: UserProfile?

    init(skillType: SkillType) {
        self.id = UUID()
        self.skillType = skillType
        self.totalXP = 0
        self.createdAt = Date()
    }

    var currentLevel: Int {
        (totalXP / Constants.xpPerSkillLevel) + 1
    }

    var levelProgress: Double {
        Double(totalXP % Constants.xpPerSkillLevel) / Double(Constants.xpPerSkillLevel)
    }

    var xpToNextLevel: Int {
        Constants.xpPerSkillLevel - (totalXP % Constants.xpPerSkillLevel)
    }

    func addXP(_ amount: Int) {
        totalXP += amount
    }
}

enum SkillType: String, Codable, CaseIterable {
    case focus
    case energyManagement
    case emotionalRegulation
    case consistency

    var displayName: String {
        switch self {
        case .focus: return "Focus"
        case .energyManagement: return "Energy"
        case .emotionalRegulation: return "Calm"
        case .consistency: return "Consistency"
        }
    }

    var icon: String {
        switch self {
        case .focus: return "eye"
        case .energyManagement: return "bolt.fill"
        case .emotionalRegulation: return "heart.fill"
        case .consistency: return "flame.fill"
        }
    }

    var color: String {
        switch self {
        case .focus: return "deepOcean"
        case .energyManagement: return "warmSand"
        case .emotionalRegulation: return "coralAlert"
        case .consistency: return "zenGreen"
        }
    }
}
