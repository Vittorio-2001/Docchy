//
//  DocumentDetailView.swift
//  Docchy
//
//  Created by Vittorio Monfrecola on 12/07/2026.
//

import SwiftUI
import PDFKit

struct DocumentDetailView: View {
    @Bindable var document: ScannedDocument

    @State private var isRenaming = false
    @State private var newTitle = ""
    @State private var activeShareItems: ShareItems?
    @State private var exportError: String?
    @State private var isEditingReminder = false
    @State private var unlockFailedAlert = false

    var body: some View {
        PDFKitView(url: document.fileURL)
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            newTitle = document.title
                            isRenaming = true
                        } label: {
                            Label("Rinomina", systemImage: "pencil")
                        }

                        Menu {
                            Button {
                                exportImages(format: .jpeg)
                            } label: {
                                Label("JPEG", systemImage: "photo")
                            }

                            Button {
                                exportImages(format: .png)
                            } label: {
                                Label("PNG", systemImage: "photo.on.rectangle")
                            }
                        } label: {
                            Label("Converti in", systemImage: "arrow.triangle.2.circlepath")
                        }

                        Button {
                            isEditingReminder = true
                        } label: {
                            Label(
                                document.expirationDate == nil ? "Imposta scadenza" : "Modifica scadenza",
                                systemImage: "bell"
                            )
                        }

                        Button {
                            toggleLock()
                        } label: {
                            Label(
                                document.isLocked ? "Rimuovi blocco" : "Blocca con Face ID",
                                systemImage: document.isLocked ? "lock.open" : "lock"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        sharePDF()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .alert("Rinomina documento", isPresented: $isRenaming) {
                TextField("Nome documento", text: $newTitle)
                Button("Annulla", role: .cancel) {}
                Button("Salva") {
                    let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        document.title = trimmed
                    }
                }
            }
            .sheet(item: $activeShareItems) { wrapper in
                ShareSheet(items: wrapper.items)
            }
            .sheet(isPresented: $isEditingReminder) {
                ReminderEditView(document: document)
            }
            .alert("Esportazione non riuscita", isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("OK") { exportError = nil }
            } message: {
                Text(exportError ?? "")
            }
            .alert("Autenticazione non riuscita", isPresented: $unlockFailedAlert) {
                Button("OK", role: .cancel) {}
            }
    }

    private func toggleLock() {
        if document.isLocked {
            Task {
                let success = await AuthenticationManager.authenticate(
                    reason: String(localized: "Sblocca per rimuovere il blocco")
                )
                if success {
                    document.isLocked = false
                } else {
                    unlockFailedAlert = true
                }
            }
        } else {
            document.isLocked = true
        }
    }

    private func sharePDF() {
        do {
            let url = try ImageExporter.renamedCopy(of: document.fileURL, as: document.title, extension: "pdf")
            activeShareItems = ShareItems(items: [url])
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func exportImages(format: ImageExportFormat) {
        do {
            let urls = try ImageExporter.exportPages(from: document.fileURL, format: format, baseName: document.title)
            activeShareItems = ShareItems(items: urls)
        } catch {
            exportError = error.localizedDescription
        }
    }
}

/// Wrapper Identifiable per gli item da condividere: usare .sheet(item:)
/// invece di .sheet(isPresented:) + una variabile separata evita che la
/// prima presentazione mostri lo share sheet vuoto (i due stati non sono
/// garantiti come un unico aggiornamento atomico in SwiftUI).
private struct ShareItems: Identifiable {
    let id = UUID()
    let items: [Any]
}

/// Wrapper minimale di PDFView (PDFKit) per SwiftUI
private struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}

/// Sheet per impostare, modificare o rimuovere il promemoria di scadenza
/// di un documento gia' salvato.
private struct ReminderEditView: View {
    @Bindable var document: ScannedDocument
    @Environment(\.dismiss) private var dismiss

    @State private var reminderEnabled: Bool
    @State private var expirationDate: Date

    init(document: ScannedDocument) {
        self.document = document
        _reminderEnabled = State(initialValue: document.expirationDate != nil)
        _expirationDate = State(initialValue: document.expirationDate ?? .now)
    }

    var body: some View {
        NavigationStack {
            Form {
                Toggle("Promemoria scadenza", isOn: $reminderEnabled)

                if reminderEnabled {
                    DatePicker(
                        "Data di scadenza",
                        selection: $expirationDate,
                        displayedComponents: .date
                    )
                }
            }
            .navigationTitle("Scadenza")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") { save() }
                }
            }
        }
    }

    private func save() {
        document.expirationDate = reminderEnabled ? expirationDate : nil

        if reminderEnabled {
            Task {
                await ReminderScheduler.scheduleReminder(for: document)
            }
        } else {
            ReminderScheduler.cancelReminder(for: document)
        }

        dismiss()
    }
}
