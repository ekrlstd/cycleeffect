//
//  WebSocketMessage.swift
//  TrafficIntelligence-iOS-Native
//
//  Created by Ω on 1/28/26.
//
import Foundation

// MARK: - WebSocket Message Types
enum WebSocketMessageType: String, Codable {
    case `init`
    case update
    case replayData = "replay_data"
    case pong
}

// MARK: - WebSocket Message
struct WebSocketMessage: Codable {
    let type: WebSocketMessageType
    let events: [TrafficEvent]?
    let state: TrafficState?
    let timestamp: Int64
    let sessionId: String?
}

// MARK: - Authentication Response
struct AuthResponse: Codable {
    let token: String
    let expiresIn: String}

// MARK: - API Error
struct APIError: Codable, Error {
    let error: String
}
