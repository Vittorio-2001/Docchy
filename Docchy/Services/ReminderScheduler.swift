//
//  ReminderScheduler.swift
//  Docchy
//
//  Created by Vittorio Monfrecola on 12/07/2026.
//

import Foundation
import UserNotifications

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
            var components = Calendar.current.dateComponents([.year, .month, .day], from: idealTriggerDate)
            components.hour = 9
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        }

        let request = UNNotificationRequest(identifier: document.id.uuidString, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    static func cancelReminder(for document: ScannedDocument) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [document.id.uuidString])
    }
}
