//
//  TrafficModels.swift
//  TrafficIntelligence-iOS-Native
//
//  Created by Ω on 1/28/26.
//
import Foundation

// MARK: - Traffic Object Types
enum TrafficObjectType: String, Codable, CaseIterable {
    case car
    case truck
    case taxi
    case police
    case ambulance
    case bus
    case motorcycle
    case bicycle
    case pedestrian

    var emoji: String {
        switch self {
        case .car: return "🚗"
        case .truck: return "🚛"
        case .taxi: return "🚕"
        case .police: return "🚔"
        case .ambulance: return "🚑"
        case .bus: return "🚌"
        case .motorcycle: return "🏍️"
        case .bicycle: return "🚲"
        case .pedestrian: return "🚶"
        }
    }

    var color: String {
        switch self {
        case .car: return "#3B82F6"      // Blue
        case .truck: return "#8B5CF6"    // Purple
        case .taxi: return "#F59E0B"     // Amber
        case .police: return "#1D4ED8"   // Dark Blue
        case .ambulance: return "#DC2626" // Red
        case .bus: return "#059669"      // Green
        case .motorcycle: return "#7C3AED" // Violet
        case .bicycle: return "#10B981"  // Emerald
        case .pedestrian: return "#6B7280" // Gray
        }
    }

    var isVehicle: Bool {
        self != .pedestrian
    }
}

// MARK: - Traffic Object
struct TrafficObject: Identifiable, Codable, Equatable {
    let id: String
    let type: TrafficObjectType
    let x: Double
    let y: Double
    let vx: Double
    let vy: Double
    let heading: Double
    let lane: String
    let confidence: Double

    /// Speed in units per second (derived from velocity vectors)
    var speed: Double {
        sqrt(vx * vx + vy * vy)
    }

    /// Speed in approximate km/h (assuming 100m intersection)
    var speedKmh: Double {
        speed * 100 * 3.6
    }

    /// Convert normalized coordinates to view coordinates
    func position(in size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }
}

// MARK: - Traffic Event Types
enum TrafficEventType: String, Codable {
    case detection
    case accident
    case congestion
    case signalChange = "signal_change"
}

// MARK: - Traffic Event
struct TrafficEvent: Identifiable, Codable {
    let id = UUID()
    let type: TrafficEventType
    let objectType: TrafficObjectType?
    let objectId: String
    let x: Double
    let y: Double
    let vx: Double?
    let vy: Double?
    let heading: Double?
    let lane: String?
    let confidence: Double?
    let metadata: [String: AnyCodable]?
    let timestamp: Int64

    var date: Date {
        Date(timeIntervalSince1970: Double(timestamp) / 1000)
    }

    enum CodingKeys: String, CodingKey {
        case type, objectType, objectId, x, y, vx, vy, heading, lane, confidence, metadata, timestamp
    }
}

// MARK: - Signal State
enum SignalState: String, Codable {
    case nsGreen = "NS_GREEN"
    case ewGreen = "EW_GREEN"

    var description: String {
        switch self {
        case .nsGreen: return "North-South Green"
        case .ewGreen: return "East-West Green"
        }
    }
}

// MARK: - Traffic State
struct TrafficState: Codable {
    let objects: [TrafficObject]
    let signalState: SignalState
    let congestionLevel: Double

    var vehicleCount: Int {
        objects.filter { $0.type.isVehicle }.count
    }

    var pedestrianCount: Int {
        objects.filter { !$0.type.isVehicle }.count
    }

    var objectsByType: [TrafficObjectType: Int] {
        Dictionary(grouping: objects, by: { $0.type })
            .mapValues { $0.count }
    }
}

// MARK: - Helper for encoding arbitrary JSON
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else {
            try container.encodeNil()
        }
    }
}
