<picture>
  <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/BananabasB/ninji/master/assets/Ninji%20Exports/Ninji-iOS-Default-1024x1024@1x.png" type="image/png">
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/BananabasB/ninji/master/assets/Ninji%20Exports/Ninji-iOS-Dark-1024x1024@1x.png" type="image/png">
  <img src="https://raw.githubusercontent.com/BananabasB/ninji/master/assets/Ninji%20Exports/Ninji-iOS-Default-1024x1024@1x.png" alt="Ninji" width="80" height="80">
</picture>

# Ninji

Ninji is a lightweight macOS desktop wrapper for Nintendo Music.

## Features

- Native WebView rendering
- Small filesize
- Theme support — coming soon
- Discord RPC support — coming soon

## Requirements

- macOS 12 or later
- Swift 5.9 or later

## Build

```sh
swift build
swift run
```

## Xcode

- Open `Ninji.xcodeproj` in Xcode to build and run the app target directly.
- The app target uses `Ninji.icon` for the bundle icon.

## Project

- `Package.swift` defines the Swift package and app target.
- `Sources/Ninji/WebView.swift` contains the native WebView implementation.
- `Sources/Ninji/DiscordRPC.swift` is the current Discord RPC bridge stub.
