import SwiftUI

public struct HistoryView: View {
    @State private var viewModel: HistoryViewModel
    @State private var copiedId: UUID? = nil
    @State private var showClearConfirmation = false
    
    public init(viewModel: HistoryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Verlauf")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Spacer()
                
                if !viewModel.entries.isEmpty {
                    Button(action: {
                        showClearConfirmation = true
                    }) {
                        Label("Verlauf leeren", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red.opacity(0.1))
                    .confirmationDialog(
                        "Verlauf leeren?",
                        isPresented: $showClearConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Ja, alles leeren", role: .destructive) {
                            Task {
                                await viewModel.clear()
                            }
                        }
                        Button("Abbrechen", role: .cancel) {}
                    } message: {
                        Text("Möchtest du wirklich alle Transkriptionen aus dem Verlauf löschen? Dies kann nicht rückgängig gemacht werden.")
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 15)
            .padding(.bottom, 10)
            
            Divider()
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Verlauf durchsuchen...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.08))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            if viewModel.isLoading {
                Spacer()
                ProgressView("Verlauf wird geladen...")
                Spacer()
            } else if viewModel.errorMessage != nil {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                    Text(viewModel.errorMessage ?? "Ein Fehler ist aufgetreten.")
                        .font(.headline)
                }
                Spacer()
            } else if viewModel.filteredEntries.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: viewModel.searchText.isEmpty ? "clock" : "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(viewModel.searchText.isEmpty ? "Keine Transkriptionen im Verlauf" : "Keine Treffer für deine Suche")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredEntries) { entry in
                            VStack(alignment: .leading, spacing: 8) {
                                // Meta-Info
                                HStack {
                                    Text(formatter.string(from: entry.timestamp))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    Spacer()
                                    
                                    // Model Name Badge
                                    Text(displayName(for: entry.modelName))
                                        .font(.system(size: 10, weight: .semibold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundStyle(.blue)
                                        .cornerRadius(4)
                                }
                                
                                // Text Content
                                Text(entry.text)
                                    .font(.body)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Divider()
                                
                                // Actions for item
                                HStack {
                                    Spacer()
                                    
                                    Button(action: {
                                        viewModel.copy(text: entry.text)
                                        withAnimation {
                                            copiedId = entry.id
                                        }
                                        Task {
                                            try? await Task.sleep(for: .seconds(2))
                                            withAnimation {
                                                if copiedId == entry.id {
                                                    copiedId = nil
                                                }
                                            }
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: copiedId == entry.id ? "checkmark" : "paperclip")
                                                .foregroundStyle(copiedId == entry.id ? .green : .primary)
                                            Text(copiedId == entry.id ? "Kopiert!" : "Kopieren")
                                                .foregroundStyle(copiedId == entry.id ? .green : .primary)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(copiedId == entry.id ? .green.opacity(0.1) : .primary.opacity(0.05))
                                    
                                    Button(action: {
                                        Task {
                                            await viewModel.delete(id: entry.id)
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.red.opacity(0.05))
                                    .help("Eintrag löschen")
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.04))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(width: 520, height: 580)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            Task {
                await viewModel.load()
            }
        }
    }
    
    private func displayName(for modelName: String) -> String {
        switch modelName {
        case "base":
            return "Schnell"
        case "small":
            return "Ausgewogen"
        case "large-v3-turbo":
            return "Genau"
        default:
            return modelName
        }
    }
}
