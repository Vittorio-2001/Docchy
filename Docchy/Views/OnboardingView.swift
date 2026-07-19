//
//  OnboardingView.swift
//  Docchy
//
//  Created by Vittorio Monfrecola on 11/07/2026.
//

import SwiftUI

struct OnboardingPage {
    let expression: MascotExpression
    let title: String
    let subtitle: String
    let buttonTitle: String
}

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            expression: .neutral,
            title: String(localized: "Benvenuto su Docchy"),
            subtitle: String(localized: "Docchy e' il tuo assistente per gestire i documenti in modo semplice, senza account e senza abbonamenti."),
            buttonTitle: String(localized: "Continua")
        ),
        OnboardingPage(
            expression: .pensierosa,
            title: String(localized: "Scansiona in un tocco"),
            subtitle: String(localized: "Inquadra il documento: i bordi vengono rilevati automaticamente, senza bisogno di ritagliare a mano."),
            buttonTitle: String(localized: "Continua")
        ),
        OnboardingPage(
            expression: .legge,
            title: String(localized: "Docchy legge per te"),
            subtitle: String(localized: "Il testo di ogni scansione viene riconosciuto sul dispositivo: potrai ritrovare un documento anche cercando una parola scritta al suo interno."),
            buttonTitle: String(localized: "Continua")
        ),
        OnboardingPage(
            expression: .orologio,
            title: String(localized: "Scadenze sotto controllo"),
            subtitle: String(localized: "Se Docchy trova una data di scadenza nel documento, te la ricorda automaticamente qualche giorno prima."),
            buttonTitle: String(localized: "Continua")
        ),
        OnboardingPage(
            expression: .agente,
            title: String(localized: "Privacy prima di tutto"),
            subtitle: String(localized: "Puoi bloccare i documenti piu' delicati con Face ID. Tutto resta sul tuo iPhone: nessun cloud, nessun account. Per qualsiasi dubbio, Docchy e' sempre a un tocco di distanza."),
            buttonTitle: String(localized: "Inizia")
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 6) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: index == currentPage ? 16 : 6, height: 6)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: currentPage)
            .padding(.bottom, 18)

            Button {
                advance()
            } label: {
                Text(pages[currentPage].buttonTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private func advance() {
        if currentPage < pages.count - 1 {
            withAnimation { currentPage += 1 }
        } else {
            hasCompletedOnboarding = true
            dismiss()
        }
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            MascotView(expression: page.expression)
                .frame(width: 180, height: 150)

            Text(page.title)
                .font(.title2.bold())
                .padding(.top, 28)

            Text(page.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 10)

            Spacer()
            Spacer()
        }
    }
}
