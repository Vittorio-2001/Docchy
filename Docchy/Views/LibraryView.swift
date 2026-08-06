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
                        if searchText.isEmpty, let expiringSoonDocument {
                            Section {
                                expiringSoonCallout(for: expiringSoonDocument)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        }

                        ForEach(groupedDocuments, id: \.title) { group in
                            Section(group.title) {
                                ForEach(group.documents) { document in
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
                                .onDelete { offsets in
                                    delete(from: group.documents, at: offsets)
                                }
                            }
                        }
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

    @ViewBuilder
    private func expiringSoonCallout(for document: ScannedDocument) -> some View {
        Button {
            if document.isLocked {
                attemptUnlock(document)
            } else {
                navigationPath.append(document)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bell.fill")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("1 documento in scadenza")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                    if let expirationDate = document.expirationDate {
                        Text("\(document.title) · \(relativeDaysText(for: expirationDate))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(12)
            .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func relativeDaysText(for date: Date) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: .now),
            to: calendar.startOfDay(for: date)
        ).day ?? 0

        if days <= 0 { return String(localized: "oggi") }
        if days == 1 { return String(localized: "domani") }
        return String(format: String(localized: "tra %d giorni"), days)
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

    private var groupedDocuments: [(title: String, documents: [ScannedDocument])] {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)

        var order: [String] = []
        var groups: [String: [ScannedDocument]] = [:]

        for document in filteredDocuments {
            let sectionTitle: String
            if calendar.isDateInToday(document.createdAt) {
                sectionTitle = String(localized: "Oggi")
            } else if calendar.isDateInYesterday(document.createdAt) {
                sectionTitle = String(localized: "Ieri")
            } else if let weekAgo, document.createdAt > weekAgo {
                sectionTitle = String(localized: "Questa settimana")
            } else {
                sectionTitle = String(localized: "Precedenti")
            }

            if groups[sectionTitle] == nil {
                order.append(sectionTitle)
            }
            groups[sectionTitle, default: []].append(document)
        }

        return order.map { (title: $0, documents: groups[$0] ?? []) }
    }

    private var expiringSoonDocument: ScannedDocument? {
        let now = Date()
        guard let horizon = Calendar.current.date(byAdding: .day, value: 14, to: now) else { return nil }

        return documents
            .filter { document in
                guard let expirationDate = document.expirationDate else { return false }
                return expirationDate > now && expirationDate <= horizon
            }
            .min { ($0.expirationDate ?? .distantFuture) < ($1.expirationDate ?? .distantFuture) }
    }

    private func delete(from group: [ScannedDocument], at offsets: IndexSet) {
        for index in offsets {
            let document = group[index]
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
                DocumentThumbnailView(document: document)

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
                Text(
                    String(
                        format: String(localized: "%@ · %d pagine"),
                        document.createdAt.formatted(date: .abbreviated, time: .omitted),
                        document.pageCount
                    )
                )
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
