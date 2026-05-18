import SwiftUI

struct SecurityWarningView: View {
    let threat: SecurityThreat
    let url: URL
    let onProceed: () -> Void
    let onGoBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 80, height: 80)
                    Image(systemName: iconName)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(iconColor)
                }

                // Title
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)

                // Description
                Text(description)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 440)

                // URL
                Text(url.absoluteString)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .frame(maxWidth: 440)

                // Buttons
                HStack(spacing: 16) {
                    Button(action: onGoBack) {
                        Text("Go Back")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.cancelAction)

                    if threat == .httpSite {
                        Button(action: onProceed) {
                            Text("Proceed Anyway")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.primary.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .shadow(color: .black.opacity(0.1), radius: 20, y: 4)
            )

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var title: String {
        switch threat {
        case .phishing: return "Deceptive Site Ahead"
        case .malware: return "Dangerous Site"
        case .unwanted: return "Suspicious Site"
        case .httpSite: return "Connection Not Secure"
        case .certError: return "Certificate Error"
        }
    }

    private var description: String {
        switch threat {
        case .phishing:
            return "This website may be trying to steal your personal information such as passwords, credit card numbers, or other sensitive data."
        case .malware:
            return "This website has been reported as containing malware that could harm your computer."
        case .unwanted:
            return "This website may contain unwanted or deceptive content."
        case .httpSite:
            return "This site uses an unencrypted connection (HTTP). Information you send or receive could be viewed or modified by others on the network."
        case .certError:
            return "The certificate for this website is invalid. This could mean someone is trying to impersonate the site."
        }
    }

    private var iconName: String {
        switch threat {
        case .phishing: return "exclamationmark.shield.fill"
        case .malware: return "ladybug.fill"
        case .unwanted: return "exclamationmark.triangle.fill"
        case .httpSite: return "lock.open.fill"
        case .certError: return "xmark.shield.fill"
        }
    }

    private var iconColor: Color {
        switch threat {
        case .phishing, .malware, .certError: return .red
        case .unwanted: return .orange
        case .httpSite: return .yellow
        }
    }

    private var iconBackgroundColor: Color {
        iconColor.opacity(0.12)
    }
}
