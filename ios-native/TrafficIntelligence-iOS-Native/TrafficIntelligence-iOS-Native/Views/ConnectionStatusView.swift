//
//  ConnectionStatusView.swift
//  TrafficIntelligence-iOS-Native
//
//  Created by Ω on 1/28/26.
//

import SwiftUI

struct ConnectionStatusView: View {
    let isConnected: Bool
    let isConnecting: Bool
    let messagesPerSecond: Int
    let onReconnect: () -> Void
    let onDisconnect: () -> Void

    var body: some View {
        HStack {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            Text(statusText)
                .font(.subheadline)

            if isConnected {
                Text("•")
                    .foregroundColor(.secondary)
                Text("\(messagesPerSecond) msg/s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isConnecting {
                ProgressView()
                    .scaleEffect(0.8)
            } else if isConnected {
                Button("Disconnect") {
                    onDisconnect()
                }
                .font(.caption)
                .foregroundColor(.red)
            } else {
                Button("Reconnect") {
                    onReconnect()
                }
                .font(.caption)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }

    private var statusColor: Color {
        if isConnecting { return .yellow }
        if isConnected { return .green }
        return .red
    }

    private var statusText: String {
        if isConnecting { return "Connecting..." }
        if isConnected { return "Connected" }
        return "Disconnected"
    }
}
