import Foundation

enum Constants {
    // MARK: - Contract Limits
    static let maxAnchorTasks = 3
    static let maxSideQuests = 2

    // MARK: - Time Estimates
    static let defaultPessimismMultiplier = 1.5
    static let minEstimateMinutes = 5
    static let maxEstimateMinutes = 480

    // MARK: - XP Values
    static let baseTaskXP = 10
    static let meltdownSurvivalXP = 25
    static let streakBonusXP = 5
    static let xpPerLevel = 100
    static let xpPerSkillLevel = 50
    static let goblinTaskXP = 5

    // MARK: - API
    static let claudeAPIBaseURL = "https://api.anthropic.com/v1/messages"
    static let claudeAPIVersion = "2023-06-01"
    static let defaultModel = "claude-sonnet-4-20250514"
    static let maxTokens = 1024

    // MARK: - Keychain Keys
    static let claudeAPIKeyKey = "claude_api_key"

    // MARK: - Animation Durations
    static let quickAnimation = 0.2
    static let standardAnimation = 0.3
    static let slowAnimation = 0.5

    // MARK: - Goblin Mode Tasks
    static let goblinModeTasks = [
        "Drink a glass of water",
        "Take 5 deep breaths",
        "Stretch for 2 minutes",
        "Eat a snack",
        "Step outside for 1 minute",
        "Splash cold water on your face",
        "Put on your favorite song",
        "Text someone you love"
    ]

    // MARK: - Encouragement Messages
    static let completionMessages = [
        "Nice work! 🎉",
        "You did it! ✨",
        "Another one down! 💪",
        "Progress! 🌟",
        "Keep going! 🚀"
    ]

    static let meltdownMessages = [
        "It's okay to pause.",
        "Your worth isn't measured in productivity.",
        "Rest is productive too.",
        "One breath at a time.",
        "You're doing better than you think."
    ]
}
