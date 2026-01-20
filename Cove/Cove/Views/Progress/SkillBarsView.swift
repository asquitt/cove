import SwiftUI

struct SkillBarsView: View {
    let skills: [SkillCategory]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Skills")
                .font(.title3)
                .foregroundColor(.deepText)

            ForEach(skills, id: \.id) { skill in
                SkillBarRow(skill: skill)
            }
        }
        .padding(Spacing.lg)
        .background(Color.white)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct SkillBarRow: View {
    let skill: SkillCategory

    private var skillColor: Color {
        switch skill.skillType {
        case .focus: return .deepOcean
        case .energyManagement: return .warmSand
        case .emotionalRegulation: return .coralAlert
        case .consistency: return .zenGreen
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: skill.skillType.icon)
                    .foregroundColor(skillColor)
                    .font(.caption)

                Text(skill.skillType.displayName)
                    .font(.caption)
                    .foregroundColor(.deepText)

                Spacer()

                Text("Lv \(skill.currentLevel)")
                    .font(.captionBold)
                    .foregroundColor(skillColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.mistGray)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(skillColor)
                        .frame(width: geometry.size.width * skill.levelProgress)
                        .animation(.spring(response: 0.5), value: skill.levelProgress)
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    SkillBarsView(skills: [
        SkillCategory(skillType: .focus),
        SkillCategory(skillType: .energyManagement),
        SkillCategory(skillType: .emotionalRegulation),
        SkillCategory(skillType: .consistency)
    ])
    .padding()
    .background(Color.cloudWhite)
}
