//
//  AssistantView.swift
//  Docchy
//
//  Created by Vittorio Monfrecola on 12/07/2026.
//


import SwiftUI

private struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
    let expression: MascotExpression?
}

struct AssistantView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(
            isUser: false,
            text: String(localized: "Ciao, sono Docchy! Chiedimi come funziona una qualsiasi parte dell'app."),
            expression: .felice
        )
    ]

    private let suggestedQuestions = [
        String(localized: "Come scansiono un documento?"),
        String(localized: "Come funzionano i promemoria?"),
        String(localized: "I miei dati vengono caricati online?")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let last = messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                if messages.count <= 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestedQuestions, id: \.self) { question in
                                Button {
                                    ask(question)
                                } label: {
                                    Text(question)
                                        .font(.footnote)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(.fill.tertiary, in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }

                HStack(spacing: 10) {
                    TextField("Fai una domanda...", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { ask(inputText) }

                    Button {
                        ask(inputText)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
            }
            .navigationTitle("Chiedi a Docchy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
    }

    private func ask(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(ChatMessage(isUser: true, text: trimmed, expression: nil))
        inputText = ""

        if let match = HelpAssistant.bestMatch(for: trimmed) {
            messages.append(ChatMessage(isUser: false, text: match.answer, expression: .felice))
        } else {
            messages.append(ChatMessage(
                isUser: false,
                text: String(localized: "Non sono sicura di aver capito. Prova a chiedermi di scansione, rinomina, esportazione, promemoria, blocco Face ID o ricerca."),
                expression: .confusa
            ))
        }
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 40)
                Text(message.text)
                    .padding(10)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            } else {
                MascotView(expression: message.expression ?? .neutral)
                    .frame(width: 40, height: 34)

                Text(message.text)
                    .padding(10)
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 14))
                Spacer(minLength: 40)
            }
        }
    }
}
