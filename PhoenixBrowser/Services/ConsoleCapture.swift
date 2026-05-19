import Foundation
import WebKit

struct ConsoleMessage: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: Level
    let text: String
    let source: String?

    enum Level: String {
        case log, warn, error, info, debug
        var color: String {
            switch self {
            case .log, .debug: return "secondary"
            case .info: return "blue"
            case .warn: return "orange"
            case .error: return "red"
            }
        }
    }
}

struct NetworkEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let method: String
    let url: String
    let status: Int?
    let mimeType: String?
    let size: Int64?
    let duration: TimeInterval?
}

final class DevToolsManager: ObservableObject {
    static let shared = DevToolsManager()

    @Published var consoleMessages: [ConsoleMessage] = []
    @Published var networkEntries: [NetworkEntry] = []
    @Published var isInspectorOpen = false

    /// JS to inject into pages that captures console + network + performance
    var captureScript: String {
        """
        (function() {
            if (window.__phoenixDevToolsInjected) return;
            window.__phoenixDevToolsInjected = true;

            // Console capture
            const origLog = console.log;
            const origWarn = console.warn;
            const origError = console.error;
            const origInfo = console.info;
            const origDebug = console.debug;

            function capture(level, args) {
                const text = Array.from(args).map(a => {
                    try { return typeof a === 'object' ? JSON.stringify(a, null, 2) : String(a); }
                    catch(e) { return String(a); }
                }).join(' ');
                window.webkit.messageHandlers.phoenixConsole.postMessage({
                    level: level,
                    text: text,
                    source: window.location.href
                });
            }

            console.log = function() { capture('log', arguments); origLog.apply(console, arguments); };
            console.warn = function() { capture('warn', arguments); origWarn.apply(console, arguments); };
            console.error = function() { capture('error', arguments); origError.apply(console, arguments); };
            console.info = function() { capture('info', arguments); origInfo.apply(console, arguments); };
            console.debug = function() { capture('debug', arguments); origDebug.apply(console, arguments); };

            // Capture unhandled errors
            window.addEventListener('error', function(e) {
                capture('error', [e.message + ' at ' + e.filename + ':' + e.lineno]);
            });

            window.addEventListener('unhandledrejection', function(e) {
                capture('error', ['Unhandled Promise: ' + e.reason]);
            });

            // Network capture via PerformanceObserver
            if (window.PerformanceObserver) {
                const observer = new PerformanceObserver(function(list) {
                    list.getEntries().forEach(function(entry) {
                        if (entry.entryType === 'resource') {
                            window.webkit.messageHandlers.phoenixNetwork.postMessage({
                                url: entry.name,
                                duration: Math.round(entry.duration),
                                size: entry.transferSize || 0,
                                type: entry.initiatorType
                            });
                        }
                    });
                });
                observer.observe({ entryTypes: ['resource'] });
            }
        })();
        """
    }

    func addConsoleMessage(level: String, text: String, source: String?) {
        let msg = ConsoleMessage(
            timestamp: Date(),
            level: ConsoleMessage.Level(rawValue: level) ?? .log,
            text: text,
            source: source
        )
        DispatchQueue.main.async {
            self.consoleMessages.insert(msg, at: 0)
            if self.consoleMessages.count > 500 {
                self.consoleMessages.removeLast()
            }
        }
    }

    func addNetworkEntry(url: String, duration: Int, size: Int64, type: String) {
        let entry = NetworkEntry(
            timestamp: Date(),
            method: "GET",
            url: url,
            status: 200,
            mimeType: type,
            size: size,
            duration: TimeInterval(duration) / 1000.0
        )
        DispatchQueue.main.async {
            self.networkEntries.insert(entry, at: 0)
            if self.networkEntries.count > 500 {
                self.networkEntries.removeLast()
            }
        }
    }

    func clearConsole() { consoleMessages.removeAll() }
    func clearNetwork() { networkEntries.removeAll() }
    func clearAll() { clearConsole(); clearNetwork() }
}

// MARK: - WKScriptMessageHandler

final class ConsoleMessageHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }

        if message.name == "phoenixConsole" {
            let level = body["level"] as? String ?? "log"
            let text = body["text"] as? String ?? ""
            let source = body["source"] as? String
            DevToolsManager.shared.addConsoleMessage(level: level, text: text, source: source)
        }

        if message.name == "phoenixNetwork" {
            let url = body["url"] as? String ?? ""
            let duration = body["duration"] as? Int ?? 0
            let size = body["size"] as? Int64 ?? 0
            let type = body["type"] as? String ?? ""
            DevToolsManager.shared.addNetworkEntry(url: url, duration: duration, size: size, type: type)
        }
    }
}
