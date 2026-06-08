import Sparkle
import SwiftUI

/// Handles Sparkle framework integration for automatic updates
final class UpdaterController: NSObject, ObservableObject {
    static let shared = UpdaterController()
    
    private let updaterController: SPUStandardUpdaterController
    
    // App cast feed URL - GitHub Releases
    // Replace with your actual GitHub repo
    private let feedURL = URL(string: "https://github.com/BananabasB/ninji/releases/latest/download/appcast.xml")!
    
    override init() {
        // Configure updater using Sparkle 2.x SPUStandardUpdaterConfiguration
        let configuration = SPUStandardUpdaterConfiguration()
        configuration.appCastURL = feedURL
        
        // For unsigned apps (no Developer Program)
        configuration.requiresSignatureVerification = false
        
        // UI settings
        configuration.automaticallyChecksForUpdates = true
        configuration.automaticallyDownloadsUpdates = false
        configuration.showsUIForAutomaticCheckOnLaunch = true
        
        // Create the updater controller
        updaterController = SPUStandardUpdaterController(configuration: configuration, delegate: self)
        
        super.init()
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
        // Get the current version from Info.plist
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

// MARK: - Sparkle Delegate

extension UpdaterController: SPUStandardUpdaterControllerDelegate {
    
    // Update found
    func updaterController(_ controller: SPUStandardUpdaterController, didFindUpdate update: SPUUpdate) {
        print("Update found: \(update.version)")
    }
    
    // No update found
    func updaterControllerDidNotFindUpdate(_ controller: SPUStandardUpdaterController) {
        print("No update found")
    }
    
    // Download failed
    func updaterController(_ controller: SPUStandardUpdaterController, failedToDownloadUpdate update: SPUUpdate, error: Error) {
        print("Download failed: ", error.localizedDescription)
    }
    
    // Installation failed  
    func updaterController(_ controller: SPUStandardUpdaterController, failedToInstallUpdate update: SPUUpdate, error: Error) {
        print("Installation failed: ", error.localizedDescription)
    }
    
    // Optional: user wants to install after download
    func updaterControllerDidFinishDownloadingUpdate(_ controller: SPUStandardUpdaterController) {
        print("Update downloaded, ready to install")
    }
}
