//
//  AuthenticationManager.swift
//  Docchy
//
//  Created by Vittorio Monfrecola on 12/07/2026.
//

import LocalAuthentication

/// Autenticazione biometrica (Face ID/Touch ID, con fallback al codice del
/// dispositivo) usata per aprire o rimuovere il blocco di un documento.
/// Tutto on-device: nessun dato lascia il dispositivo.
enum AuthenticationManager {

    static var isBiometricAuthAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    static func authenticate(reason: String = String(localized: "Sblocca per accedere al documento")) async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }

        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
}
