import Sparkle
import SwiftUI

/// Handles Sparkle framework integration for automatic updates
final class UpdaterController: NSObject, ObservableObject {
    static let shared = UpdaterController()
    
    private var updater: SPUUpdater!
    
    // App cast feed URL - GitHub Releases
    // Replace with your actual GitHub repo
    private let feedURL = URL(string: "https://github.com/BananabasB/ninji/releases/latest/download/appcast.xml")!
    
    override init() {
        super.init()
        
        // Create the updater - Sparkle 2.x uses SUAppcastSource
        let source = SUAppcastSource(appCastURL: feedURL)
        updater = SPUUpdater(source: source, delegate: self)
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

extension UpdaterController: SUUpdaterDelegate {
    
    // Update found
    func updater(_ updater: SUUpdater, foundUpdate update: SUUpdate) {
        print("Update found: \(update.version)")
    }
    
    // No update found
    func updaterDidNotFindUpdate(_ updater: SUUpdater) {
        print("No update found")
    }
    
    // Download failed
    func updater(_ updater: SUUpdater, failedToDownloadUpdate update: SUUpdate, withError error: Error) {
        print("Download failed: ", error.localizedDescription)
    }
    
    // Installation failed  
    func updater(_ updater: SUUpdater, failedToInstallUpdate update: SUUpdate, withError error: Error) {
        print("Installation failed: ", error.localizedDescription)
    }
}
