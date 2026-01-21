import Foundation
import AuthenticationServices

/// Service for Google Calendar integration
/// Allows users to sync tasks with Google Calendar events
@Observable
final class GoogleCalendarService: NSObject {
    // MARK: - Configuration

    /// Google OAuth 2.0 configuration
    /// Note: In production, these would be stored securely and configured via GoogleService-Info.plist
    private let clientId = "" // Set in app configuration
    private let redirectUri = "com.demario.cove:/oauth2callback"
    private let scopes = ["https://www.googleapis.com/auth/calendar.readonly", "https://www.googleapis.com/auth/calendar.events"]

    // MARK: - State

    private(set) var isAuthenticated = false
    private(set) var isLoading = false
    private(set) var events: [GoogleCalendarEvent] = []
    private(set) var error: GoogleCalendarError?

    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiration: Date?

    private weak var presentationAnchor: ASPresentationAnchor?

    // MARK: - Authentication

    /// Check if user has connected Google Calendar
    var isConnected: Bool {
        accessToken != nil && (tokenExpiration ?? .distantPast) > Date()
    }

    /// Initiate Google OAuth flow
    func authenticate(from anchor: ASPresentationAnchor) async throws {
        guard !clientId.isEmpty else {
            throw GoogleCalendarError.notConfigured
        }

        presentationAnchor = anchor
        isLoading = true
        error = nil

        defer { isLoading = false }

        // Build OAuth URL
        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]

        guard let authURL = components.url else {
            throw GoogleCalendarError.invalidURL
        }

        // Create and start auth session
        let callbackURLScheme = "com.demario.cove"

        let code = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: callbackURLScheme
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: GoogleCalendarError.authFailed(error.localizedDescription))
                    return
                }

                guard let callbackURL = callbackURL,
                      let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                      let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: GoogleCalendarError.noAuthCode)
                    return
                }

                continuation.resume(returning: code)
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false

            if !session.start() {
                continuation.resume(throwing: GoogleCalendarError.sessionFailed)
            }
        }

        // Exchange code for tokens
        try await exchangeCodeForTokens(code)
        isAuthenticated = true
    }

    /// Exchange authorization code for access and refresh tokens
    private func exchangeCodeForTokens(_ code: String) async throws {
        guard !clientId.isEmpty else {
            throw GoogleCalendarError.notConfigured
        }

        let url = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "code": code,
            "client_id": clientId,
            "redirect_uri": redirectUri,
            "grant_type": "authorization_code"
        ]
        request.httpBody = body.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GoogleCalendarError.tokenExchangeFailed
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        accessToken = tokenResponse.accessToken
        refreshToken = tokenResponse.refreshToken
        tokenExpiration = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))

        // Store tokens securely
        saveTokens()
    }

    /// Refresh access token using refresh token
    private func refreshAccessToken() async throws {
        guard let refreshToken = refreshToken, !clientId.isEmpty else {
            throw GoogleCalendarError.notConfigured
        }

        let url = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "refresh_token": refreshToken,
            "client_id": clientId,
            "grant_type": "refresh_token"
        ]
        request.httpBody = body.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GoogleCalendarError.tokenRefreshFailed
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        accessToken = tokenResponse.accessToken
        tokenExpiration = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))

        saveTokens()
    }

    /// Disconnect Google Calendar
    func disconnect() {
        accessToken = nil
        refreshToken = nil
        tokenExpiration = nil
        isAuthenticated = false
        events = []
        clearTokens()
    }

    // MARK: - Calendar Operations

    /// Fetch events for a date range
    func fetchEvents(from startDate: Date, to endDate: Date) async throws -> [GoogleCalendarEvent] {
        guard let token = accessToken else {
            throw GoogleCalendarError.notAuthenticated
        }

        // Check if token needs refresh
        if let expiration = tokenExpiration, expiration < Date() {
            try await refreshAccessToken()
        }

        let formatter = ISO8601DateFormatter()
        let timeMin = formatter.string(from: startDate)
        let timeMax = formatter.string(from: endDate)

        var components = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")!
        components.queryItems = [
            URLQueryItem(name: "timeMin", value: timeMin),
            URLQueryItem(name: "timeMax", value: timeMax),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime")
        ]

        guard let url = components.url else {
            throw GoogleCalendarError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken ?? "")", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GoogleCalendarError.fetchFailed
        }

        let eventsResponse = try JSONDecoder().decode(EventsResponse.self, from: data)
        events = eventsResponse.items.map { GoogleCalendarEvent(from: $0) }
        return events
    }

    /// Fetch today's events
    func fetchTodayEvents() async throws -> [GoogleCalendarEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return try await fetchEvents(from: startOfDay, to: endOfDay)
    }

    /// Create a calendar event from a task
    func createEventFromTask(_ task: CoveTask) async throws -> String {
        guard let token = accessToken else {
            throw GoogleCalendarError.notAuthenticated
        }

        // Check if token needs refresh
        if let expiration = tokenExpiration, expiration < Date() {
            try await refreshAccessToken()
        }

        let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let startTime = task.scheduledFor ?? Date()
        let endTime = startTime.addingTimeInterval(TimeInterval((task.estimatedMinutes ?? 30) * 60))

        let eventData: [String: Any] = [
            "summary": task.title,
            "description": task.taskDescription ?? "",
            "start": ["dateTime": ISO8601DateFormatter().string(from: startTime)],
            "end": ["dateTime": ISO8601DateFormatter().string(from: endTime)]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: eventData)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GoogleCalendarError.createFailed
        }

        let createdEvent = try JSONDecoder().decode(CalendarEventItem.self, from: data)
        return createdEvent.id
    }

    // MARK: - Token Storage

    private func saveTokens() {
        if let accessToken = accessToken {
            try? KeychainHelper.save(key: "google_access_token", value: accessToken)
        }
        if let refreshToken = refreshToken {
            try? KeychainHelper.save(key: "google_refresh_token", value: refreshToken)
        }
        if let expiration = tokenExpiration {
            UserDefaults.standard.set(expiration, forKey: "google_token_expiration")
        }
    }

    private func loadTokens() {
        accessToken = KeychainHelper.load(key: "google_access_token")
        refreshToken = KeychainHelper.load(key: "google_refresh_token")
        tokenExpiration = UserDefaults.standard.object(forKey: "google_token_expiration") as? Date
        isAuthenticated = isConnected
    }

    private func clearTokens() {
        KeychainHelper.delete(key: "google_access_token")
        KeychainHelper.delete(key: "google_refresh_token")
        UserDefaults.standard.removeObject(forKey: "google_token_expiration")
    }

    // MARK: - Initialization

    override init() {
        super.init()
        loadTokens()
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension GoogleCalendarService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        presentationAnchor ?? ASPresentationAnchor()
    }
}

// MARK: - Supporting Types

enum GoogleCalendarError: LocalizedError {
    case notConfigured
    case notAuthenticated
    case invalidURL
    case authFailed(String)
    case noAuthCode
    case sessionFailed
    case tokenExchangeFailed
    case tokenRefreshFailed
    case fetchFailed
    case createFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Google Calendar is not configured. Please add your API credentials."
        case .notAuthenticated:
            return "Please connect your Google Calendar first."
        case .invalidURL:
            return "Invalid URL configuration."
        case .authFailed(let message):
            return "Authentication failed: \(message)"
        case .noAuthCode:
            return "No authorization code received."
        case .sessionFailed:
            return "Failed to start authentication session."
        case .tokenExchangeFailed:
            return "Failed to exchange authorization code."
        case .tokenRefreshFailed:
            return "Failed to refresh access token. Please reconnect."
        case .fetchFailed:
            return "Failed to fetch calendar events."
        case .createFailed:
            return "Failed to create calendar event."
        }
    }
}

struct GoogleCalendarEvent: Identifiable {
    let id: String
    let title: String
    let description: String?
    let startTime: Date
    let endTime: Date
    let isAllDay: Bool

    fileprivate init(from item: CalendarEventItem) {
        self.id = item.id
        self.title = item.summary ?? "Untitled"
        self.description = item.description

        let formatter = ISO8601DateFormatter()
        if let dateTime = item.start.dateTime {
            self.startTime = formatter.date(from: dateTime) ?? Date()
            self.isAllDay = false
        } else if let date = item.start.date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            self.startTime = dateFormatter.date(from: date) ?? Date()
            self.isAllDay = true
        } else {
            self.startTime = Date()
            self.isAllDay = false
        }

        if let dateTime = item.end.dateTime {
            self.endTime = formatter.date(from: dateTime) ?? Date()
        } else if let date = item.end.date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            self.endTime = dateFormatter.date(from: date) ?? Date()
        } else {
            self.endTime = startTime.addingTimeInterval(3600)
        }
    }

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var durationMinutes: Int {
        Int(duration / 60)
    }
}

// MARK: - API Response Models

private struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

private struct EventsResponse: Codable {
    let items: [CalendarEventItem]
}

private struct CalendarEventItem: Codable {
    let id: String
    let summary: String?
    let description: String?
    let start: EventDateTime
    let end: EventDateTime
}

private struct EventDateTime: Codable {
    let dateTime: String?
    let date: String?
}
