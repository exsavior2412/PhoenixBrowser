import Foundation
import WebKit

final class StyleManager: ObservableObject {
    @Published var styles: [CustomStyle] = []

    private let storageKey = "phoenix_custom_styles"

    init() {
        load()
    }

    func add(name: String, css: String, urlPattern: String = "*") {
        let style = CustomStyle(name: name, css: css, urlPattern: urlPattern)
        styles.append(style)
        save()
    }

    func remove(_ style: CustomStyle) {
        styles.removeAll { $0.id == style.id }
        save()
    }

    func update(_ style: CustomStyle) {
        if let idx = styles.firstIndex(where: { $0.id == style.id }) {
            styles[idx] = style
            save()
        }
    }

    func toggleStyle(_ style: CustomStyle) {
        if let idx = styles.firstIndex(where: { $0.id == style.id }) {
            styles[idx].isEnabled.toggle()
            save()
        }
    }

    /// Inject matching styles into a WKWebView for the given URL
    func injectStyles(into webView: WKWebView, for url: URL?) {
        let matchingCSS = styles
            .filter { $0.isEnabled && $0.matchesURL(url) }
            .map { $0.css }
            .joined(separator: "\n")

        guard !matchingCSS.isEmpty else { return }

        let js = """
        (function() {
            let el = document.getElementById('phoenix-custom-style');
            if (el) el.remove();
            const style = document.createElement('style');
            style.id = 'phoenix-custom-style';
            style.textContent = \(jsStringLiteral(matchingCSS));
            document.head.appendChild(style);
        })();
        """

        webView.evaluateJavaScript(js)
    }

    private func jsStringLiteral(_ s: String) -> String {
        let escaped = s
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
        return "`\(escaped)`"
    }

    private func save() {
        if let data = try? JSONEncoder().encode(styles) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([CustomStyle].self, from: data)
        else { return }
        styles = saved
    }
}
