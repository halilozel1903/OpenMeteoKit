import OpenMeteoKit
import OpenMeteoUI
import SwiftUI

@main
struct BreezeWatchApp: App {
    @State private var store: WeatherStore

    init() {
        _store = State(initialValue: WeatherStore.make(for: ScreenshotScene.requested))
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView(scene: ScreenshotScene.requested)
                .environment(store)
        }
    }
}

/// Vertically paged screens: now, the next hours and the week. A screenshot launch shows one screen on its own.
struct WatchRootView: View {
    let scene: ScreenshotScene?

    @Environment(WeatherStore.self) private var store

    var body: some View {
        Group {
            switch scene {
            case .current:
                WatchCurrentView()
            case .hourly:
                WatchHourlyView()
            default:
                TabView {
                    WatchCurrentView()
                    WatchHourlyView()
                    WatchWeekView()
                }
                .tabViewStyle(.verticalPage)
            }
        }
        .task {
            if store.forecast == nil {
                await store.load()
            }
        }
        .signalsScreenshotReady(scene, when: store.phase == .loaded)
    }
}

/// The sky of the current conditions, or a neutral night sky before they load.
struct WatchSky: View {
    let current: CurrentWeather?

    var body: some View {
        WeatherBackground(code: current?.weatherCode, isDay: current?.isDay ?? false)
            .opacity(0.85)
            .ignoresSafeArea()
    }
}

/// A spinner while loading, or the error with a retry button.
struct WatchLoadingView: View {
    @Environment(WeatherStore.self) private var store

    var body: some View {
        if case let .failed(message) = store.phase {
            ScrollView {
                VStack(spacing: 8) {
                    Image(systemName: "icloud.slash")
                        .font(.title2)
                    Text(message)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        Task { await store.load() }
                    }
                }
            }
        } else {
            ProgressView()
        }
    }
}
