import OpenMeteoKit
import OpenMeteoUI
import SwiftUI

@main
struct BreezePhoneApp: App {
    @State private var store: WeatherStore

    init() {
        _store = State(initialValue: WeatherStore.make(for: ScreenshotScene.requested))
    }

    var body: some Scene {
        WindowGroup {
            PhoneRootView(scene: ScreenshotScene.requested)
                .environment(store)
                .preferredColorScheme(.dark)
        }
    }
}

/// Four tabs: today, the week, air quality and search. A screenshot scene opens its tab.
struct PhoneRootView: View {
    enum Tab: Hashable {
        case today
        case week
        case air
        case search
    }

    let scene: ScreenshotScene?

    @Environment(WeatherStore.self) private var store
    @State private var tab: Tab

    init(scene: ScreenshotScene?) {
        self.scene = scene
        _tab = State(initialValue: scene == .week ? .week : .today)
    }

    var body: some View {
        TabView(selection: $tab) {
            TodayScreen()
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(Tab.today)
            WeekScreen()
                .tabItem { Label("Week", systemImage: "calendar") }
                .tag(Tab.week)
            AirQualityScreen()
                .tabItem { Label("Air", systemImage: "aqi.medium") }
                .tag(Tab.air)
            SearchScreen { location in
                tab = .today
                Task { await store.select(location) }
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
            .tag(Tab.search)
        }
        .task {
            if store.forecast == nil {
                await store.load()
            }
        }
        .signalsScreenshotReady(scene, when: store.phase == .loaded)
    }
}

/// The sky of the current conditions behind a whole screen.
struct PhoneSky: View {
    @Environment(WeatherStore.self) private var store

    var body: some View {
        WeatherBackground(code: store.current?.weatherCode, isDay: store.current?.isDay ?? true)
            .ignoresSafeArea()
    }
}

/// A translucent card with a small caption, the way the system Weather app groups its sections.
struct WeatherCard<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content

    init(_ title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title.uppercased(), systemImage: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.65))
            Divider()
                .overlay(Color.white.opacity(0.25))
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

/// A spinner while loading, or the error with a retry button.
struct PhoneLoadingView: View {
    @Environment(WeatherStore.self) private var store

    var body: some View {
        Group {
            if case let .failed(message) = store.phase {
                ContentUnavailableView {
                    Label("No Forecast", systemImage: "icloud.slash")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again") {
                        Task { await store.load() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ProgressView()
                    .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
