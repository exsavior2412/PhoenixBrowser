import Foundation

enum HomographDetector {
    static func isAttack(_ url: URL) -> Bool {
        guard let host = url.host()?.lowercased() else { return false }

        let hasLatin = host.unicodeScalars.contains { CharacterSet.latinChars.contains($0) }
        let hasCyrillic = host.unicodeScalars.contains { CharacterSet.cyrillicChars.contains($0) }
        let hasGreek = host.unicodeScalars.contains { CharacterSet.greekChars.contains($0) }

        if hasLatin && (hasCyrillic || hasGreek) { return true }

        if host.contains("xn--") {
            let labels = host.split(separator: ".")
            if labels.contains(where: { $0.hasPrefix("xn--") }) { return true }
        }

        return false
    }
}

extension CharacterSet {
    static let latinChars: CharacterSet = {
        var s = CharacterSet()
        s.insert(charactersIn: "a"..."z")
        s.insert(charactersIn: "A"..."Z")
        return s
    }()

    static let cyrillicChars: CharacterSet = {
        var s = CharacterSet()
        s.insert(charactersIn: Unicode.Scalar(0x0400)!...Unicode.Scalar(0x04FF)!)
        return s
    }()

    static let greekChars: CharacterSet = {
        var s = CharacterSet()
        s.insert(charactersIn: Unicode.Scalar(0x0370)!...Unicode.Scalar(0x03FF)!)
        return s
    }()
}
