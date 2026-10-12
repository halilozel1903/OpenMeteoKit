import Foundation
import SwiftUI

/// Scenes used by CI to capture the README screenshots.
/// Launch with `-screenshot <scene>`; normal launches are unaffected and use the live API.
///
/// Every scene loads Istanbul's real forecast from the live Open-Meteo API, retrying a few times. There is no
/// fallback data: when the API cannot be reached, the scene never signals ready and the screenshot job fails
/// instead of committing anything that is not real.
enum ScreenshotScene: String {
    /// Apple Watch: the current conditions, today's high and low and the air quality.
    case current
    /// Apple Watch: the next hours as a list.
    case hourly
    /// iPhone: the Today screen with the current conditions, the hourly strip and the details.
    case today
    /// iPhone: the 7-day forecast.
    case week

    /// The scene this launch asked for. (Not `current`: that is the name of a scene.)
    static var requested: ScreenshotScene? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-screenshot"), arguments.indices.contains(index + 1) else {
            return nil
        }
        return ScreenshotScene(rawValue: arguments[index + 1])
    }
}

extension View {
    /// Tells scripts/screenshots.sh that the scene is on screen by writing `tmp/screenshot-ready` into the app
    /// container, once `isReady` is true and the frame had time to settle. Nothing animates in a screenshot scene,
    /// so the frame is final by then.
    func signalsScreenshotReady(_ scene: ScreenshotScene?, when isReady: Bool) -> some View {
        task(id: isReady) {
            guard let scene, isReady else { return }
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            let marker = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("screenshot-ready")
            try? scene.rawValue.write(to: marker, atomically: true, encoding: .utf8)
        }
    }
}
