//
//  IntersectionMapView.swift
//  TrafficIntelligence-iOS-Native
//
//  Created by Ω on 1/28/26.
//

import SwiftUI

struct IntersectionMapView: View {
    let state: TrafficState

    private let roadColor = Color(white: 0.3)
    private let laneMarkingColor = Color.yellow.opacity(0.8)
    private let sidewalkColor = Color(white: 0.6)

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                // Background
                Color(white: 0.15)

                // Draw intersection
                Canvas { context, canvasSize in
                    drawIntersection(context: context, size: CGSize(width: size, height: size))
                }
                .frame(width: size, height: size)

                // Traffic objects
                ForEach(state.objects) { object in
                    TrafficObjectView(object: object)
                        .position(
                            x: object.x * size,
                            y: object.y * size
                        )
                }

                // Signal indicators
                SignalIndicatorView(signalState: state.signalState)
                    .frame(width: size, height: size)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private func drawIntersection(context: GraphicsContext, size: CGSize) {
        let roadWidth = size.width * 0.25
        let centerX = size.width / 2
        let centerY = size.height / 2

        // Vertical road
        let verticalRoad = Path { path in
            path.addRect(CGRect(
                x: centerX - roadWidth / 2,
                y: 0,
                width: roadWidth,
                height: size.height
            ))
        }
        context.fill(verticalRoad, with: .color(roadColor))

        // Horizontal road
        let horizontalRoad = Path { path in
            path.addRect(CGRect(
                x: 0,
                y: centerY - roadWidth / 2,
                width: size.width,
                height: roadWidth
            ))
        }
        context.fill(horizontalRoad, with: .color(roadColor))

        // Center lane markings (dashed)
        let dashLength: CGFloat = 15
        let gapLength: CGFloat = 10

        // Vertical center line
        var y: CGFloat = 0
        while y < size.height {
            if y < centerY - roadWidth / 2 || y > centerY + roadWidth / 2 {
                let dash = Path { path in
                    path.addRect(CGRect(x: centerX - 1, y: y, width: 2, height: dashLength))
                }
                context.fill(dash, with: .color(laneMarkingColor))
            }
            y += dashLength + gapLength
        }

        // Horizontal center line
        var x: CGFloat = 0
        while x < size.width {
            if x < centerX - roadWidth / 2 || x > centerX + roadWidth / 2 {
                let dash = Path { path in
                    path.addRect(CGRect(x: x, y: centerY - 1, width: dashLength, height: 2))
                }
                context.fill(dash, with: .color(laneMarkingColor))
            }
            x += dashLength + gapLength
        }

        // Crosswalks
        drawCrosswalk(context: context,
                     x: centerX - roadWidth / 2 - 15,
                     y: centerY - roadWidth / 2 + 5,
                     width: 10, height: roadWidth - 10,
                     horizontal: false)
        drawCrosswalk(context: context,
                     x: centerX + roadWidth / 2 + 5,
                     y: centerY - roadWidth / 2 + 5,
                     width: 10, height: roadWidth - 10,
                     horizontal: false)
        drawCrosswalk(context: context,
                     x: centerX - roadWidth / 2 + 5,
                     y: centerY - roadWidth / 2 - 15,
                     width: roadWidth - 10, height: 10,
                     horizontal: true)
        drawCrosswalk(context: context,
                     x: centerX - roadWidth / 2 + 5,
                     y: centerY + roadWidth / 2 + 5,
                     width: roadWidth - 10, height: 10,
                     horizontal: true)
    }

    private func drawCrosswalk(context: GraphicsContext, x: CGFloat, y: CGFloat,
                               width: CGFloat, height: CGFloat, horizontal: Bool) {
        let stripeCount = 5
        let stripeWidth: CGFloat = horizontal ? height / CGFloat(stripeCount * 2) : width / CGFloat(stripeCount * 2)

        for i in 0..<stripeCount {
            let offset = CGFloat(i * 2) * stripeWidth
            let stripe = Path { path in
                if horizontal {
                    path.addRect(CGRect(x: x, y: y + offset, width: width, height: stripeWidth))
                } else {
                    path.addRect(CGRect(x: x + offset, y: y, width: stripeWidth, height: height))
                }
            }
            context.fill(stripe, with: .color(.white.opacity(0.8)))
        }
    }
}

// MARK: - Traffic Object View
struct TrafficObjectView: View {
    let object: TrafficObject

    var body: some View {
        ZStack {
            // Direction indicator
            if object.type.isVehicle {
                Triangle()
                    .fill(Color(hex: object.type.color).opacity(0.5))
                    .frame(width: 20, height: 12)
                    .rotationEffect(.degrees(object.heading + 90))
                    .offset(y: -8)
            }

            // Object marker
            Circle()
                .fill(Color(hex: object.type.color))
                .frame(width: object.type.isVehicle ? 16 : 10,
                       height: object.type.isVehicle ? 16 : 10)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )

            // Confidence ring
            Circle()
                .stroke(
                    Color(hex: object.type.color).opacity(object.confidence),
                    lineWidth: 2
                )
                .frame(width: 22, height: 22)
        }
        .rotationEffect(.degrees(object.heading))
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

// MARK: - Signal Indicator
struct SignalIndicatorView: View {
    let signalState: SignalState

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let indicatorSize: CGFloat = 12

            ZStack {
                // North
                Circle()
                    .fill(signalState == .nsGreen ? Color.green : Color.red)
                    .frame(width: indicatorSize, height: indicatorSize)
                    .position(x: size.width / 2, y: size.height * 0.15)

                // South
                Circle()
                    .fill(signalState == .nsGreen ? Color.green : Color.red)
                    .frame(width: indicatorSize, height: indicatorSize)
                    .position(x: size.width / 2, y: size.height * 0.85)

                // East
                Circle()
                    .fill(signalState == .ewGreen ? Color.green : Color.red)
                    .frame(width: indicatorSize, height: indicatorSize)
                    .position(x: size.width * 0.85, y: size.height / 2)

                // West
                Circle()
                    .fill(signalState == .ewGreen ? Color.green : Color.red)
                    .frame(width: indicatorSize, height: indicatorSize)
                    .position(x: size.width * 0.15, y: size.height / 2)
            }
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
