import Foundation

actor ClaudeAIService {
    // MARK: - Properties
    private let apiKey: String
    private let baseURL = URL(string: Constants.claudeAPIBaseURL)!

    // MARK: - Initialization
    init(apiKey: String) {
        self.apiKey = apiKey
    }

    static func fromKeychain() throws -> ClaudeAIService {
        guard let apiKey = KeychainHelper.load(key: Constants.claudeAPIKeyKey),
              !apiKey.isEmpty else {
            throw ClaudeError.apiKeyMissing
        }
        return ClaudeAIService(apiKey: apiKey)
    }

    // MARK: - API Types
    struct Message: Codable {
        let role: String
        let content: String
    }

    struct Request: Codable {
        let model: String
        let max_tokens: Int
        let messages: [Message]
        let system: String?
    }

    struct Response: Codable {
        let content: [ContentBlock]

        struct ContentBlock: Codable {
            let type: String
            let text: String?
        }
    }

    // MARK: - Classification
    func classifyInput(_ text: String) async throws -> ClassificationResult {
        let systemPrompt = """
        You are an ADHD-friendly task assistant. Classify user input into one of three buckets:

        DIRECTIVE: Actionable tasks that need to be done
        ARCHIVE: Reference information to save for later
        VENTING: Emotional expression that needs acknowledgment, not action

        For DIRECTIVE items, also extract:
        - title: Clear, concise task name (max 50 chars)
        - estimatedMinutes: Realistic time estimate (5-480)
        - interestLevel: high/medium/low (how engaging is this task?)
        - energyRequired: high/medium/low (mental effort needed)

        For VENTING items, provide a brief empathetic acknowledgment.

        Respond ONLY with valid JSON matching this exact structure:
        {
            "bucket": "DIRECTIVE" | "ARCHIVE" | "VENTING",
            "tasks": [{"title": "string", "estimatedMinutes": number, "interestLevel": "high"|"medium"|"low", "energyRequired": "high"|"medium"|"low"}],
            "archiveNote": "string or null",
            "ventingResponse": "string or null"
        }
        """

        let userPrompt = "Classify this input: \"\(text)\""

        let responseText = try await sendMessage(
            prompt: userPrompt,
            system: systemPrompt,
            maxTokens: 512
        )

        return try parseClassification(responseText)
    }

    // MARK: - Send Message
    private func sendMessage(
        prompt: String,
        system: String? = nil,
        model: String = Constants.defaultModel,
        maxTokens: Int = Constants.maxTokens
    ) async throws -> String {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Constants.claudeAPIVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.timeoutInterval = 30

        let body = Request(
            model: model,
            max_tokens: maxTokens,
            messages: [Message(role: "user", content: prompt)],
            system: system
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw ClaudeError.invalidAPIKey
        case 429:
            throw ClaudeError.rateLimited
        default:
            throw ClaudeError.apiError(statusCode: httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)

        guard let text = decoded.content.first?.text else {
            throw ClaudeError.emptyResponse
        }

        return text
    }

    // MARK: - Parse Classification
    private func parseClassification(_ json: String) throws -> ClassificationResult {
        // Extract JSON from potential markdown code blocks
        let cleanJSON = json
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleanJSON.data(using: .utf8) else {
            throw ClaudeError.parsingFailed
        }

        let decoder = JSONDecoder()
        return try decoder.decode(ClassificationResult.self, from: data)
    }

    // MARK: - Retry Logic
    func classifyWithRetry(_ text: String, maxRetries: Int = 2) async throws -> ClassificationResult {
        var lastError: Error?

        for attempt in 0...maxRetries {
            do {
                return try await classifyInput(text)
            } catch let error as ClaudeError {
                lastError = error
                if case .rateLimited = error {
                    let delay = UInt64(pow(2.0, Double(attempt))) * 1_000_000_000
                    try await Task.sleep(nanoseconds: delay)
                    continue
                }
                throw error
            } catch {
                throw error
            }
        }

        throw lastError ?? ClaudeError.invalidResponse
    }
}

// MARK: - Classification Result
struct ClassificationResult: Codable {
    let bucket: ClassificationBucket
    let tasks: [TaskSuggestion]?
    let archiveNote: String?
    let ventingResponse: String?

    enum CodingKeys: String, CodingKey {
        case bucket, tasks, archiveNote, ventingResponse
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bucket = try container.decode(ClassificationBucket.self, forKey: .bucket)
        tasks = try container.decodeIfPresent([TaskSuggestion].self, forKey: .tasks)
        archiveNote = try container.decodeIfPresent(String.self, forKey: .archiveNote)
        ventingResponse = try container.decodeIfPresent(String.self, forKey: .ventingResponse)
    }
}

enum ClassificationBucket: String, Codable {
    case directive = "DIRECTIVE"
    case archive = "ARCHIVE"
    case venting = "VENTING"

    var taskBucket: TaskBucket {
        switch self {
        case .directive: return .directive
        case .archive: return .archive
        case .venting: return .venting
        }
    }
}

struct TaskSuggestion: Codable {
    let title: String
    let estimatedMinutes: Int
    let interestLevel: String
    let energyRequired: String

    var interest: InterestLevel {
        InterestLevel(rawValue: interestLevel.lowercased()) ?? .medium
    }

    var energy: EnergyLevel {
        EnergyLevel(rawValue: energyRequired.lowercased()) ?? .medium
    }
}

// MARK: - Errors
enum ClaudeError: LocalizedError {
    case apiKeyMissing
    case invalidAPIKey
    case invalidResponse
    case apiError(statusCode: Int)
    case emptyResponse
    case rateLimited
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "Please add your Claude API key in Settings"
        case .invalidAPIKey:
            return "Invalid API key. Please check your settings."
        case .invalidResponse:
            return "Invalid response from Claude API"
        case .apiError(let code):
            return "API error (status: \(code))"
        case .emptyResponse:
            return "Empty response from Claude"
        case .rateLimited:
            return "Rate limited. Please try again later."
        case .parsingFailed:
            return "Failed to parse AI response"
        }
    }
}
