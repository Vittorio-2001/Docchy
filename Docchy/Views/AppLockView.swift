//
//  AppLockView.swift
//  Docchy
//
//  Created by Vittorio Monfrecola on 12/07/2026.
//


import SwiftUI

/// Avvolge il contenuto principale dell'app e mostra una schermata di blocco
/// (con Face ID/Touch ID) quando l'utente ha attivato l'impostazione, sia
/// all'avvio sia ogni volta che l'app torna in primo piano.
struct AppLockView<Content: View>: View {
    @AppStorage("isFaceIDLockEnabled") private var isLockEnabled = false
    @Environment(\.scenePhase) private var scenePhase

    @State private var isUnlocked = false
    @State private var authFailed = false

    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            content()
                .opacity(shouldShowLock ? 0 : 1)

            if shouldShowLock {
                LockScreenView(authFailed: authFailed, onUnlock: unlockButtonTapped)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background && isLockEnabled {
                isUnlocked = false
                authFailed = false
            }
        }
        .task(id: shouldShowLock) {
            if shouldShowLock {
                await authenticate()
            }
        }
    }

    private var shouldShowLock: Bool {
        isLockEnabled && !isUnlocked
    }

    private func unlockButtonTapped() {
        Task { await authenticate() }
    }

    private func authenticate() async {
        let success = await AuthenticationManager.authenticate()
        authFailed = !success
        isUnlocked = success
    }
}

/// Schermata mostrata mentre l'app e' bloccata: mascotte + pulsante per sbloccare.
private struct LockScreenView: View {
    let authFailed: Bool
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            MascotView(expression: authFailed ? .confusa : .neutral)
                .frame(width: 140, height: 116)

            Text("Documenti bloccati")
                .font(.title2.bold())

            Text(authFailed
                 ? "Autenticazione non riuscita, riprova."
                 : "Sblocca con Face ID per accedere ai tuoi documenti.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                onUnlock()
            } label: {
                Label("Sblocca", systemImage: "faceid")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .background(Color(.systemBackground))
    }
}