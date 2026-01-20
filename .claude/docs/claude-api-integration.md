# Claude API Integration for Cove

## Overview
Cove uses the Claude API for intelligent task classification and suggestions. This document covers implementation details.

## API Configuration

### Endpoint
```
POST https://api.anthropic.com/v1/messages
```

### Headers
```
x-api-key: YOUR_API_KEY
anthropic-version: 2023-06-01
content-type: application/json
```

### Recommended Model
- **claude-sonnet-4-20250514** - Fast, cost-effective, great for classification
- Fallback: claude-3-haiku for even faster/cheaper simple tasks

## Swift Implementation

### ClaudeAPIService.swift
```swift
import Foundation

actor ClaudeAPIService {
    private let apiKey: String
    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!

    init(apiKey: String) {
        self.apiKey = apiKey
    }

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

    func sendMessage(
        prompt: String,
        system: String? = nil,
        model: String = "claude-sonnet-4-20250514",
        maxTokens: Int = 1024
    ) async throws -> String {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

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

        guard httpResponse.statusCode == 200 else {
            throw ClaudeError.apiError(statusCode: httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)

        guard let text = decoded.content.first?.text else {
            throw ClaudeError.emptyResponse
        }

        return text
    }
}

enum ClaudeError: LocalizedError {
    case invalidResponse
    case apiError(statusCode: Int)
    case emptyResponse
    case apiKeyMissing

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from Claude API"
        case .apiError(let code): return "API error: \(code)"
        case .emptyResponse: return "Empty response from Claude"
        case .apiKeyMissing: return "Please add your Claude API key in Settings"
        }
    }
}
```

## Classification Prompts

### Input Classification
```swift
let classificationSystem = """
You are an ADHD-friendly task assistant. Classify user input into one of three buckets:

DIRECTIVE: Actionable tasks that need to be done
ARCHIVE: Reference information to save for later
VENTING: Emotional expression that needs acknowledgment, not action

For DIRECTIVE items, also extract:
- title: Clear, concise task name
- estimatedMinutes: Realistic time estimate
- interestLevel: high/medium/low (how engaging is this task?)
- energyRequired: high/medium/low (mental effort needed)

Respond in JSON format only.
"""

let classificationPrompt = """
Classify this input: "\(userInput)"

Respond with JSON:
{
    "bucket": "DIRECTIVE" | "ARCHIVE" | "VENTING",
    "tasks": [
        {
            "title": "string",
            "estimatedMinutes": number,
            "interestLevel": "high" | "medium" | "low",
            "energyRequired": "high" | "medium" | "low"
        }
    ],
    "archiveNote": "string (if ARCHIVE bucket)",
    "ventingResponse": "string (if VENTING bucket - empathetic acknowledgment)"
}
"""
```

### Task Suggestion
```swift
let suggestionSystem = """
You are helping someone with ADHD manage their day. Given their current state and tasks, suggest the best task to work on next.

Consider:
- Current energy level
- Time of day
- Task interest levels
- Momentum (what they just completed)

Be encouraging but realistic. Don't overwhelm.
"""
```

### Meltdown Support
```swift
let meltdownSystem = """
The user has activated Meltdown Protocol. They're overwhelmed. Your role:

1. Be gentle and non-judgmental
2. Suggest ONE small physiological self-care action
3. Remind them that productivity isn't everything
4. Don't mention their tasks or responsibilities

Keep responses very short (1-2 sentences max).
"""
```

## API Key Storage

### KeychainHelper.swift
```swift
import Foundation
import Security

enum KeychainHelper {
    static func save(key: String, value: String) throws {
        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed
        }
    }

    static func load(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum KeychainError: Error {
    case saveFailed
    case loadFailed
}
```

## Cost Estimation

### claude-sonnet-4-20250514 Pricing
- Input: $3.00 / 1M tokens
- Output: $15.00 / 1M tokens

### Estimated Usage per User/Day
- ~10 classification requests: ~500 input tokens, ~200 output tokens each
- ~5 suggestion requests: ~300 input, ~100 output each
- Total: ~6,500 input + 2,500 output tokens

### Daily Cost per User
- Input: 6,500 × $0.000003 = $0.02
- Output: 2,500 × $0.000015 = $0.04
- **Total: ~$0.06/day/active user**

## Error Handling

```swift
func classifyWithRetry(_ input: String, retries: Int = 2) async throws -> Classification {
    var lastError: Error?

    for attempt in 0...retries {
        do {
            return try await classify(input)
        } catch let error as ClaudeError {
            lastError = error
            if case .apiError(let code) = error, code == 429 {
                // Rate limited - wait and retry
                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
                continue
            }
            throw error
        }
    }

    throw lastError ?? ClaudeError.invalidResponse
}
```

## Testing

### Mock Service for Development
```swift
#if DEBUG
class MockClaudeService: ClaudeServiceProtocol {
    func classify(_ input: String) async throws -> Classification {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)

        // Return mock classification
        return Classification(
            bucket: .directive,
            tasks: [
                TaskSuggestion(
                    title: "Mock task from: \(input.prefix(20))...",
                    estimatedMinutes: 15,
                    interestLevel: .medium,
                    energyRequired: .low
                )
            ]
        )
    }
}
#endif
```

## Security Checklist

- [ ] API key stored in Keychain, not UserDefaults
- [ ] API key never logged or displayed in UI
- [ ] API key not included in crash reports
- [ ] HTTPS only (enforced by API)
- [ ] Request timeout configured (30s recommended)
