//
//  TrafficStatsView.swift
//  TrafficIntelligence-iOS-Native
//
//  Created by Ω on 1/28/26.
//
import SwiftUI

struct TrafficStatsView: View {
    let state: TrafficState
    let accidentCount: Int
    let events: [TrafficEvent]

    var body: some View {
        VStack(spacing: 16) {
            // Main stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Vehicles",
                    value: "\(state.vehicleCount)",
                    icon: "car.fill",
                    color: .blue
                )
                StatCard(
                    title: "Pedestrians",
                    value: "\(state.pedestrianCount)",
                    icon: "figure.walk",
                    color: .green
                )
                StatCard(
                    title: "Accidents",
                    value: "\(accidentCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: accidentCount > 0 ? .red : .gray
                )
            }

            // Congestion level
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Congestion Level")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(state.congestionLevel * 100))%")
                        .font(.headline)
                        .foregroundColor(congestionColor)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(congestionColor)
                            .frame(width: geometry.size.width * state.congestionLevel)
                    }
                }
                .frame(height: 8)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            // Signal state
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(state.signalState == .nsGreen ? .green : .red)
                Text(state.signalState.description)
                    .font(.subheadline)
                Spacer()
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            // Objects by type
            VStack(alignment: .leading, spacing: 12) {
                Text("Objects by Type")
                    .font(.headline)

                ForEach(Array(state.objectsByType.sorted { $0.value > $1.value }), id: \.key) { type, count in
                    HStack {
                        Text(type.emoji)
                        Text(type.rawValue.capitalized)
                            .font(.subheadline)
                        Spacer()
                        Text("\(count)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            // Recent events
            if !events.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Events")
                        .font(.headline)

                    ForEach(events.suffix(5).reversed()) { event in
                        HStack {
                            Circle()
                                .fill(eventColor(for: event.type))
                                .frame(width: 8, height: 8)
                            Text(event.type.rawValue.capitalized)
                                .font(.caption)
                            if let objectType = event.objectType {
                                Text(objectType.emoji)
                            }
                            Spacer()
                            Text(event.date, style: .time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }

    private var congestionColor: Color {
        switch state.congestionLevel {
        case 0..<0.3: return .green
        case 0.3..<0.6: return .yellow
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }

    private func eventColor(for type: TrafficEventType) -> Color {
        switch type {
        case .detection: return .blue
        case .accident: return .red
        case .congestion: return .orange
        case .signalChange: return .green
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
