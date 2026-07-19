//
//  ShareSheet.swift
//  Docchy
//
//  Created by Vittorio Monfrecola on 11/07/2026.
//


import SwiftUI
import UIKit

/// Share sheet nativo per condividere/esportare file (PDF o immagini).
/// Usato al posto di ShareLink quando gli item da condividere vengono
/// generati dinamicamente al momento del tocco (es. conversione in JPEG/PNG).
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
