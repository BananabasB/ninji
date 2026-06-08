import SwiftUI
import WebKit

private let sharedDataStore = WKWebsiteDataStore.default()
private let safariUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"
private let sidebarLogoNudgeCSS = """
._1lg72ai0 { margin-top: 28px !important; }
.c-header_corpLogo { padding-left: 100px; background-color: #E60012; }
"""

private func makeInjectedStyleScript() -> WKUserScript {
    let source = """
    (() => {
        const style = document.createElement('style');
        style.textContent = \(sidebarLogoNudgeCSS.debugDescription);
        document.documentElement.appendChild(style);
    })();
    """

    return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
}

private func makeInjectedResourceScript(named resourceName: String, fileExtension: String, injectionTime: WKUserScriptInjectionTime) -> WKUserScript? {
    // Try bundle resource first
    if let url = Bundle.main.url(forResource: resourceName, withExtension: fileExtension),
       let source = try? String(contentsOf: url, encoding: .utf8) {
        return WKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: false)
    }

    // Fallback: try a resource at Bundle.resourceURL (e.g., themes/injector.js when bundled in a subdirectory)
    if let resourceBase = Bundle.main.resourceURL {
        let candidate = resourceBase.appendingPathComponent("\(resourceName).\(fileExtension)")
        if FileManager.default.fileExists(atPath: candidate.path),
           let source = try? String(contentsOf: candidate, encoding: .utf8) {
            return WKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: false)
        }

        // Also try themes subdirectory
        let themed = resourceBase.appendingPathComponent("themes/")
            .appendingPathComponent("\(resourceName).\(fileExtension)")
        if FileManager.default.fileExists(atPath: themed.path),
           let source = try? String(contentsOf: themed, encoding: .utf8) {
            return WKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: false)
        }
    }

    // Development fallback: try loading from current working directory (useful when running from source)
    let cwdCandidate = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent("themes/")
        .appendingPathComponent("\(resourceName).\(fileExtension)")
    if FileManager.default.fileExists(atPath: cwdCandidate.path),
       let source = try? String(contentsOf: cwdCandidate, encoding: .utf8) {
        return WKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: false)
    }

    return nil
}

private func enableDeveloperExtras(on configuration: WKWebViewConfiguration) {
    configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
}

private func jsonSafeValue(_ value: Any) -> Any {
    switch value {
    case let string as String:
        return string
    case let number as NSNumber:
        return number
    case let bool as Bool:
        return bool
    case let date as Date:
        return ISO8601DateFormatter().string(from: date)
    case let url as URL:
        return url.absoluteString
    case let data as Data:
        return data.base64EncodedString()
    case let array as [Any]:
        return array.map(jsonSafeValue)
    case let dictionary as [String: Any]:
        var result: [String: Any] = [:]
        for (key, item) in dictionary {
            result[key] = jsonSafeValue(item)
        }
        return result
    case let dictionary as [AnyHashable: Any]:
        var result: [String: Any] = [:]
        for (key, item) in dictionary {
            result[String(describing: key)] = jsonSafeValue(item)
        }
        return result
    case is NSNull:
        return NSNull()
    default:
        return String(describing: value)
    }
}

private enum TrackLog {
    private static let logURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".ninji")
        .appendingPathComponent("track.log")

    static func append(data trackData: [String: Any]) {
        let directoryURL = logURL.deletingLastPathComponent()

        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            print("TRACK LOG: failed to create directory at \(directoryURL.path): \(error)")
            return
        }

        let record: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "track": trackData.mapValues(jsonSafeValue)
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: record, options: []) else {
            print("TRACK LOG: failed to encode JSON record")
            return
        }

        var data = jsonData
        data.append(0x0A)

        if !FileManager.default.fileExists(atPath: logURL.path) {
            FileManager.default.createFile(atPath: logURL.path, contents: nil)
        }

        do {
            let handle = try FileHandle(forWritingTo: logURL)
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
            try handle.close()
        } catch {
            print("TRACK LOG: failed to append to \(logURL.path): \(error)")
        }
    }
}

final class PlaybackManager {
    static let shared = PlaybackManager()
    
    struct State {
        let name: String
        let game: String
        let author: String?
        let image: String?
        var position: Double
        let length: Double
        let isPlaying: Bool
        var lastUpdate: Date
    }
    
    private var state: State?
    private var timer: Timer?
    
    func update(with body: [String: Any]) {
        let name = body["name"] as? String ?? "Unknown"
        let game = body["game"] as? String ?? "Unknown"
        let author = body["author"] as? String
        let image = body["image"] as? String
        let position = body["position"] as? Double ?? 0
        let length = body["length"] as? Double ?? 0
        let isPlaying = body["isPlaying"] as? Bool ?? false
        
        state = State(
            name: name,
            game: game,
            author: author,
            image: image,
            position: position,
            length: length,
            isPlaying: isPlaying,
            lastUpdate: Date()
        )
        
        if UserDefaults.standard.bool(forKey: "enableLogging") {
            TrackLog.append(data: body)
        }

        if UserDefaults.standard.bool(forKey: "enableDiscordRPC") {
            if isPlaying {
                print("SWIFT: Updating Discord Presence for [\(name)]")
                DiscordRPC.shared.updatePresence(
                    title: name,
                    game: game,
                    author: author,
                    position: position,
                    length: length,
                    image: image
                )
            } else {
                print("SWIFT: Clearing Discord Presence (not playing)")
                DiscordRPC.shared.clearPresence()
            }
        } else {
            print("SWIFT: Discord RPC disabled in settings")
            DiscordRPC.shared.clearPresence()
        }

        startTimerIfNeeded()
    }
    
    private func startTimerIfNeeded() {
        guard timer == nil else { return }
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
    
    private func tick() {
        guard var currentState = state, currentState.isPlaying else { return }
        
        let now = Date()
        let timeSinceUpdate = now.timeIntervalSince(currentState.lastUpdate)
        
        // If JS hasn't updated in > 1.2s, it's likely throttled (JS polls at 1s)
        if timeSinceUpdate > 1.5 {
            let estimatedPosition = min(currentState.position + timeSinceUpdate, currentState.length)
            
            var data: [String: Any] = [
                "name": currentState.name,
                "game": currentState.game,
                "position": estimatedPosition,
                "length": currentState.length,
                "isPlaying": true,
                "isEstimated": true
            ]
            
            if let author = currentState.author { data["author"] = author }
            if let image = currentState.image { data["image"] = image }
            
            if UserDefaults.standard.bool(forKey: "enableLogging") {
                TrackLog.append(data: data)
            }

            if UserDefaults.standard.bool(forKey: "enableDiscordRPC") {
                DiscordRPC.shared.updatePresence(
                    title: currentState.name,
                    game: currentState.game,
                    author: currentState.author,
                    position: estimatedPosition,
                    length: currentState.length,
                    image: currentState.image
                )
            }
            
            // Update local state to continue from this estimation
            currentState.position = estimatedPosition
            currentState.lastUpdate = now
            state = currentState
        }
    }
}


final class WebViewManager: NSObject, WKScriptMessageHandler {
    static let shared = WebViewManager()
    
    let webView: WKWebView
    private var hasLoadedInitialURL = false
    
    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = sharedDataStore
        enableDeveloperExtras(on: configuration)
        configuration.userContentController.addUserScript(makeInjectedStyleScript())
        
        // Add a console.log wrapper to pipe logs to Swift
        let logScript = WKUserScript(source: """
            console.log = (function(oldLog) {
                return function() {
                    let args = Array.from(arguments).map(v => typeof v === 'object' ? JSON.stringify(v) : v);
                    window.webkit.messageHandlers.logHandler.postMessage(args.join(' '));
                    oldLog.apply(console, arguments);
                }
            })(console.log);
            console.error = (function(oldError) {
                return function() {
                    let args = Array.from(arguments).map(v => typeof v === 'object' ? JSON.stringify(v) : v);
                    window.webkit.messageHandlers.logHandler.postMessage('ERROR: ' + args.join(' '));
                    oldError.apply(console, arguments);
                }
            })(console.error);
        """, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(logScript)

        if let trackObserverScript = makeInjectedResourceScript(named: "TrackObserver", fileExtension: "js", injectionTime: .atDocumentEnd) {
            configuration.userContentController.addUserScript(trackObserverScript)
        }

        // Attempt to inject themes/injector.js (try bundled resource first, then common runtime paths)
        if let injectorScript = makeInjectedResourceScript(named: "injector", fileExtension: "js", injectionTime: .atDocumentEnd) {
            configuration.userContentController.addUserScript(injectorScript)
        } else {
            // Try a few runtime locations useful during development
            let fm = FileManager.default
            var candidates: [String] = []
            candidates.append(fm.currentDirectoryPath + "/themes/injector.js")
            candidates.append(fm.currentDirectoryPath + "/../themes/injector.js")
            if let res = Bundle.main.resourceURL?.appendingPathComponent("themes/injector.js").path {
                candidates.append(res)
            }
            candidates.append(Bundle.main.bundlePath + "/Contents/Resources/themes/injector.js")

            var injected = false
            for path in candidates {
                if fm.fileExists(atPath: path), let src = try? String(contentsOfFile: path, encoding: .utf8) {
                    let userScript = WKUserScript(source: src, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
                    configuration.userContentController.addUserScript(userScript)
                    print("Injected themes/injector.js from: \(path)")
                    injected = true
                    break
                }
            }

            if !injected {
                print("theme-injector: injector.js not found in bundle or common runtime paths")
            }
        }

        // Inject a lightweight presence-check script that logs to the webview console so it's clear whether
        // the injector loaded at runtime. This always runs and helps debugging when the injector resource
        // isn't found in the bundle or cwd.
        let themePresenceScript = WKUserScript(source: """
            (function(){
                try {
                    console.log('theme-loader: checking for theme injector...');
                    if (window.__themeInjector) {
                        console.log('theme-loader: __themeInjector present');
                    } else {
                        console.log('theme-loader: __themeInjector missing');
                    }
                } catch (e) { console.log('theme-loader error', e); }
            })();
        """, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(themePresenceScript)
        
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        
        configuration.userContentController.add(self, name: "trackObserver")
        configuration.userContentController.add(self, name: "logHandler")
        
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = safariUserAgent
        webView.setValue(false, forKey: "drawsBackground")
        if #available(macOS 13.3, *) {
            webView.isInspectable = true
        }
    }
    
    func loadIfNeeded(url: URL) {
        guard !hasLoadedInitialURL else { return }
        webView.load(URLRequest(url: url))
        hasLoadedInitialURL = true
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "logHandler", let body = message.body as? String {
            print("JS LOG: \(body)")
        } else if message.name == "trackObserver", let body = message.body as? [String: Any] {
            let name = body["name"] as? String ?? "Unknown"
            let isPlaying = body["isPlaying"] as? Bool ?? false
            
            if name != "TEST_HEARTBEAT" {
                print("SWIFT: Received track update [\(name)], isPlaying: \(isPlaying)")
                PlaybackManager.shared.update(with: body)
            }
        }
    }
}

struct WebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        container.autoresizesSubviews = true

        let webView = WebViewManager.shared.webView
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.autoresizingMask = [.width, .height]

        // Remove from old superview if any
        webView.removeFromSuperview()
        
        container.addSubview(webView)
        webView.frame = container.bounds

        context.coordinator.mainWebView = webView
        context.coordinator.container = container

        WebViewManager.shared.loadIfNeeded(url: url)

        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebView
        weak var mainWebView: WKWebView?
        weak var container: NSView?
        var authWebView: WKWebView?
        var hasSeenInitialAuthLoad = false

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url, let host = url.host else {
                decisionHandler(.cancel)
                return
            }

            print("NAV [\(webView == mainWebView ? "main" : "auth")]: \(url.absoluteString)")

            // If auth webview lands on music.nintendo.com, login is done
            if webView == authWebView && host == "music.nintendo.com" {
                decisionHandler(.cancel)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.dismissAuthWebView()
                    self.mainWebView?.load(URLRequest(url: URL(string: "https://music.nintendo.com")!))
                }
                return
            }

            // Intercept authorize with prompt=consent in auth webview — login just completed
            if webView == authWebView && host.hasSuffix("nintendo.com") && url.path.contains("/connect/1.0.0/authorize") {
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                let prompt = components?.queryItems?.first(where: { $0.name == "prompt" })?.value
                if prompt != "none" {
                    if !hasSeenInitialAuthLoad {
                        hasSeenInitialAuthLoad = true
                        decisionHandler(.allow)
                        return
                    }

                    decisionHandler(.allow)
                    // Give it a moment to set cookies then reload main
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.dismissAuthWebView()
                        self.mainWebView?.load(URLRequest(url: URL(string: "https://music.nintendo.com")!))
                    }
                    return
                }
            }

            let allowedHosts = [
                "music.nintendo.com",
                "nintendo.com",
                "nintendo.net",
                "google.com",
                "gstatic.com"
            ]

            if allowedHosts.contains(where: { host == $0 || host.hasSuffix("." + $0) }) {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
            }
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            guard let container = container else { return nil }

            configuration.websiteDataStore = sharedDataStore
            enableDeveloperExtras(on: configuration)
            configuration.userContentController.addUserScript(makeInjectedStyleScript())

            let authView = WKWebView(frame: container.bounds, configuration: configuration)
            authView.navigationDelegate = self
            authView.uiDelegate = self
            authView.customUserAgent = safariUserAgent
            authView.autoresizingMask = [.width, .height]
            if #available(macOS 13.3, *) {
                authView.isInspectable = true
            }

            container.addSubview(authView)
            authView.frame = container.bounds
            authWebView = authView

            return authView
        }

        func dismissAuthWebView() {
            authWebView?.removeFromSuperview()
            authWebView = nil
        }
    }
}
