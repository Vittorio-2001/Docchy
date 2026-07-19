//
//  SettingsView.swift
//  Docchy
//
//  Created by Vittorio Monfrecola on 12/07/2026.
//


import SwiftUI

struct SettingsView: View {
    @AppStorage("isFaceIDLockEnabled") private var isLockEnabled = false
    @Environment(\.dismiss) private var dismiss
    @State private var biometryUnavailableAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Blocca con Face ID", isOn: Binding(
                        get: { isLockEnabled },
                        set: { newValue in
                            if newValue && !AuthenticationManager.isBiometricAuthAvailable {
                                biometryUnavailableAlert = true
                            } else {
                                isLockEnabled = newValue
                            }
                        }
                    ))
                } footer: {
                    Text("Se attivo, dovrai sbloccare l'app con Face ID (o il codice del telefono) ogni volta che la apri o torni da un'altra app. Nessun dato lascia il tuo iPhone.")
                }
            }
            .navigationTitle("Impostazioni")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fatto") { dismiss() }
                }
            }
            .alert("Face ID non disponibile", isPresented: $biometryUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Il tuo dispositivo non supporta Face ID/Touch ID, oppure non e' configurato in Impostazioni.")
            }
        }
    }
}