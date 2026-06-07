import Foundation
import Network

class DiscordRPC {
    static let shared = DiscordRPC()
    
    private var lastPresence: [String: Any]?
    private var listener: NWListener?
    private let port: NWEndpoint.Port = 9090
    private let queue = DispatchQueue(label: "com.ninji.server", attributes: .concurrent)
    
    private var safePresence: [String: Any]? {
        get { queue.sync { lastPresence } }
        set { queue.async(flags: .barrier) { self.lastPresence = newValue } }
    }
    
    func startIfNeeded() {
        if UserDefaults.standard.bool(forKey: "enableDiscordRPC") {
            startServer()
        }
    }
    
    func updatePresence(title: String, game: String, author: String?, position: Double, length: Double, image: String?) {
        let now = Date().timeIntervalSince1970
        let startTimestamp = Int((now - position) * 1000)
        let endTimestamp = Int((now + (length - position)) * 1000)
        
        let presence: [String: Any] = [
            "details": title,
            "state": author ?? game,
            "author": author ?? "",
            "game": game,
            "image": image ?? "",
            "timestamps": [
                "start": startTimestamp,
                "end": endTimestamp
            ]
        ]
        
        self.safePresence = presence
        
        if listener == nil {
            startServer()
        }
    }
    
    func clearPresence() {
        self.safePresence = nil
    }
    
    private func startServer() {
        guard listener == nil else { return }
        
        guard let listener = try? NWListener(using: .tcp, on: port) else {
            print("Ninji Server: Failed to create listener on port \(port)")
            return
        }
        self.listener = listener
        
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Ninji Presence Server: Listening on port \(self.port)")
            case .failed(let error):
                print("Ninji Presence Server: Failed with error \(error)")
                self.listener = nil
            default:
                break
            }
        }
        
        listener.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }
        
        listener.start(queue: queue)
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, _, error in
            if error == nil {
                self?.sendResponse(to: connection)
            } else {
                connection.cancel()
            }
        }
    }
    
    private func sendResponse(to connection: NWConnection) {
        let presence = safePresence ?? [:]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: presence, options: []) else {
            connection.cancel()
            return
        }
        
        // Proper HTTP response with \r\n line endings
        let headers = [
            "HTTP/1.1 200 OK",
            "Content-Type: application/json",
            "Content-Length: \(jsonData.count)",
            "Access-Control-Allow-Origin: *",
            "Connection: close",
            "",
            ""
        ].joined(separator: "\r\n")
        
        var responseData = headers.data(using: .utf8) ?? Data()
        responseData.append(jsonData)
        
        connection.send(content: responseData, completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
}
