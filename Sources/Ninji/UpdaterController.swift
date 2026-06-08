import Sparkle
import SwiftUI

/// Handles Sparkle framework integration for automatic updates
final class UpdaterController: NSObject, ObservableObject {
    static let shared = UpdaterController()

    // App cast feed URL - GitHub Releases
    // Replace with your actual GitHub repo
    private let feedURL = URL(string: "https://github.com/BananabasB/ninji/releases/latest/download/appcast.xml")!

    // Lazily create the standard updater controller so `self` can be used as the delegate
    private lazy var updaterController: SPUStandardUpdaterController = {
        SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: self, userDriverDelegate: nil)
    }()

    override init() {
        super.init()
    }

    /// Start the updater - call this when the app launches
    func start() {
        // Start the Sparkle updater's internal scheduling
        updaterController.startUpdater()
    }

    /// Manually check for updates
    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    /// Get the current version info
    var currentVersion: String? {
        // Get the current version from Info.plist
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

// MARK: - Sparkle Delegate

extension UpdaterController: SPUUpdaterDelegate {

    // Provide the feed URL to Sparkle programmatically
    func feedURLString(for updater: SPUUpdater) -> String? {
        feedURL.absoluteString
    }

    // Called when no update is found
    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        print("No update found")
    }

}
