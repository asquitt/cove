import SwiftUI
import SwiftData

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var inputText = ""
    @State private var isRecording = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerSection

                Spacer()

                // Main capture area
                captureArea

                Spacer()

                // Input field
                textInputSection
            }
            .background(Color.cloudWhite)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Capture")
                .font(.largeTitle)
                .foregroundColor(.deepText)

            Text("Speak or type your thoughts")
                .font(.bodyMedium)
                .foregroundColor(.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
    }

    private var captureArea: some View {
        VStack(spacing: Spacing.xl) {
            // Voice capture button
            VoiceCaptureButton(isRecording: $isRecording) {
                toggleRecording()
            }

            // Recording status
            if isRecording {
                recordingIndicator
            }

            // Instructions
            instructionText
        }
        .padding(Spacing.lg)
    }

    private var recordingIndicator: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(Color.coralAlert)
                .frame(width: 8, height: 8)

            Text("Listening...")
                .font(.bodyMedium)
                .foregroundColor(.coralAlert)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.coralAlert.opacity(0.1))
        .cornerRadius(CornerRadius.full)
    }

    private var instructionText: some View {
        VStack(spacing: Spacing.sm) {
            Text("Just say what's on your mind")
                .font(.bodyMedium)
                .foregroundColor(.mutedText)

            Text("I'll help you sort it out")
                .font(.caption)
                .foregroundColor(.mutedText.opacity(0.7))
        }
        .multilineTextAlignment(.center)
    }

    private var textInputSection: some View {
        HStack(spacing: Spacing.md) {
            TextField("Or type here...", text: $inputText, axis: .vertical)
                .font(.bodyMedium)
                .focused($isTextFieldFocused)
                .lineLimit(1...4)
                .padding(Spacing.md)
                .background(Color.white)
                .cornerRadius(CornerRadius.lg)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

            if !inputText.isEmpty {
                Button(action: submitText) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.deepOcean)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.lg)
    }

    private func toggleRecording() {
        withAnimation(.spring(response: 0.3)) {
            isRecording.toggle()
        }

        if isRecording {
            startRecording()
        } else {
            stopRecording()
        }
    }

    private func startRecording() {
        // TODO: Implement speech recognition in Phase 2
    }

    private func stopRecording() {
        // TODO: Process recording in Phase 2
    }

    private func submitText() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let capture = CapturedInput(rawText: inputText, source: .text)
        modelContext.insert(capture)

        inputText = ""
        isTextFieldFocused = false
    }
}

struct VoiceCaptureButton: View {
    @Binding var isRecording: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(isRecording ? Color.coralAlert : Color.deepOcean, lineWidth: 3)
                    .frame(width: 100, height: 100)
                    .scaleEffect(isRecording ? 1.1 : 1.0)
                    .opacity(isRecording ? 0.6 : 1.0)
                    .animation(
                        isRecording
                            ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                            : .default,
                        value: isRecording
                    )

                // Inner circle
                Circle()
                    .fill(isRecording ? Color.coralAlert : Color.deepOcean)
                    .frame(width: 80, height: 80)

                // Icon
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: isRecording)
    }
}

#Preview {
    CaptureView()
        .modelContainer(for: [CapturedInput.self], inMemory: true)
}
