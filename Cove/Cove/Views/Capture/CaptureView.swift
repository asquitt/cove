import SwiftUI
import SwiftData

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var inputText = ""
    @State private var speechService = SpeechService()
    @State private var isProcessing = false
    @State private var showStagingArea = false
    @State private var errorMessage: String?
    @State private var showError = false
    @FocusState private var isTextFieldFocused: Bool

    @Query(
        filter: #Predicate<CapturedInput> { $0.status == .processed },
        sort: \CapturedInput.createdAt,
        order: .reverse
    )
    private var pendingReviews: [CapturedInput]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection

                Spacer()

                captureArea

                Spacer()

                textInputSection
            }
            .background(Color.cloudWhite)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !pendingReviews.isEmpty {
                        Button(action: { showStagingArea = true }) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "tray.full")
                                Text("\(pendingReviews.count)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.deepOcean)
                        }
                    }
                }
            }
            .sheet(isPresented: $showStagingArea) {
                StagingAreaView()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .task {
                await requestPermissions()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Capture")
                .font(.largeTitle)
                .foregroundColor(.deepText)

            Text(speechService.statusMessage)
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
            VoiceCaptureButton(
                isRecording: speechService.isRecording,
                isProcessing: isProcessing
            ) {
                toggleRecording()
            }

            // Recording status
            if speechService.isRecording {
                recordingIndicator
            }

            // Transcribed text preview
            if !speechService.transcribedText.isEmpty && !isProcessing {
                transcriptionPreview
            }

            // Processing indicator
            if isProcessing {
                processingIndicator
            }

            // Instructions
            if !speechService.isRecording && speechService.transcribedText.isEmpty && !isProcessing {
                instructionText
            }
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

    private var transcriptionPreview: some View {
        VStack(spacing: Spacing.md) {
            Text(speechService.transcribedText)
                .font(.bodyMedium)
                .foregroundColor(.deepText)
                .multilineTextAlignment(.center)
                .padding(Spacing.md)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(CornerRadius.lg)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

            Button(action: submitVoiceCapture) {
                Label("Process with AI", systemImage: "sparkles")
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(Color.deepOcean)
                    .cornerRadius(CornerRadius.lg)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var processingIndicator: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.deepOcean)

            Text("Classifying with AI...")
                .font(.bodyMedium)
                .foregroundColor(.mutedText)
        }
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

            if !inputText.isEmpty && !isProcessing {
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

    // MARK: - Actions
    private func requestPermissions() async {
        if speechService.authorizationStatus == .notDetermined {
            _ = await speechService.requestAuthorization()
            _ = await speechService.requestMicrophonePermission()
        }
    }

    private func toggleRecording() {
        if speechService.isRecording {
            speechService.stopRecording()
        } else {
            Task {
                do {
                    try await speechService.startRecording()
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func submitVoiceCapture() {
        let text = speechService.transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        processCapture(text: text, source: .voice)
        speechService.transcribedText = ""
    }

    private func submitText() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        processCapture(text: text, source: .text)
        inputText = ""
        isTextFieldFocused = false
    }

    private func processCapture(text: String, source: CaptureSource) {
        let capture = CapturedInput(rawText: text, source: source)
        capture.status = .processing
        modelContext.insert(capture)

        isProcessing = true

        Task {
            do {
                let service = try ClaudeAIService.fromKeychain()
                let result = try await service.classifyWithRetry(text)

                await MainActor.run {
                    let encoder = JSONEncoder()
                    if let jsonData = try? encoder.encode(result),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        capture.aiResponse = jsonString
                    }

                    capture.markProcessed(bucket: result.bucket.taskBucket, response: capture.aiResponse)
                    isProcessing = false

                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    capture.status = .failed
                    capture.aiResponse = error.localizedDescription
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Voice Capture Button
struct VoiceCaptureButton: View {
    let isRecording: Bool
    let isProcessing: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(ringColor, lineWidth: 3)
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
                    .fill(fillColor)
                    .frame(width: 80, height: 80)

                // Icon
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }
        }
        .disabled(isProcessing)
        .sensoryFeedback(.impact(weight: .medium), trigger: isRecording)
    }

    private var ringColor: Color {
        if isProcessing { return .mutedText }
        return isRecording ? .coralAlert : .deepOcean
    }

    private var fillColor: Color {
        if isProcessing { return .mutedText }
        return isRecording ? .coralAlert : .deepOcean
    }
}

#Preview {
    CaptureView()
        .modelContainer(for: [CapturedInput.self, CoveTask.self], inMemory: true)
}
