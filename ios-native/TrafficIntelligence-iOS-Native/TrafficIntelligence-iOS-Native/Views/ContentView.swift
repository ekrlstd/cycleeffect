//
//  ContentView.swift
//  TrafficIntelligence-iOS-Native
//
//  Created by Ω on 1/28/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var feedService = TrafficFeedService()
    @State private var showingAuth = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Connection Status Bar
                ConnectionStatusView(
                    isConnected: feedService.isConnected,
                    isConnecting: feedService.isConnecting,
                    messagesPerSecond: feedService.messagesPerSecond,
                    onReconnect: { Task { await feedService.connectDemo() } },
                    onDisconnect: { feedService.disconnect() }
                )

                if feedService.isConnected, let state = feedService.trafficState {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Intersection Map
                            IntersectionMapView(state: state)
                                .frame(height: 350)
                                .padding(.horizontal)

                            // Stats Dashboard
                            TrafficStatsView(
                                state: state,
                                accidentCount: feedService.accidentCount,
                                events: feedService.events
                            )
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                } else if feedService.isConnecting {
                    Spacer()
                    ProgressView("Connecting...")
                        .scaleEffect(1.5)
                    Spacer()
                } else if let error = feedService.error {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        Text(error.localizedDescription)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            Task { await feedService.connectDemo() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                } else {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "car.2")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                        Text("Traffic Intelligence")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Connect to view real-time traffic data")
                            .foregroundColor(.secondary)
                        Button("Connect Demo") {
                            Task { await feedService.connectDemo() }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    Spacer()
                }
            }
            .navigationTitle("Traffic Intelligence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if feedService.isConnected {
                        Button("Reset Stats") {
                            feedService.resetStats()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
