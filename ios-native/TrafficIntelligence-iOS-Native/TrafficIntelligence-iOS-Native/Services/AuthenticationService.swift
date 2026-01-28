//
//  AuthenticationService.swift
//  TrafficIntelligence-iOS-Native
//
//  Created by Ω on 1/28/26.
//
import Foundation

actor AuthenticationService {
    private let baseURL = "https://gxziopzriagwbiefmrwi.supabase.co/functions/v1/traffic-feed"
    private var cachedToken: String?
    private var tokenExpiry: Date?

    enum AuthError: Error, LocalizedError {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case authenticationFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .networkError(let error): return "Network error: \(error.localizedDescription)"
            case .invalidResponse: return "Invalid response from server"
            case .authenticationFailed(let message): return "Authentication failed: \(message)"
            }
        }
    }

    /// Authenticate with API key and get JWT token
    func authenticate(apiKey: String) async throws -> String {
        // Check cached token
        if let token = cachedToken, let expiry = tokenExpiry, expiry > Date() {
            return token
        }

        guard let url = URL(string: "\(baseURL)/token") else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["apiKey": apiKey])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                throw AuthError.authenticationFailed(apiError.error)
            }
            throw AuthError.authenticationFailed("HTTP \(httpResponse.statusCode)")
        }

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        cachedToken = authResponse.token

        return authResponse.token
    }

    /// Get demo token
    func getDemoToken() async throws -> String {
        try await authenticate(apiKey: "demo-traffic-feed-key")
    }

    /// Clear cached token
    func clearToken() {
        cachedToken = nil
        tokenExpiry = nil
    }
}
