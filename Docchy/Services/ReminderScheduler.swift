//
//  ReminderScheduler.swift
//  Docchy
//
//  Created by Vittorio Monfrecola on 12/07/2026.
//

import Foundation
import UserNotifications

/// Pianifica promemoria locali (nessun server, nessun account) per le
/// scadenze dei documenti, usando UNUserNotificationCenter.
enum ReminderScheduler {

    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    /// Pianifica un promemoria un tot di giorni prima della scadenza.
    /// Se esiste gia' un promemoria per lo stesso documento, lo sostituisce.
    static func scheduleReminder(for document: ScannedDocument, daysBefore: Int = 7) async {
        cancelReminder(for: document)

        guard let expirationDate = document.expirationDate, expirationDate > Date() else { return }
        guard await requestAuthorizationIfNeeded() else { return }

        let idealTriggerDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: expirationDate) ?? expirationDate

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Documento in scadenza")
        content.body = String(
            format: String(localized: "\"%@\" scade il %@."),
            document.title,
            expirationDate.formatted(date: .abbreviated, time: .omitted)
        )
        content.sound = .default

        let trigger: UNNotificationTrigger
        if idealTriggerDate > Date() {
            // Preavviso normale: il giorno calcolato, alle 9 del mattino
            var components = Calendar.current.dateComponents([.year, .month, .day], from: idealTriggerDate)
            components.hour = 9
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        } else {
            // La scadenza e' troppo vicina per il preavviso standard: avvisa comunque a breve
            // invece di non pianificare nulla (un trigger a intervallo e' sempre nel futuro).
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        }

        let request = UNNotificationRequest(identifier: document.id.uuidString, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    static func cancelReminder(for document: ScannedDocument) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [document.id.uuidString])
    }
}
