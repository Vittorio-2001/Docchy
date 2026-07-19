//
//  ScannedDocument.swift
//  Docchy
//
//  Created by Vittorio Monfrecola on 11/07/2026.
//


import Foundation
import SwiftData

@Model
final class ScannedDocument {
    var id: UUID
    var title: String
    var createdAt: Date
    var pageCount: Int
    /// Nome del file PDF salvato nella cartella Documents dell'app
    var fileName: String
    /// Testo riconosciuto dall'OCR (Vision), utile per una futura ricerca full-text
    var recognizedText: String
    /// Data di scadenza (rilevata dall'OCR o impostata a mano). Se presente,
    /// e' pianificato un promemoria locale.
    var expirationDate: Date?
    /// Se true, il documento richiede Face ID/Touch ID per essere aperto
    var isLocked: Bool

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = .now,
        pageCount: Int,
        fileName: String,
        recognizedText: String = "",
        expirationDate: Date? = nil,
        isLocked: Bool = false
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.pageCount = pageCount
        self.fileName = fileName
        self.recognizedText = recognizedText
        self.expirationDate = expirationDate
        self.isLocked = isLocked
    }

    /// URL assoluto del PDF sul disco
    var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }
}
