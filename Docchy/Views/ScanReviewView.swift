//
//  ScanReviewView.swift
//  Docchy
//
//  Created by Vittorio Monfrecola on 12/07/2026.
//

import SwiftUI
import SwiftData

private enum AnalysisState {
    case analyzing
    case readable
    case unreadable
}

struct ScanReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State var pages: [UIImage]
    @State private var title: String = ""
    @State private var zoomedPageIndex: Int?

    @State private var analysisState: AnalysisState = .analyzing
    @State private var insight: DocumentInsight?
    @State private var reminderEnabled = false
    @State private var expirationDate = Date()
    @State private var dateWasAutoDetected = false

    var onSaved: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TextField("Nome documento", text: $title)
                        .font(.headline)
                        .padding(12)
                        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                        .padding(.top, 8)

                    MascotReactionCard(expression: mascotExpression, message: mascotMessage)
                        .padding(.horizontal)

                    ReminderSection(reminderEnabled: $reminderEnabled, expirationDate: $expirationDate)
                        .padding(.horizontal)

                    ForEach(pages.indices, id: \.self) { index in
                        VStack(spacing: 6) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: pages[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(.separator, lineWidth: 0.5)
                                    )
                                    .onTapGesture {
                                        zoomedPageIndex = index
                                    }

                                Button {
                                    pages.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.white, .black.opacity(0.6))
                                }
                                .padding(10)
                            }
                            .padding(.horizontal)

                            Text(
                                String(
                                    format: String(localized: "Pagina %d · tocca per ingrandire"),
                                    index + 1
                                )
                            )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Revisione")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") { save() }
                        .disabled(pages.isEmpty)
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { zoomedPageIndex != nil },
                set: { if !$0 { zoomedPageIndex = nil } }
            )) {
                if let index = zoomedPageIndex, pages.indices.contains(index) {
                    ZoomablePageView(image: pages[index])
                }
            }
            .task {
                await runAnalysis()
            }
        }
    }

    private var mascotExpression: MascotExpression {
        switch analysisState {
        case .analyzing: return .pensierosa
        case .readable: return dateWasAutoDetected ? .orologio : .felice
        case .unreadable: return .confusa
        }
    }

    private var mascotMessage: String {
        switch analysisState {
        case .analyzing:
            return String(localized: "Sto leggendo il documento...")
        case .readable:
            return dateWasAutoDetected
                ? String(localized: "Ho trovato una data di scadenza! Controlla il promemoria qui sotto.")
                : String(localized: "Testo riconosciuto! Potrai cercarlo in futuro.")
        case .unreadable:
            return String(localized: "Non riesco a leggere bene il testo: controlla che la foto sia a fuoco e ben illuminata.")
        }
    }

    private func runAnalysis() async {
        analysisState = .analyzing
        let result = await DocumentAnalyzer.analyze(pages: pages)
        insight = result
        analysisState = result.hasReadableText ? .readable : .unreadable

        if let detectedDate = DateDetector.detectExpirationDate(in: result.recognizedText) {
            expirationDate = detectedDate
            reminderEnabled = true
            dateWasAutoDetected = true
        }
    }

    private func save() {
        do {
            let fileName = try PDFBuilder.makePDF(from: pages)
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalTitle = trimmed.isEmpty
                ? String(
                    format: String(localized: "Documento del %@"),
                    Date().formatted(date: .abbreviated, time: .omitted)
                )
                : trimmed

            let document = ScannedDocument(
                title: finalTitle,
                pageCount: pages.count,
                fileName: fileName,
                recognizedText: insight?.recognizedText ?? "",
                expirationDate: reminderEnabled ? expirationDate : nil
            )
            modelContext.insert(document)
            onSaved()
            dismiss()

            if reminderEnabled {
                Task {
                    await ReminderScheduler.scheduleReminder(for: document)
                }
            }
        } catch {
            // In un'app di produzione: mostrare un alert all'utente
            print("Errore nel salvataggio del PDF: \(error)")
        }
    }
}

/// Sezione per impostare (o confermare, se rilevata automaticamente)
/// una data di scadenza con relativo promemoria locale.
private struct ReminderSection: View {
    @Binding var reminderEnabled: Bool
    @Binding var expirationDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $reminderEnabled) {
                Label("Promemoria scadenza", systemImage: "bell")
                    .font(.subheadline)
            }

            if reminderEnabled {
                DatePicker(
                    "Data di scadenza",
                    selection: $expirationDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .font(.subheadline)
            }
        }
        .padding(12)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
    }
}

/// Piccola "scheda" con la mascotte e un messaggio, tipo fumetto,
/// che reagisce all'esito dell'analisi OCR della scansione appena fatta.
private struct MascotReactionCard: View {
    let expression: MascotExpression
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            MascotView(expression: expression)
                .frame(width: 56, height: 46)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.25), value: message)
    }
}

/// Visualizzatore a schermo intero con zoom (pizzico o doppio tocco)
/// per controllare in dettaglio la qualita' di una pagina scansionata.
private struct ZoomablePageView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = max(1, min(4, lastScale * value))
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale == 1 {
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            },
                        DragGesture()
                            .onChanged { value in
                                guard scale > 1 else { return }
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                )
                .onTapGesture(count: 2) {
                    withAnimation {
                        if scale > 1 {
                            scale = 1
                            lastScale = 1
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 2
                            lastScale = 2
                        }
                    }
                }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white, .black.opacity(0.6))
            }
            .padding()
        }
    }
}
