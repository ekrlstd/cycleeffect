//
//  TrafficFeedService.swift
//  TrafficIntelligence-iOS-Native
//
//  Created by Ω on 1/28/26.
//
import Foundation
import Combine

@MainActor
class TrafficFeedService: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isConnected = false
    @Published private(set) var isConnecting = false
    @Published private(set) var error: Error?
    @Published private(set) var trafficState: TrafficState?
    @Published private(set) var events: [TrafficEvent] = []
    @Published private(set) var messagesPerSecond: Int = 0
    @Published private(set) var accidentCount: Int = 0

    // MARK: - Private Properties
    private let baseURL = "wss://gxziopzriagwbiefmrwi.supabase.co/functions/v1/traffic-feed"
    private let authService = AuthenticationService()
    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    private var messageCount = 0
    private var lastSecondTimestamp = Date()
    private var pingTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5

    // MARK: - Initialization
    override init() {
        super.init()
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    }

    // MARK: - Public Methods

    /// Connect using demo API key
    func connectDemo() async {
        do {
            let token = try await authService.getDemoToken()
            await connect(token: token)
        } catch {
            self.error = error
            isConnecting = false
        }
    }

    /// Connect using custom API key
    func connect(apiKey: String) async {
        isConnecting = true
        error = nil

        do {
            let token = try await authService.authenticate(apiKey: apiKey)
            await connect(token: token)
        } catch {
            self.error = error
            isConnecting = false
        }
    }

    /// Connect with existing token
    func connect(token: String) async {
        isConnecting = true
        error = nil

        guard let url = URL(string: "\(baseURL)/stream?token=\(token)") else {
            error = NSError(domain: "TrafficFeed", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            isConnecting = false
            return
        }

        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = urlSession.webSocketTask(with: url)
        webSocket?.resume()

        startReceiving()
        startPingTimer()
    }

    /// Disconnect from feed
    func disconnect() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        pingTimer?.invalidate()
        pingTimer = nil
        isConnected = false
        isConnecting = false
        reconnectAttempts = 0
    }

    /// Reset statistics
    func resetStats() {
        accidentCount = 0
        events.removeAll()
    }

    /// Request replay of historical session
    func requestReplay(sessionId: String) {
        guard isConnected else { return }

        let message = ["type": "replay", "sessionId": sessionId]
        if let data = try? JSONEncoder().encode(message),
           let string = String(data: data, encoding: .utf8) {
            webSocket?.send(.string(string)) { _ in }
        }
    }

    // MARK: - Private Methods

    private func startReceiving() {
        webSocket?.receive { [weak self] result in
            Task { @MainActor in
                self?.handleReceive(result)
            }
        }
    }

    private func handleReceive(_ result: Result<URLSessionWebSocketTask.Message, Error>) {
        switch result {
        case .success(let message):
            reconnectAttempts = 0

            switch message {
            case .string(let text):
                handleMessage(text)
            case .data(let data):
                if let text = String(data: data, encoding: .utf8) {
                    handleMessage(text)
                }
            @unknown default:
                break
            }

            // Continue receiving
            startReceiving()

        case .failure(let error):
            self.error = error
            isConnected = false
            isConnecting = false
            attemptReconnect()
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }

        do {
            let message = try JSONDecoder().decode(WebSocketMessage.self, from: data)

            // Update message rate
            updateMessageRate()

            // Update state
            if let state = message.state {
                trafficState = state
            }

            // Process events
            if let newEvents = message.events {
                events = (events + newEvents).suffix(100).map { $0 }

                // Count accidents
                accidentCount += newEvents.filter { $0.type == .accident }.count
            }

            // Mark as connected on first message
            if !isConnected {
                isConnected = true
                isConnecting = false
            }

        } catch {
            print("Failed to decode message: \(error)")
        }
    }

    private func updateMessageRate() {
        messageCount += 1
        let now = Date()

        if now.timeIntervalSince(lastSecondTimestamp) >= 1.0 {
            messagesPerSecond = messageCount
            messageCount = 0
            lastSecondTimestamp = now
        }
    }

    private func startPingTimer() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }

    private func sendPing() {
        webSocket?.sendPing { [weak self] error in
            if let error = error {
                print("Ping failed: \(error)")
                Task { @MainActor in
                    self?.attemptReconnect()
                }
            }
        }
    }

    private func attemptReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            error = NSError(domain: "TrafficFeed", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Max reconnection attempts reached"])
            return
        }

        reconnectAttempts += 1
        let delay = Double(reconnectAttempts) * 2.0

        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            await connectDemo()
        }
    }
}

// MARK: - URLSessionWebSocketDelegate
extension TrafficFeedService: URLSessionWebSocketDelegate {
    nonisolated func urlSession(_ session: URLSession,
                                webSocketTask: URLSessionWebSocketTask,
                                didOpenWithProtocol protocol: String?) {
        Task { @MainActor in
            print("WebSocket connected")
        }
    }

    nonisolated func urlSession(_ session: URLSession,
                                webSocketTask: URLSessionWebSocketTask,
                                didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                                reason: Data?) {
        Task { @MainActor in
            isConnected = false
            print("WebSocket closed: \(closeCode)")
        }
    }
}
