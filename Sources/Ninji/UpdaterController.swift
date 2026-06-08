import Sparkle
import SwiftUI

/// Handles Sparkle framework integration for automatic updates
final class UpdaterController: NSObject, ObservableObject {
    static let shared = UpdaterController()
    
    private var updater: SPUUpdater!
    private var userDefaults: UserDefaults

    // App cast feed URL - GitHub Releases
    // Replace with your actual GitHub repo
    private let feedURL = URL(string: "https://github.com/BananabasB/ninji/releases/latest/download/appcast.xml")!
    
    override init() {
        // Use a custom UserDefaults suite for Sparkle to avoid conflicts
        userDefaults = UserDefaults(suiteName: "com.barnabasbodily.Ninji.sparkle") ?? .standard
        
        super.init()
        
        // Create the updater
        updater = SPUUpdater(
            source: SPUAppcastSource(appCastURL: feedURL),
            userDefaults: userDefaults,
            delegate: self
        )
    }
    
    /// Start the updater - call this when the app launches
    func start() {
        // Start checking for updates
        updater.start()
    }
    
    /// Manually check for updates
    func checkForUpdates() {
        updater.checkForUpdates()
    }
    
    /// Get the current version info
    var currentVersion: String? {
        // Get the current version from Info.plist
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

// MARK: - Sparkle Delegate

extension UpdaterController: SPUUpdaterDelegate {
    
    func updater(_ updater: SPUUpdater, willStartDownloadingUpdate update: SPUUpdate) {
        print("Starting download of update: \(update.version)")
    }
    
    func updater(_ updater: SPUUpdater, didDownloadUpdate update: SPUUpdate, at path: String) {
        print("Update downloaded to: \(path)")
    }
    
    func updater(_ updater: SPUUpdater, didFailToDownloadUpdateWithError error: Error) {
        print("Download failed: ", error.localizedDescription)
    }
    
    func updater(_ updater: SPUUpdater, didFailToInstallUpdateWithError error: Error) {
        print("Installation failed: ", error.localizedDescription)
    }
    
    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        print("No update found")
    }
    
    func updater(_ updater: SPUUpdater, foundUpdate update: SPUUpdate) {
        print("Update found: \(update.version)")
    }
}
