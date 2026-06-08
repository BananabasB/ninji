import Sparkle
import SwiftUI

/// Handles Sparkle framework integration for automatic updates
final class UpdaterController {
    static let shared = UpdaterController()
    
    private let updaterController: SPUStandardUpdaterController
    private let userDefaults: UserDefaults
    
    // App cast feed URL - GitHub Releases
    // Replace with your actual GitHub repo
    private let feedURL = URL(string: "https://github.com/BananabasB/ninji/releases/latest/download/appcast.xml")!
    
    private init() {
        // Use a custom UserDefaults suite for Sparkle to avoid conflicts
        userDefaults = UserDefaults(suiteName: "com.barnabasbodily.Ninji.sparkle") ?? .standard
        
        // Configure updater
        let configuration = SPUStandardUpdaterConfiguration(
            appCastURL: feedURL,
            userDefaults: userDefaults
        )
        
        // Display settings
        configuration.automaticallyChecksForUpdates = true
        configuration.automaticallyDownloadsUpdates = false // Let users choose
        configuration.showsUIForAutomaticCheckOnLaunch = true
        configuration.prefersSparkleHostForAutomaticUpdates = true
        
        // For unsigned apps (no Developer Program), allow unsigned updates
        // ⚠️ Security warning: This bypasses signature verification!
        // Only use this for testing without Developer Program
        configuration.ignoresSystemProxySettings = false
        configuration.requiresSignatureVerification = false
        
        // Create the updater controller
        updaterController = SPUStandardUpdaterController(
            configuration: configuration,
            delegate: nil,
            userDriverDelegate: nil
        )
    }
    
    /// Start the updater - call this when the app launches
    func start() {
        updaterController.start()
    }
    
    /// Manually check for updates
    func checkForUpdates() {
        updaterController.checkForUpdates()
    }
    
    /// Get the current version info
    var currentVersion: String? {
        updaterController.updater.versionForUpdater
    }
}

/// Legacy AppDelegate wrapper for Sparkle compatibility
class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    func updater(_ updater: SPUUpdater, performing action: SPUUpdaterAction) {
        // Handle different update actions
        switch performing {
        case .download:
            print("Starting download...")
        case .install:
            print("Starting installation...")
        default:
            break
        }
    }
    
    func updater(_ updater: SPUUpdater, failedToDownloadUpdateWithError error: Error) {
        print("Download failed: ", error.localizedDescription)
    }
    
    func updater(_ updater: SPUUpdater, failedToInstallUpdateWithError error: Error) {
        print("Installation failed: ", error.localizedDescription)
    }
    
    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        print("No update found")
    }
    
    func updaterFoundUpdate(_ updater: SPUUpdater, update: SPUUpdate) {
        print("Update found: ", update.version)
    }
}
