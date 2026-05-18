import Foundation

enum ContentBlockingRules {
    static let json = """
    [
        {"trigger": {"url-filter": ".*", "resource-type": ["popup"]}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "googleads\\\\.g\\\\.doubleclick\\\\.net"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "pagead2\\\\.googlesyndication\\\\.com"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "ad\\\\.doubleclick\\\\.net"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "ads\\\\.yahoo\\\\.com"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "analytics\\\\.google\\\\.com"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "connect\\\\.facebook\\\\.net.*fbevents"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "static\\\\.ads-twitter\\\\.com"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "cdn\\\\.taboola\\\\.com"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "widgets\\\\.outbrain\\\\.com"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "pixel\\\\.facebook\\\\.com"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "bat\\\\.bing\\\\.com"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "tr\\\\.snapchat\\\\.com"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "sc-static\\\\.net.*scevent"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "amazon-adsystem\\\\.com"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "adservice\\\\.google"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "googlesyndication\\\\.com"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "doubleclick\\\\.net"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "hotjar\\\\.com"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "clarity\\\\.ms"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "newrelic\\\\.com"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "segment\\\\.io"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "segment\\\\.com"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "mixpanel\\\\.com"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "amplitude\\\\.com"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "sentry\\\\.io.*cdn"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "crisp\\\\.chat"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "intercom\\\\.io"}, "action": {"type": "block"}},
        {"trigger": {"url-filter": "tiktok\\\\.com.*analytics"}, "action": {"type": "block"}}
    ]
    """
}
