import OpenMeteoKit
import OpenMeteoUI
import SwiftUI

/// Search for a place by name with Open-Meteo's geocoding API, as you type. Choosing one shows its weather.
struct SearchScreen: View {
    let onSelect: (Location) -> Void

    @Environment(WeatherStore.self) private var store
    @State private var query = ""
    @State private var results: [Location] = []
    @State private var message: String?

    var body: some View {
        NavigationStack {
            List {
                if let message {
                    Text(message)
                        .foregroundStyle(.secondary)
                }
                ForEach(results) { location in
                    Button {
                        onSelect(location)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(location.name)
                                .font(.headline)
                            Text(location.regionDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                Section {
                    OpenMeteoAttributionView()
                }
            }
            .navigationTitle("Search")
            // iOS 26 bars are transparent by default; keep the title readable over the list.
            .toolbarBackground(Color(red: 0.08, green: 0.10, blue: 0.16), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "City or postal code")
            .task(id: query) {
                await search()
            }
        }
    }

    private func search() async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 2 else {
            results = []
            message = nil
            return
        }
        // Wait until typing pauses.
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        do {
            let found = try await store.client.searchLocations(text, count: 20)
            guard !Task.isCancelled else { return }
            results = found
            message = found.isEmpty ? "No places match \u{201C}\(text)\u{201D}." : nil
        } catch {
            guard !Task.isCancelled else { return }
            results = []
            message = error.localizedDescription
        }
    }
}
