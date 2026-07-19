//
//  LibraryView.swift
//  Docchy
//
//  Created by Vittorio Monfrecola on 12/07/2026.
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScannedDocument.createdAt, order: .reverse) private var documents: [ScannedDocument]

    @State private var navigationPath = NavigationPath()

    @State private var isShowingScanner = false
    @State private var isShowingReview = false
    @State private var scannedPages: [UIImage] = []
    @State private var pendingScanResult: [UIImage]?
    @State private var searchText = ""
    @State private var documentBeingRenamed: ScannedDocument?
    @State private var renameText = ""
    @State private var unlockFailedAlert = false
    @State private var isShowingAssistant = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if documents.isEmpty {
                    ContentUnavailableView(
                        "Nessun documento",
                        systemImage: "doc.text.viewfinder",
                        description: Text("Tocca + per scansionare il tuo primo documento")
                    )
                } else if filteredDocuments.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        ForEach(filteredDocuments) { document in
                            rowLink(for: document)
                                .contextMenu {
                                    Button {
                                        renameText = document.title
                                        documentBeingRenamed = document
                                    } label: {
                                        Label("Rinomina", systemImage: "pencil")
                                    }

                                    Button {
                                        toggleLock(for: document)
                                    } label: {
                                        Label(
                                            document.isLocked ? "Rimuovi blocco" : "Blocca con Face ID",
                                            systemImage: document.isLocked ? "lock.open" : "lock"
                                        )
                                    }
                                }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Cerca documenti")
            .navigationTitle("Documenti")
            .navigationDestination(for: ScannedDocument.self) { document in
                DocumentDetailView(document: document)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingAssistant = true
                    } label: {
                        Image(systemName: "questionmark.bubble")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingScanner = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fullScreenCover(isPresented: $isShowingScanner, onDismiss: {
                if let pages = pendingScanResult {
                    scannedPages = pages
                    pendingScanResult = nil
                    isShowingReview = true
                }
            }) {
                DocumentCameraView(
                    onFinish: { images in
                        pendingScanResult = images
                        isShowingScanner = false
                    },
                    onCancel: { isShowingScanner = false }
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $isShowingReview) {
                ScanReviewView(pages: scannedPages, onSaved: { scannedPages = [] })
            }
            .alert("Rinomina documento", isPresented: Binding(
                get: { documentBeingRenamed != nil },
                set: { if !$0 { documentBeingRenamed = nil } }
            )) {
                TextField("Nome documento", text: $renameText)
                Button("Annulla", role: .cancel) {}
                Button("Salva") {
                    let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        documentBeingRenamed?.title = trimmed
                    }
                }
            }
            .alert("Autenticazione non riuscita", isPresented: $unlockFailedAlert) {
                Button("OK", role: .cancel) {}
            }
            .fullScreenCover(isPresented: Binding(
                get: { !hasCompletedOnboarding },
                set: { isPresented in
                    if !isPresented { hasCompletedOnboarding = true }
                }
            )) {
                OnboardingView()
            }
            .sheet(isPresented: $isShowingAssistant) {
                AssistantView()
            }
        }
    }

    /// Riga del documento: se e' bloccato, il tocco richiede Face ID prima di
    /// navigare al dettaglio; altrimenti si comporta come un normale link.
    @ViewBuilder
    private func rowLink(for document: ScannedDocument) -> some View {
        if document.isLocked {
            Button {
                attemptUnlock(document)
            } label: {
                DocumentRow(document: document, searchText: searchText)
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: document) {
                DocumentRow(document: document, searchText: searchText)
            }
        }
    }

    private func attemptUnlock(_ document: ScannedDocument) {
        Task {
            let success = await AuthenticationManager.authenticate(
                reason: String(format: String(localized: "Sblocca per aprire \"%@\""), document.title)
            )
            if success {
                navigationPath.append(document)
            } else {
                unlockFailedAlert = true
            }
        }
    }

    private func toggleLock(for document: ScannedDocument) {
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

    private var filteredDocuments: [ScannedDocument] {
        guard !searchText.isEmpty else { return documents }
        return documents.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.recognizedText.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let document = filteredDocuments[index]
            PDFBuilder.deleteFile(named: document.fileName)
            modelContext.delete(document)
        }
    }
}

private struct DocumentRow: View {
    let document: ScannedDocument
    var searchText: String = ""

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "doc.text")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 38, height: 48)
                    .background(.fill.tertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                if document.isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(.orange, in: Circle())
                        .offset(x: 4, y: 4)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(document.title)
                    .font(.subheadline.weight(.medium))
                Text("\(document.createdAt.formatted(date: .abbreviated, time: .omitted)) · \(document.pageCount) pagine")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let expirationDate = document.expirationDate {
                    Label(expirationDate.formatted(date: .abbreviated, time: .omitted), systemImage: "bell.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                if let snippet = contentMatchSnippet {
                    Label(snippet, systemImage: "text.viewfinder")
                        .font(.caption2)
                        .foregroundStyle(Color.accentColor)
                        .lineLimit(1)
                }
            }
        }
        .foregroundStyle(.primary)
    }

    /// Se la ricerca trova il termine nel testo OCR ma non nel titolo,
    /// mostra un piccolo estratto per far capire perche' il documento e' comparso.
    private var contentMatchSnippet: String? {
        guard !searchText.isEmpty,
              !document.title.localizedCaseInsensitiveContains(searchText),
              let range = document.recognizedText.range(of: searchText, options: .caseInsensitive) else {
            return nil
        }

        let text = document.recognizedText
        let start = text.index(range.lowerBound, offsetBy: -18, limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(range.upperBound, offsetBy: 18, limitedBy: text.endIndex) ?? text.endIndex

        let snippet = text[start..<end].replacingOccurrences(of: "\n", with: " ")
        return "…\(snippet)…"
    }
}
