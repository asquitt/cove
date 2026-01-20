import Foundation

/// Service for detecting and redacting Personally Identifiable Information (PII)
/// PRD 6.1.4 - Privacy Sandbox: Local PII Redactor
enum PIIRedactionService {
    // MARK: - Redaction Result

    struct RedactionResult {
        let redactedText: String
        let containsSensitiveData: Bool
        let redactedItems: [RedactedItem]

        var shouldExcludeFromAI: Bool {
            redactedItems.contains { $0.type.excludeFromAI }
        }
    }

    struct RedactedItem {
        let type: PIIType
        let originalRange: Range<String.Index>
        let placeholder: String
    }

    // MARK: - PII Types

    enum PIIType: CaseIterable {
        case creditCard
        case socialSecurityNumber
        case apiKey
        case password
        case healthData
        case financialAccount
        case phoneNumber
        case email

        var pattern: String {
            switch self {
            case .creditCard:
                // Major card formats: Visa, Mastercard, Amex, Discover
                return "\\b(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|6(?:011|5[0-9]{2})[0-9]{12})\\b"

            case .socialSecurityNumber:
                // US SSN format: XXX-XX-XXXX or XXXXXXXXX
                return "\\b(?!000|666|9\\d{2})\\d{3}[-\\s]?(?!00)\\d{2}[-\\s]?(?!0000)\\d{4}\\b"

            case .apiKey:
                // Common API key patterns
                return "\\b(?:sk-[a-zA-Z0-9]{20,}|api[_-]?key[_-]?[=:]?\\s*['\"]?[a-zA-Z0-9_-]{16,}|[a-zA-Z0-9]{32,64})\\b"

            case .password:
                // Text indicating a password follows
                return "(?i)(?:password|passwd|pwd|pass)[\\s:=]+[^\\s]{4,}"

            case .healthData:
                // Medical terms that might indicate health data
                return "(?i)\\b(?:diagnosis|prescribed|medication|symptoms?|treatment|medical\\s+record|blood\\s+(?:type|pressure)|allergic|dosage)\\b"

            case .financialAccount:
                // Bank account / routing numbers
                return "\\b(?:(?:account|acct|routing)[\\s#:]*\\d{8,17}|\\d{9,17})\\b"

            case .phoneNumber:
                // US phone numbers
                return "\\b(?:\\+1[-.\\s]?)?(?:\\(?\\d{3}\\)?[-.\\s]?)?\\d{3}[-.\\s]?\\d{4}\\b"

            case .email:
                // Email addresses
                return "\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\\b"
            }
        }

        var placeholder: String {
            switch self {
            case .creditCard: return "[CREDIT_CARD]"
            case .socialSecurityNumber: return "[SSN]"
            case .apiKey: return "[API_KEY]"
            case .password: return "[PASSWORD]"
            case .healthData: return "[HEALTH_DATA]"
            case .financialAccount: return "[ACCOUNT_NUMBER]"
            case .phoneNumber: return "[PHONE]"
            case .email: return "[EMAIL]"
            }
        }

        /// Whether this type of PII should completely exclude the input from AI processing
        var excludeFromAI: Bool {
            switch self {
            case .creditCard, .socialSecurityNumber, .apiKey, .password, .financialAccount:
                return true
            case .healthData, .phoneNumber, .email:
                return false // Can be redacted and still processed
            }
        }

        var displayName: String {
            switch self {
            case .creditCard: return "Credit Card Number"
            case .socialSecurityNumber: return "Social Security Number"
            case .apiKey: return "API Key"
            case .password: return "Password"
            case .healthData: return "Health Information"
            case .financialAccount: return "Financial Account"
            case .phoneNumber: return "Phone Number"
            case .email: return "Email Address"
            }
        }
    }

    // MARK: - Detection & Redaction

    /// Scans text for PII and returns redaction result
    static func scan(_ text: String) -> RedactionResult {
        var redactedText = text
        var redactedItems: [RedactedItem] = []

        for piiType in PIIType.allCases {
            guard let regex = try? NSRegularExpression(pattern: piiType.pattern, options: []) else {
                continue
            }

            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: range)

            // Process matches in reverse order to preserve indices
            for match in matches.reversed() {
                guard let stringRange = Range(match.range, in: redactedText) else { continue }

                let item = RedactedItem(
                    type: piiType,
                    originalRange: stringRange,
                    placeholder: piiType.placeholder
                )
                redactedItems.append(item)

                redactedText.replaceSubrange(stringRange, with: piiType.placeholder)
            }
        }

        return RedactionResult(
            redactedText: redactedText,
            containsSensitiveData: !redactedItems.isEmpty,
            redactedItems: redactedItems.reversed() // Restore original order
        )
    }

    /// Quick check if text contains any sensitive data that should block AI processing
    static func containsHighSensitivityPII(_ text: String) -> Bool {
        let result = scan(text)
        return result.shouldExcludeFromAI
    }

    /// Returns list of detected PII types in text
    static func detectPIITypes(_ text: String) -> [PIIType] {
        let result = scan(text)
        return Array(Set(result.redactedItems.map { $0.type }))
    }

    /// Redact text and return only the redacted version
    static func redact(_ text: String) -> String {
        scan(text).redactedText
    }

    // MARK: - Keyword-based Detection

    /// Additional keyword detection for context clues
    static func containsSensitiveKeywords(_ text: String) -> Bool {
        let lowercased = text.lowercased()

        let sensitiveKeywords = [
            "social security",
            "credit card",
            "debit card",
            "bank account",
            "routing number",
            "pin number",
            "cvv",
            "expiry",
            "expiration date",
            "api key",
            "secret key",
            "access token",
            "bearer token",
            "private key",
            "password is",
            "my password",
            "login credentials"
        ]

        return sensitiveKeywords.contains { lowercased.contains($0) }
    }

    // MARK: - Full Analysis

    struct SensitivityReport {
        let piiDetected: [PIIType]
        let containsKeywords: Bool
        let riskLevel: RiskLevel
        let recommendation: Recommendation

        enum RiskLevel: String {
            case none = "None"
            case low = "Low"
            case medium = "Medium"
            case high = "High"
            case critical = "Critical"
        }

        enum Recommendation {
            case safe // Safe to send to AI
            case redactAndProceed // Redact PII, then send to AI
            case userConfirmation // Ask user before sending
            case block // Do not send to AI

            var message: String {
                switch self {
                case .safe:
                    return "Text is safe to process."
                case .redactAndProceed:
                    return "Some personal information will be redacted before processing."
                case .userConfirmation:
                    return "This text may contain sensitive information. Are you sure you want to process it?"
                case .block:
                    return "This text contains highly sensitive information and cannot be processed by AI for your protection."
                }
            }
        }
    }

    /// Perform full sensitivity analysis
    static func analyze(_ text: String) -> SensitivityReport {
        let result = scan(text)
        let hasKeywords = containsSensitiveKeywords(text)

        let highSensitivityTypes: Set<PIIType> = [
            .creditCard, .socialSecurityNumber, .apiKey, .password, .financialAccount
        ]

        let mediumSensitivityTypes: Set<PIIType> = [
            .healthData
        ]

        let detectedTypes = Set(result.redactedItems.map { $0.type })

        let hasHighSensitivity = !detectedTypes.isDisjoint(with: highSensitivityTypes)
        let hasMediumSensitivity = !detectedTypes.isDisjoint(with: mediumSensitivityTypes)

        let riskLevel: SensitivityReport.RiskLevel
        let recommendation: SensitivityReport.Recommendation

        if hasHighSensitivity {
            riskLevel = .critical
            recommendation = .block
        } else if hasMediumSensitivity || hasKeywords {
            riskLevel = .medium
            recommendation = .userConfirmation
        } else if result.containsSensitiveData {
            riskLevel = .low
            recommendation = .redactAndProceed
        } else {
            riskLevel = .none
            recommendation = .safe
        }

        return SensitivityReport(
            piiDetected: Array(detectedTypes),
            containsKeywords: hasKeywords,
            riskLevel: riskLevel,
            recommendation: recommendation
        )
    }
}
