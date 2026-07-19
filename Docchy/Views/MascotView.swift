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

/// Disegna la mascotte pixel-art (documento con piega, occhi e braccia)
/// come una griglia di rettangoli pieni, scalati al frame disponibile.
/// Usa Color.primary cosi si adatta automaticamente a Dark Mode.
struct MascotView: View {
    let expression: MascotExpression
    @State private var animate = false

    var body: some View {
        Canvas { context, size in
            let scaleX = size.width / 340
            let scaleY = size.height / 280

            for rect in MascotShapes.bodyAndFold + MascotShapes.face(for: expression) {
                let scaled = CGRect(
                    x: rect.minX * scaleX,
                    y: rect.minY * scaleY,
                    width: rect.width * scaleX,
                    height: rect.height * scaleY
                )
                context.fill(Path(scaled), with: .color(.primary))
            }
        }
        .modifier(MascotMotion(expression: expression, animate: animate))
        .onAppear {
            withAnimation(motionAnimation) {
                animate = true
            }
        }
    }

    private var motionAnimation: Animation {
        switch expression {
        case .orologio:
            return .easeInOut(duration: 0.12).repeatForever(autoreverses: true)
        default:
            return .easeInOut(duration: 1.6).repeatForever(autoreverses: true)
        }
    }
}

private struct MascotMotion: ViewModifier {
    let expression: MascotExpression
    let animate: Bool

    func body(content: Content) -> some View {
        switch expression {
        case .orologio:
            content.rotationEffect(.degrees(animate ? 3 : -3))
        default:
            content.offset(y: animate ? -3 : 3)
        }
    }
}

/// Coordinate "a griglia" (1 cella = 10 unita' su un canvas 340x280) che
/// replicano esattamente i pixel disegnati nei mockup della mascotte.
enum MascotShapes {

    /// Corpo del documento e piega in alto a destra: uguali per ogni espressione.
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

    static func face(for expression: MascotExpression) -> [CGRect] {
        switch expression {
        case .neutral:
            return [
                CGRect(x: 130, y: 120, width: 30, height: 10),
                CGRect(x: 180, y: 110, width: 30, height: 10),
                CGRect(x: 130, y: 140, width: 30, height: 30),
                CGRect(x: 180, y: 140, width: 30, height: 30),
                CGRect(x: 150, y: 200, width: 50, height: 10),
                CGRect(x: 140, y: 190, width: 10, height: 10),
                CGRect(x: 200, y: 190, width: 10, height: 10),
                CGRect(x: 240, y: 180, width: 10, height: 10),
                CGRect(x: 250, y: 170, width: 10, height: 10),
                CGRect(x: 260, y: 160, width: 10, height: 10),
                CGRect(x: 270, y: 150, width: 10, height: 10),
                CGRect(x: 270, y: 130, width: 20, height: 20),
                CGRect(x: 90, y: 200, width: 10, height: 10),
                CGRect(x: 80, y: 210, width: 10, height: 10),
                CGRect(x: 70, y: 220, width: 10, height: 10),
                CGRect(x: 50, y: 230, width: 20, height: 20),
            ]
        case .pensierosa:
            return [
                CGRect(x: 130, y: 120, width: 30, height: 10),
                CGRect(x: 180, y: 100, width: 30, height: 10),
                CGRect(x: 130, y: 130, width: 30, height: 30),
                CGRect(x: 180, y: 130, width: 30, height: 30),
                CGRect(x: 150, y: 190, width: 20, height: 10),
                CGRect(x: 240, y: 150, width: 10, height: 10),
                CGRect(x: 220, y: 170, width: 10, height: 10),
                CGRect(x: 190, y: 180, width: 10, height: 10),
                CGRect(x: 160, y: 180, width: 20, height: 20),
            ]
        case .felice:
            return [
                CGRect(x: 130, y: 100, width: 30, height: 10),
                CGRect(x: 180, y: 100, width: 30, height: 10),
                CGRect(x: 130, y: 140, width: 30, height: 30),
                CGRect(x: 180, y: 140, width: 30, height: 30),
                CGRect(x: 130, y: 180, width: 10, height: 10),
                CGRect(x: 210, y: 180, width: 10, height: 10),
                CGRect(x: 140, y: 190, width: 70, height: 10),
                CGRect(x: 160, y: 200, width: 30, height: 10),
                CGRect(x: 240, y: 170, width: 10, height: 10),
                CGRect(x: 250, y: 160, width: 10, height: 10),
                CGRect(x: 260, y: 150, width: 10, height: 10),
                CGRect(x: 260, y: 130, width: 20, height: 20),
                CGRect(x: 90, y: 170, width: 10, height: 10),
                CGRect(x: 80, y: 160, width: 10, height: 10),
                CGRect(x: 70, y: 150, width: 10, height: 10),
                CGRect(x: 60, y: 130, width: 20, height: 20),
            ]
        case .confusa:
            return [
                CGRect(x: 130, y: 90, width: 10, height: 10),
                CGRect(x: 140, y: 110, width: 10, height: 10),
                CGRect(x: 150, y: 120, width: 10, height: 10),
                CGRect(x: 180, y: 80, width: 30, height: 10),
                CGRect(x: 130, y: 140, width: 30, height: 30),
                CGRect(x: 180, y: 150, width: 10, height: 10),
                CGRect(x: 190, y: 140, width: 10, height: 10),
                CGRect(x: 200, y: 150, width: 10, height: 10),
                CGRect(x: 140, y: 190, width: 20, height: 10),
                CGRect(x: 160, y: 170, width: 20, height: 10),
                CGRect(x: 180, y: 190, width: 20, height: 10),
                CGRect(x: 240, y: 140, width: 10, height: 10),
                CGRect(x: 250, y: 120, width: 10, height: 10),
                CGRect(x: 240, y: 100, width: 10, height: 10),
                CGRect(x: 220, y: 70, width: 20, height: 20),
            ]
        case .orologio:
            return [
                // sopracciglia sorprese, entrambe alzate
                CGRect(x: 130, y: 95, width: 30, height: 10),
                CGRect(x: 180, y: 95, width: 30, height: 10),
                // occhi
                CGRect(x: 130, y: 140, width: 30, height: 30),
                CGRect(x: 180, y: 140, width: 30, height: 30),
                // bocca aperta "o" di sorpresa
                CGRect(x: 165, y: 195, width: 20, height: 20),
                // braccio sinistro in appoggio
                CGRect(x: 90, y: 200, width: 10, height: 10),
                CGRect(x: 80, y: 210, width: 10, height: 10),
                CGRect(x: 70, y: 220, width: 10, height: 10),
                CGRect(x: 50, y: 230, width: 20, height: 20),
                // braccio destro alzato verso l'orologio
                CGRect(x: 240, y: 180, width: 10, height: 10),
                CGRect(x: 250, y: 170, width: 10, height: 10),
                CGRect(x: 260, y: 160, width: 10, height: 10),
                CGRect(x: 270, y: 150, width: 10, height: 10),
                // quadrante dell'orologio (contorno vuoto) e lancette
                CGRect(x: 280, y: 100, width: 40, height: 10),
                CGRect(x: 280, y: 130, width: 40, height: 10),
                CGRect(x: 280, y: 100, width: 10, height: 40),
                CGRect(x: 310, y: 100, width: 10, height: 40),
                CGRect(x: 295, y: 110, width: 10, height: 20),
                CGRect(x: 295, y: 120, width: 15, height: 10),
                // vibrazione sugli angoli in alto, sinistra e destra
                CGRect(x: 265, y: 100, width: 10, height: 5),
                CGRect(x: 265, y: 110, width: 10, height: 5),
                CGRect(x: 325, y: 100, width: 10, height: 5),
                CGRect(x: 325, y: 110, width: 10, height: 5),
            ]
        case .legge:
            return [
                // sopracciglia concentrate, leggermente aggrottate verso il centro
                CGRect(x: 112, y: 122, width: 14, height: 8),
                CGRect(x: 126, y: 130, width: 14, height: 8),
                CGRect(x: 194, y: 130, width: 14, height: 8),
                CGRect(x: 208, y: 122, width: 14, height: 8),
                // occhiali da vista (contorno vuoto) con ponte centrale
                CGRect(x: 125, y: 135, width: 40, height: 10),
                CGRect(x: 125, y: 165, width: 40, height: 10),
                CGRect(x: 125, y: 135, width: 10, height: 40),
                CGRect(x: 155, y: 135, width: 10, height: 40),
                CGRect(x: 175, y: 135, width: 40, height: 10),
                CGRect(x: 175, y: 165, width: 40, height: 10),
                CGRect(x: 175, y: 135, width: 10, height: 40),
                CGRect(x: 205, y: 135, width: 10, height: 40),
                CGRect(x: 165, y: 145, width: 10, height: 10),
                // occhi, spostati verso destra: guarda il documento che tiene alzato
                CGRect(x: 148, y: 150, width: 12, height: 12),
                CGRect(x: 198, y: 150, width: 12, height: 12),
                // bocca piccola, concentrata
                CGRect(x: 160, y: 200, width: 20, height: 10),
                // braccio sinistro in appoggio
                CGRect(x: 90, y: 200, width: 10, height: 10),
                CGRect(x: 80, y: 210, width: 10, height: 10),
                CGRect(x: 70, y: 220, width: 10, height: 10),
                CGRect(x: 50, y: 230, width: 20, height: 20),
                // braccio destro alzato verso il documento
                CGRect(x: 240, y: 180, width: 10, height: 10),
                CGRect(x: 250, y: 170, width: 10, height: 10),
                CGRect(x: 260, y: 160, width: 10, height: 10),
                // documento grande (contorno vuoto) con due righe di testo
                CGRect(x: 240, y: 90, width: 60, height: 10),
                CGRect(x: 240, y: 150, width: 60, height: 10),
                CGRect(x: 240, y: 90, width: 10, height: 70),
                CGRect(x: 290, y: 90, width: 10, height: 70),
                CGRect(x: 255, y: 110, width: 30, height: 5),
                CGRect(x: 255, y: 130, width: 30, height: 5),
            ]
        case .agente:
            return [
                // cappello: cupola e falda
                CGRect(x: 140, y: 10, width: 60, height: 20),
                CGRect(x: 90, y: 30, width: 160, height: 10),
                // occhiali da sole scuri, due lenti separate collegate da un ponte
                CGRect(x: 120, y: 145, width: 45, height: 20),
                CGRect(x: 175, y: 145, width: 45, height: 20),
                CGRect(x: 165, y: 150, width: 10, height: 10),
                // colletto alzato che nasconde bocca e braccia
                CGRect(x: 90, y: 200, width: 10, height: 10),
                CGRect(x: 100, y: 190, width: 10, height: 10),
                CGRect(x: 110, y: 180, width: 10, height: 10),
                CGRect(x: 120, y: 170, width: 10, height: 10),
                CGRect(x: 240, y: 200, width: 10, height: 10),
                CGRect(x: 230, y: 190, width: 10, height: 10),
                CGRect(x: 220, y: 180, width: 10, height: 10),
                CGRect(x: 210, y: 170, width: 10, height: 10),
            ]
        }
    }
}
