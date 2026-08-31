import SwiftUI

extension Color {
    static let coveInk = Color(red: 0.035, green: 0.12, blue: 0.17)
    static let coveAction = Color(red: 0.035, green: 0.31, blue: 0.34)
    static let coveOcean = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.43, green: 0.82, blue: 0.76, alpha: 1)
        }
        return UIColor(red: 0.035, green: 0.31, blue: 0.34, alpha: 1)
    })
    static let coveSeaGlass = Color(red: 0.45, green: 0.72, blue: 0.68)
    static let coveSand = Color(red: 0.95, green: 0.83, blue: 0.63)
    static let coveCoral = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 1, green: 0.55, blue: 0.46, alpha: 1)
        }
        return UIColor(red: 0.72, green: 0.22, blue: 0.16, alpha: 1)
    })
    static let coveCream = Color(red: 0.98, green: 0.96, blue: 0.91)
}

struct CoveBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.coveInk : Color.coveCream)
                .ignoresSafeArea()

            Circle()
                .fill(Color.coveSeaGlass.opacity(colorScheme == .dark ? 0.10 : 0.20))
                .frame(width: 320, height: 320)
                .offset(x: 150, y: -280)

            Circle()
                .fill(Color.coveSand.opacity(colorScheme == .dark ? 0.08 : 0.22))
                .frame(width: 260, height: 260)
                .offset(x: -170, y: 340)
        }
        .accessibilityHidden(true)
    }
}

struct CoveCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.07) : Color.white.opacity(0.86))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.coveOcean.opacity(colorScheme == .dark ? 0.35 : 0.10), lineWidth: 1)
            )
    }
}

extension View {
    func coveCard() -> some View {
        modifier(CoveCardModifier())
    }
}

struct CovePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.coveAction.opacity(configuration.isPressed ? 0.78 : 1))
            )
            .contentShape(Rectangle())
    }
}

struct CoveSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.coveOcean)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.coveSeaGlass.opacity(configuration.isPressed ? 0.24 : 0.14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.coveOcean.opacity(0.24), lineWidth: 1)
            )
            .contentShape(Rectangle())
    }
}

struct CoveSectionLabel: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.4)
                .foregroundStyle(Color.coveOcean)
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
