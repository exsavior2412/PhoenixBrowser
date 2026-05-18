import Foundation

enum XSSDetector {
    private static let patterns = [
        "<script", "javascript:", "onerror=", "onload=", "onclick=",
        "onmouseover=", "onfocus=", "eval(", "document.cookie",
        "document.write", "window.location", "innerhtml",
        "fromcharcode", "\\x3c", "%3cscript", "&#x3c;",
        "data:text/html",
    ]

    static func containsPayload(_ input: String) -> Bool {
        let lower = input.lowercased()
        return patterns.contains { lower.contains($0) }
    }
}
