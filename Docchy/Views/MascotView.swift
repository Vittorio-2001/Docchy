//
//  MascotView.swift
//  Docchy
//
//  Created by Vittorio Monfrecola on 12/07/2026.
//

import SwiftUI

enum MascotExpression {
    case neutral
    case pensierosa
    case felice
    case confusa
    case orologio
    case legge
    case agente
}

struct MascotView: View {
    let expression: MascotExpression
    @State private var isBlinking = false
    @State private var isWaving = false

    var body: some View {
        Canvas { context, size in
            let scaleX = size.width / 340
            let scaleY = size.height / 280

            let shapes = MascotShapes.bodyAndFold
                + MascotShapes.face(for: expression, blinking: isBlinking, waving: isWaving)

            for rect in shapes {
                let scaled = CGRect(
                    x: rect.minX * scaleX,
                    y: rect.minY * scaleY,
                    width: rect.width * scaleX,
                    height: rect.height * scaleY
                )
                context.fill(Path(scaled), with: .color(.primary))
            }
        }
        .task {
            guard MascotShapes.canBlink(expression) else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_200_000_000)
                isBlinking = true
                try? await Task.sleep(nanoseconds: 120_000_000)
                isBlinking = false
            }
        }
        .task {
            guard MascotShapes.canWave(expression) else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 450_000_000)
                isWaving.toggle()
            }
        }
    }
}

enum MascotShapes {

    static let bodyAndFold: [CGRect] = [
        CGRect(x: 100, y: 50, width: 10, height: 200),
        CGRect(x: 100, y: 50, width: 140, height: 10),
        CGRect(x: 230, y: 50, width: 10, height: 200),
        CGRect(x: 100, y: 240, width: 140, height: 10),
        CGRect(x: 190, y: 50, width: 10, height: 10),
        CGRect(x: 200, y: 60, width: 10, height: 10),
        CGRect(x: 210, y: 70, width: 10, height: 10),
        CGRect(x: 220, y: 80, width: 10, height: 10),
    ]

    static func canBlink(_ expression: MascotExpression) -> Bool {
        expression != .agente
    }

    static func canWave(_ expression: MascotExpression) -> Bool {
        expression != .agente
    }

    static func face(for expression: MascotExpression, blinking: Bool = false, waving: Bool = false) -> [CGRect] {
        let shapes = shapes(for: expression)
        return (blinking ? shapes.eyesBlink : shapes.eyes)
            + (waving ? shapes.armAlt : shapes.arm)
            + shapes.rest
    }

    private struct ExpressionShapes {
        let eyes: [CGRect]
        let eyesBlink: [CGRect]
        let arm: [CGRect]
        let armAlt: [CGRect]
        let rest: [CGRect]
    }

    private static func shapes(for expression: MascotExpression) -> ExpressionShapes {
        switch expression {
        case .neutral:
            return ExpressionShapes(
                eyes: [
                    CGRect(x: 130, y: 140, width: 30, height: 30),
                    CGRect(x: 180, y: 140, width: 30, height: 30),
                ],
                eyesBlink: [
                    CGRect(x: 130, y: 152, width: 30, height: 6),
                    CGRect(x: 180, y: 152, width: 30, height: 6),
                ],
                // braccio destro: saluto, oscilla verso l'esterno
                arm: [
                    CGRect(x: 240, y: 180, width: 10, height: 10),
                    CGRect(x: 250, y: 170, width: 10, height: 10),
                    CGRect(x: 260, y: 160, width: 10, height: 10),
                    CGRect(x: 270, y: 150, width: 10, height: 10),
                    CGRect(x: 270, y: 130, width: 20, height: 20),
                ],
                armAlt: [
                    CGRect(x: 240, y: 180, width: 10, height: 10),
                    CGRect(x: 245, y: 160, width: 10, height: 10),
                    CGRect(x: 250, y: 140, width: 10, height: 10),
                    CGRect(x: 255, y: 120, width: 10, height: 10),
                    CGRect(x: 255, y: 100, width: 20, height: 20),
                ],
                rest: [
                    CGRect(x: 130, y: 120, width: 30, height: 10),
                    CGRect(x: 180, y: 110, width: 30, height: 10),
                    CGRect(x: 150, y: 200, width: 50, height: 10),
                    CGRect(x: 140, y: 190, width: 10, height: 10),
                    CGRect(x: 200, y: 190, width: 10, height: 10),
                    CGRect(x: 90, y: 200, width: 10, height: 10),
                    CGRect(x: 80, y: 210, width: 10, height: 10),
                    CGRect(x: 70, y: 220, width: 10, height: 10),
                    CGRect(x: 50, y: 230, width: 20, height: 20),
                ]
            )
        case .pensierosa:
            return ExpressionShapes(
                eyes: [
                    CGRect(x: 130, y: 130, width: 30, height: 30),
                    CGRect(x: 180, y: 130, width: 30, height: 30),
                ],
                eyesBlink: [
                    CGRect(x: 130, y: 142, width: 30, height: 6),
                    CGRect(x: 180, y: 142, width: 30, height: 6),
                ],
                // braccio al mento: piccolo tamburellare
                arm: [
                    CGRect(x: 240, y: 150, width: 10, height: 10),
                    CGRect(x: 220, y: 170, width: 10, height: 10),
                    CGRect(x: 190, y: 180, width: 10, height: 10),
                    CGRect(x: 160, y: 180, width: 20, height: 20),
                ],
                armAlt: [
                    CGRect(x: 240, y: 140, width: 10, height: 10),
                    CGRect(x: 220, y: 160, width: 10, height: 10),
                    CGRect(x: 190, y: 170, width: 10, height: 10),
                    CGRect(x: 160, y: 170, width: 20, height: 20),
                ],
                rest: [
                    CGRect(x: 130, y: 120, width: 30, height: 10),
                    CGRect(x: 180, y: 100, width: 30, height: 10),
                    CGRect(x: 150, y: 190, width: 20, height: 10),
                ]
            )
        case .felice:
            return ExpressionShapes(
                eyes: [
                    CGRect(x: 130, y: 140, width: 30, height: 30),
                    CGRect(x: 180, y: 140, width: 30, height: 30),
                ],
                eyesBlink: [
                    CGRect(x: 130, y: 152, width: 30, height: 6),
                    CGRect(x: 180, y: 152, width: 30, height: 6),
                ],
                arm: [
                    CGRect(x: 240, y: 170, width: 10, height: 10),
                    CGRect(x: 250, y: 160, width: 10, height: 10),
                    CGRect(x: 260, y: 150, width: 10, height: 10),
                    CGRect(x: 260, y: 130, width: 20, height: 20),
                    CGRect(x: 90, y: 170, width: 10, height: 10),
                    CGRect(x: 80, y: 160, width: 10, height: 10),
                    CGRect(x: 70, y: 150, width: 10, height: 10),
                    CGRect(x: 60, y: 130, width: 20, height: 20),
                ],
                armAlt: [
                    CGRect(x: 240, y: 160, width: 10, height: 10),
                    CGRect(x: 250, y: 150, width: 10, height: 10),
                    CGRect(x: 260, y: 140, width: 10, height: 10),
                    CGRect(x: 260, y: 120, width: 20, height: 20),
                    CGRect(x: 90, y: 160, width: 10, height: 10),
                    CGRect(x: 80, y: 150, width: 10, height: 10),
                    CGRect(x: 70, y: 140, width: 10, height: 10),
                    CGRect(x: 60, y: 120, width: 20, height: 20),
                ],
                rest: [
                    CGRect(x: 130, y: 100, width: 30, height: 10),
                    CGRect(x: 180, y: 100, width: 30, height: 10),
                    CGRect(x: 130, y: 180, width: 10, height: 10),
                    CGRect(x: 210, y: 180, width: 10, height: 10),
                    CGRect(x: 140, y: 190, width: 70, height: 10),
                    CGRect(x: 160, y: 200, width: 30, height: 10),
                ]
            )
        case .confusa:
            return ExpressionShapes(
                eyes: [
                    CGRect(x: 130, y: 140, width: 30, height: 30),
                ],
                eyesBlink: [
                    CGRect(x: 130, y: 152, width: 30, height: 6),
                ],
                arm: [
                    CGRect(x: 240, y: 140, width: 10, height: 10),
                    CGRect(x: 250, y: 120, width: 10, height: 10),
                    CGRect(x: 240, y: 100, width: 10, height: 10),
                    CGRect(x: 220, y: 70, width: 20, height: 20),
                ],
                armAlt: [
                    CGRect(x: 240, y: 150, width: 10, height: 10),
                    CGRect(x: 250, y: 130, width: 10, height: 10),
                    CGRect(x: 230, y: 110, width: 10, height: 10),
                    CGRect(x: 210, y: 80, width: 20, height: 20),
                ],
                rest: [
                    CGRect(x: 130, y: 90, width: 10, height: 10),
                    CGRect(x: 140, y: 110, width: 10, height: 10),
                    CGRect(x: 150, y: 120, width: 10, height: 10),
                    CGRect(x: 180, y: 80, width: 30, height: 10),
                    CGRect(x: 180, y: 150, width: 10, height: 10),
                    CGRect(x: 190, y: 140, width: 10, height: 10),
                    CGRect(x: 200, y: 150, width: 10, height: 10),
                    CGRect(x: 140, y: 190, width: 20, height: 10),
                    CGRect(x: 160, y: 170, width: 20, height: 10),
                    CGRect(x: 180, y: 190, width: 20, height: 10),
                ]
            )
        case .orologio:
            return ExpressionShapes(
                eyes: [
                    CGRect(x: 130, y: 140, width: 30, height: 30),
                    CGRect(x: 180, y: 140, width: 30, height: 30),
                ],
                eyesBlink: [
                    CGRect(x: 130, y: 152, width: 30, height: 6),
                    CGRect(x: 180, y: 152, width: 30, height: 6),
                ],
                arm: [
                    CGRect(x: 240, y: 180, width: 10, height: 10),
                    CGRect(x: 250, y: 170, width: 10, height: 10),
                    CGRect(x: 260, y: 160, width: 10, height: 10),
                    CGRect(x: 270, y: 150, width: 10, height: 10),
                    CGRect(x: 280, y: 100, width: 40, height: 10),
                    CGRect(x: 280, y: 130, width: 40, height: 10),
                    CGRect(x: 280, y: 100, width: 10, height: 40),
                    CGRect(x: 310, y: 100, width: 10, height: 40),
                    CGRect(x: 295, y: 110, width: 10, height: 20),
                    CGRect(x: 295, y: 120, width: 15, height: 10),
                    CGRect(x: 265, y: 100, width: 10, height: 5),
                    CGRect(x: 265, y: 110, width: 10, height: 5),
                    CGRect(x: 325, y: 100, width: 10, height: 5),
                    CGRect(x: 325, y: 110, width: 10, height: 5),
                ],
                armAlt: [
                    CGRect(x: 240, y: 180, width: 10, height: 10),
                    CGRect(x: 250, y: 170, width: 10, height: 10),
                    CGRect(x: 260, y: 160, width: 10, height: 10),
                    CGRect(x: 270, y: 150, width: 10, height: 10),
                    CGRect(x: 272, y: 100, width: 40, height: 10),
                    CGRect(x: 272, y: 130, width: 40, height: 10),
                    CGRect(x: 272, y: 100, width: 10, height: 40),
                    CGRect(x: 302, y: 100, width: 10, height: 40),
                    CGRect(x: 287, y: 110, width: 10, height: 20),
                    CGRect(x: 287, y: 120, width: 15, height: 10),
                    CGRect(x: 257, y: 100, width: 10, height: 5),
                    CGRect(x: 257, y: 110, width: 10, height: 5),
                    CGRect(x: 317, y: 100, width: 10, height: 5),
                    CGRect(x: 317, y: 110, width: 10, height: 5),
                ],
                rest: [
                    CGRect(x: 130, y: 95, width: 30, height: 10),
                    CGRect(x: 180, y: 95, width: 30, height: 10),
                    CGRect(x: 165, y: 195, width: 20, height: 20),
                    CGRect(x: 90, y: 200, width: 10, height: 10),
                    CGRect(x: 80, y: 210, width: 10, height: 10),
                    CGRect(x: 70, y: 220, width: 10, height: 10),
                    CGRect(x: 50, y: 230, width: 20, height: 20),
                ]
            )
        case .legge:
            return ExpressionShapes(
                eyes: [
                    CGRect(x: 148, y: 150, width: 12, height: 12),
                    CGRect(x: 198, y: 150, width: 12, height: 12),
                ],
                eyesBlink: [
                    CGRect(x: 148, y: 154, width: 12, height: 4),
                    CGRect(x: 198, y: 154, width: 12, height: 4),
                ],
                arm: [
                    CGRect(x: 240, y: 180, width: 10, height: 10),
                    CGRect(x: 250, y: 170, width: 10, height: 10),
                    CGRect(x: 260, y: 160, width: 10, height: 10),
                    CGRect(x: 240, y: 90, width: 60, height: 10),
                    CGRect(x: 240, y: 150, width: 60, height: 10),
                    CGRect(x: 240, y: 90, width: 10, height: 70),
                    CGRect(x: 290, y: 90, width: 10, height: 70),
                    CGRect(x: 255, y: 110, width: 30, height: 5),
                    CGRect(x: 255, y: 130, width: 30, height: 5),
                ],
                armAlt: [
                    CGRect(x: 240, y: 180, width: 10, height: 10),
                    CGRect(x: 250, y: 170, width: 10, height: 10),
                    CGRect(x: 260, y: 160, width: 10, height: 10),
                    CGRect(x: 240, y: 85, width: 60, height: 10),
                    CGRect(x: 240, y: 145, width: 60, height: 10),
                    CGRect(x: 240, y: 85, width: 10, height: 70),
                    CGRect(x: 290, y: 85, width: 10, height: 70),
                    CGRect(x: 255, y: 105, width: 30, height: 5),
                    CGRect(x: 255, y: 125, width: 30, height: 5),
                ],
                rest: [
                    CGRect(x: 112, y: 122, width: 14, height: 8),
                    CGRect(x: 126, y: 130, width: 14, height: 8),
                    CGRect(x: 194, y: 130, width: 14, height: 8),
                    CGRect(x: 208, y: 122, width: 14, height: 8),
                    CGRect(x: 125, y: 135, width: 40, height: 10),
                    CGRect(x: 125, y: 165, width: 40, height: 10),
                    CGRect(x: 125, y: 135, width: 10, height: 40),
                    CGRect(x: 155, y: 135, width: 10, height: 40),
                    CGRect(x: 175, y: 135, width: 40, height: 10),
                    CGRect(x: 175, y: 165, width: 40, height: 10),
                    CGRect(x: 175, y: 135, width: 10, height: 40),
                    CGRect(x: 205, y: 135, width: 10, height: 40),
                    CGRect(x: 165, y: 145, width: 10, height: 10),
                    CGRect(x: 160, y: 200, width: 20, height: 10),
                    CGRect(x: 90, y: 200, width: 10, height: 10),
                    CGRect(x: 80, y: 210, width: 10, height: 10),
                    CGRect(x: 70, y: 220, width: 10, height: 10),
                    CGRect(x: 50, y: 230, width: 20, height: 20),
                ]
            )
        case .agente:
            return ExpressionShapes(
                eyes: [],
                eyesBlink: [],
                arm: [],
                armAlt: [],
                rest: [
                    CGRect(x: 140, y: 10, width: 60, height: 20),
                    CGRect(x: 90, y: 30, width: 160, height: 10),
                    CGRect(x: 120, y: 145, width: 45, height: 20),
                    CGRect(x: 175, y: 145, width: 45, height: 20),
                    CGRect(x: 165, y: 150, width: 10, height: 10),
                    CGRect(x: 90, y: 200, width: 10, height: 10),
                    CGRect(x: 100, y: 190, width: 10, height: 10),
                    CGRect(x: 110, y: 180, width: 10, height: 10),
                    CGRect(x: 120, y: 170, width: 10, height: 10),
                    CGRect(x: 240, y: 200, width: 10, height: 10),
                    CGRect(x: 230, y: 190, width: 10, height: 10),
                    CGRect(x: 220, y: 180, width: 10, height: 10),
                    CGRect(x: 210, y: 170, width: 10, height: 10),
                ]
            )
        }
    }
}
