import SwiftUI
import SwiftData

/// Bail-out message generator for canceling/rescheduling commitments
/// PRD 6.5.3 - Remove social anxiety from canceling commitments
struct BailOutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var recipientName: String = ""
    @State private var context: String = ""
    @State private var selectedTone: MessageTone = .casual
    @State private var generatedMessage: String = ""
    @State private var isGenerating = false
    @State private var showCopiedFeedback = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    inputSection
                    toneSelector

                    if !generatedMessage.isEmpty {
                        generatedMessageSection
                    }

                    generateButton

                    if let error = error {
                        errorView(error)
                    }
                }
                .padding()
            }
            .background(Color.cloudWhite)
            .navigationTitle("Bail Out")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.deepOcean)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 48))
                .foregroundColor(.calmSea)

            Text("Need to cancel or reschedule?")
                .font(.headline)
                .foregroundColor(.deepText)

            Text("Let me help you craft a message. No shame, just self-care.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Recipient name
            VStack(alignment: .leading, spacing: 8) {
                Text("Who are you messaging?")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.deepText)

                TextField("Name (optional)", text: $recipientName)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
            }

            // Context
            VStack(alignment: .leading, spacing: 8) {
                Text("What are you canceling?")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.deepText)

                TextField("e.g., \"our meeting tomorrow\"", text: $context)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Tone Selector

    private var toneSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose your tone")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.deepText)

            HStack(spacing: 12) {
                ForEach(MessageTone.allCases, id: \.self) { tone in
                    ToneButton(
                        tone: tone,
                        isSelected: selectedTone == tone,
                        action: { selectedTone = tone }
                    )
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Generated Message

    private var generatedMessageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your message")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.deepText)

                Spacer()

                Button {
                    copyToClipboard()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                        Text(showCopiedFeedback ? "Copied!" : "Copy")
                    }
                    .font(.caption)
                    .foregroundColor(.calmSea)
                }
            }

            Text(generatedMessage)
                .font(.body)
                .foregroundColor(.deepText)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.mistGray.opacity(0.5))
                .cornerRadius(12)

            // Regenerate button
            Button {
                Task { await generateMessage() }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Regenerate")
                }
                .font(.subheadline)
                .foregroundColor(.calmSea)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            Task { await generateMessage() }
        } label: {
            HStack {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "wand.and.stars")
                    Text("Generate Message")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(context.isEmpty ? Color.mistGray : Color.deepOcean)
            .cornerRadius(16)
        }
        .disabled(context.isEmpty || isGenerating)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
            Text(message)
        }
        .font(.caption)
        .foregroundColor(.warmSand)
        .padding()
        .background(Color.warmSand.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Actions

    private func generateMessage() async {
        guard !context.isEmpty else { return }

        isGenerating = true
        error = nil

        // Build the message locally (no API call for bail-out to save costs)
        // This follows the tone and provides a polished message
        let message = buildBailOutMessage(
            recipientName: recipientName.isEmpty ? nil : recipientName,
            context: context,
            tone: selectedTone
        )

        // Small delay for UX
        try? await Task.sleep(nanoseconds: 500_000_000)

        await MainActor.run {
            generatedMessage = message
            isGenerating = false

            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = generatedMessage
        showCopiedFeedback = true

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Reset feedback after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopiedFeedback = false
        }
    }

    private func buildBailOutMessage(recipientName: String?, context: String, tone: MessageTone) -> String {
        let greeting = recipientName.map { "Hi \($0)," } ?? "Hi,"

        switch tone {
        case .formal:
            return """
            \(greeting)

            I hope this message finds you well. I regret to inform you that I need to reschedule \(context). I apologize for any inconvenience this may cause.

            Would it be possible to find an alternative time that works for both of us? I appreciate your understanding and flexibility.

            Best regards
            """

        case .casual:
            return """
            \(greeting)

            Something came up and I won't be able to make \(context). I'm really sorry about this!

            Could we reschedule? Let me know what times work for you.

            Thanks for understanding!
            """

        case .brief:
            return """
            \(greeting)

            I need to reschedule \(context). Apologies for the short notice. What times work for you instead?

            Thanks
            """
        }
    }
}

// MARK: - Message Tone

enum MessageTone: String, CaseIterable {
    case formal = "Formal"
    case casual = "Casual"
    case brief = "Brief"

    var icon: String {
        switch self {
        case .formal: return "briefcase"
        case .casual: return "face.smiling"
        case .brief: return "bolt"
        }
    }

    var description: String {
        switch self {
        case .formal: return "Professional"
        case .casual: return "Friendly"
        case .brief: return "Quick"
        }
    }
}

// MARK: - Tone Button

struct ToneButton: View {
    let tone: MessageTone
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: tone.icon)
                    .font(.title2)
                Text(tone.description)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.deepOcean : Color.mistGray.opacity(0.5))
            .foregroundColor(isSelected ? .white : .deepText)
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview

#Preview {
    BailOutView()
}
