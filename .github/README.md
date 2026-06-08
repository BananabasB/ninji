# GitHub Actions for Ninji

This directory contains GitHub Actions workflows for building, testing, and releasing Ninji.

## Available Workflows

### 🚀 Release Workflow (`.github/workflows/release.yml`)

**Trigger:** Push to tags matching `v*` pattern (e.g., `v1.0.0`)

**What it does:**
- Builds the macOS app in Release configuration
- Creates a signed ZIP archive
- Generates appcast.xml for Sparkle updates
- Uploads assets to GitHub Release
- Allows Sparkle to detect and download updates

## ✅ How to Use

### 1. Create a New Release

```bash
# Bump version and create tag
git tag v1.0.0
git push origin v1.0.0
```

The workflow will automatically:
1. Build and archive the app
2. Generate appcast.xml
3. Upload to GitHub Release
4. Sparkle will automatically detect the new version

### 2. Configure Sparkle Feed URL

The app is already configured to use GitHub Releases:
```swift
// In UpdaterController.swift
private let feedURL = URL(string: "https://github.com/BananabasB/ninji/releases/latest/download/appcast.xml")!
```

### 3. Development Builds

For testing without tagging:
```bash
# Build locally
swift build -c release

# Or use the workflow manually
# (customize the workflow to trigger on push to develop branch)
```

## 🔧 Configuration Files

### ExportOptions.plist
Configured for development builds. For production distribution:
- Update `method` to `app-store` or `developer-id`
- Add your `teamID`
- Configure signing certificates

### AppCast Generation
The workflow automatically:
- Creates appcast.xml with proper Sparkle namespaces
- Includes version information
- Links to the GitHub Release download URL
- Provides release notes from commit messages

## 🛡️ Code Signing (Optional)

For signed releases, you'll need:

1. **Developer ID Application certificate** from Apple
2. **ExportOptions.plist** updates:
   ```xml
   <key>method</key>
   <string>developer-id</string>
   <key>teamID</key>
   <string>YOUR_TEAM_ID</string>
   <key>signingCertificate</key>
   <string>Developer ID Application: Your Name</string>
   ```

3. **Notarization** (macOS Gatekeeper requirement)
   Add notarization steps to the workflow using `notarytool`

## 📋 Requirements

- **macOS 14+** runner (Xcode 15+)
- **Swift 5.9+**
- **GitHub Releases** enabled for the repository

## 🔄 Customization

### Change Trigger
Modify the `on:` section in `release.yml` to trigger on different events:
```yaml
on:
  push:
    branches: [main]  # Trigger on every push to main
  # or
  workflow_dispatch:   # Allow manual triggering
```

### Build Configuration
Adjust build settings in the workflow:
- Add environment variables
- Configure code signing
- Customize build flags

## ⚠️ Troubleshooting

### Workflow Fails
- Check macOS runner availability
- Verify Xcode version compatibility
- Ensure Sparkle dependencies are resolvable

### Sparkle Updates Not Working
- Verify appcast.xml URL is accessible
- Check appcast.xml has valid Sparkle signing
- Ensure version numbers are increasing

### Signing Issues
- Verify certificate in Keychain
- Check provisioning profiles
- Validate teamID in ExportOptions.plist

## 📚 Resources

- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [GitHub Actions macOS](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners#standard-github-hosted-runners-for-public-repositories)
- [Xcodebuild Documentation](https://developer.apple.com/library/archive/technotes/tn2339/_index.html)
