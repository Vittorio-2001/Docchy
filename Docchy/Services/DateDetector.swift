//
//  DateDetector.swift
//  Docchy
//
//  Created by Vittorio Monfrecola on 12/07/2026.
//


import Foundation

/// Cerca nel testo riconosciuto dall'OCR una possibile data di scadenza,
/// dando priorita' alle date vicine a parole chiave come "scadenza",
/// "valido fino", "expiry". Nessuna rete, nessun modello: solo NSDataDetector.
enum DateDetector {

    static func detectExpirationDate(in text: String) -> Date? {
        guard !text.isEmpty,
              let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }

        let matches = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
        guard !matches.isEmpty else { return nil }

        let keywords = ["scad", "valid", "expir"]

        // 1. Cerca una data preceduta da una parola chiave di scadenza/validita'
        for match in matches {
            guard let date = match.date, let range = Range(match.range, in: text) else { continue }
            let contextStart = text.index(range.lowerBound, offsetBy: -30, limitedBy: text.startIndex) ?? text.startIndex
            let context = text[contextStart..<range.lowerBound].lowercased()
            if keywords.contains(where: { context.contains($0) }) {
                return date
            }
        }

        // 2. Altrimenti, se c'e' esattamente una data futura nel testo, usa quella
        let futureDates = matches.compactMap(\.date).filter { $0 > Date() }
        if futureDates.count == 1 {
            return futureDates.first
        }

        return nil
    }
}