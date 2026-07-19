//
//  HelpAssistant.swift
//  Docchy
//
//  Created by Vittorio Monfrecola on 12/07/2026.
//


import Foundation

struct FAQItem: Identifiable {
    let id = UUID()
    let keywords: [String]
    let question: String
    let answer: String
}

/// Risponde alle domande sull'app cercando la corrispondenza migliore tra
/// parole chiave predefinite (in italiano e in inglese). Nessuna rete,
/// nessun modello linguistico: solo un confronto testuale locale.
enum HelpAssistant {

    static let faq: [FAQItem] = [
        FAQItem(
            keywords: ["scansion", "scan", "foto", "fotocamera", "photo", "camera", "picture"],
            question: String(localized: "Come scansiono un documento?"),
            answer: String(localized: "Tocca il pulsante + nella libreria: si apre la fotocamera che rileva da sola i bordi del foglio. Dopo aver scattato tutte le pagine, tocca \"Fine\" e passi alla revisione.")
        ),
        FAQItem(
            keywords: ["rinomina", "nome", "titolo", "rename", "name", "title"],
            question: String(localized: "Come rinomino un documento?"),
            answer: String(localized: "Puoi farlo subito durante la revisione (c'e' un campo apposito), oppure dopo: tieni premuto su un documento in libreria e scegli \"Rinomina\", o apri il documento e usa il menu \"...\".")
        ),
        FAQItem(
            keywords: ["esport", "pdf", "jpeg", "jpg", "png", "converti", "formato", "export", "convert", "format"],
            question: String(localized: "Come esporto un documento in un altro formato?"),
            answer: String(localized: "Apri il documento, tocca il menu \"...\" in alto e scegli \"Converti in\": puoi ottenere JPEG o PNG oltre al PDF originale. Il pulsante di condivisione invia invece direttamente il PDF.")
        ),
        FAQItem(
            keywords: ["scadenza", "promemoria", "notifica", "avviso", "expir", "reminder", "notification", "due date", "alert"],
            question: String(localized: "Come funzionano i promemoria di scadenza?"),
            answer: String(localized: "Se l'OCR trova una data vicina a parole come \"scadenza\" o \"valido fino\", te la propone gia' in revisione. Puoi anche impostarla o modificarla in qualsiasi momento dal menu \"...\" del documento: riceverai una notifica 7 giorni prima.")
        ),
        FAQItem(
            keywords: ["face id", "blocc", "sicur", "touch id", "lock", "secur", "password"],
            question: String(localized: "Come blocco un documento con Face ID?"),
            answer: String(localized: "Tieni premuto su un documento in libreria (o apri il menu \"...\" dentro il documento) e scegli \"Blocca con Face ID\". Da quel momento, per aprirlo o rimuovere il blocco serve l'autenticazione.")
        ),
        FAQItem(
            keywords: ["cerca", "ricerca", "trova", "cercare", "search", "find"],
            question: String(localized: "Come funziona la ricerca?"),
            answer: String(localized: "La barra di ricerca in libreria controlla sia il nome dei documenti sia il testo riconosciuto dall'OCR al loro interno: puoi trovare un documento anche cercando una parola scritta nel foglio, non solo nel titolo.")
        ),
        FAQItem(
            keywords: ["elimina", "cancella", "rimuovi", "delete", "remove"],
            question: String(localized: "Come elimino un documento?"),
            answer: String(localized: "Scorri la riga del documento verso sinistra in libreria e tocca \"Elimina\".")
        ),
        FAQItem(
            keywords: ["privacy", "account", "cloud", "dati", "server", "internet", "abbonamento", "data", "subscription", "online"],
            question: String(localized: "I miei documenti vengono caricati online?"),
            answer: String(localized: "No. Docchy funziona tutto sul dispositivo: scansione, OCR, promemoria e blocco non passano mai da server esterni. Nessun account, nessun abbonamento.")
        ),
    ]

    static func bestMatch(for query: String) -> FAQItem? {
        let normalized = query.lowercased()
        guard !normalized.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }

        var bestItem: FAQItem?
        var bestScore = 0

        for item in faq {
            let score = item.keywords.reduce(0) { partial, keyword in
                normalized.contains(keyword) ? partial + 1 : partial
            }
            if score > bestScore {
                bestScore = score
                bestItem = item
            }
        }

        return bestScore > 0 ? bestItem : nil
    }
}
