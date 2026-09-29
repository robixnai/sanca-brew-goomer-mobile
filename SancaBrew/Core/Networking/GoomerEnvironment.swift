import Foundation

/// Every remote address and identifier the app depends on.
///
/// The values come from the published store front-end
/// (`https://sanca-brew-a-casa-do-cervejeiro.goomer.app`) and are the same ones
/// its web client uses, so the native app talks to the very same backend.
enum GoomerEnvironment {
    static let storeSlug = "sanca-brew-a-casa-do-cervejeiro"
    static let storeID = 50901

    static let webBaseURL = URL(string: "https://sanca-brew-a-casa-do-cervejeiro.goomer.app")!
    static let apiBaseURL = URL(string: "https://api-go.goomer.app")!
    static let menuHostURL = URL(string: "https://www.goomer.app")!

    /// Public web API key of the `goomer-sso` Firebase project used by the store
    /// front-end. It is not a secret: it is shipped in the site's JavaScript and
    /// only identifies the project for Identity Toolkit calls.
    static let firebaseAPIKey = "AIzaSyA1hDbuEHn6C60BQHq_5Z1ZxN5a1w9tcPM"
    static let firebaseAuthDomain = "goomer-sso.firebaseapp.com"

    static var firebaseWebSessionKey: String { "firebase:authUser:\(firebaseAPIKey):[DEFAULT]" }

    static let defaultHeaders: [String: String] = [
        "Accept": "application/json, text/plain, */*",
        "Accept-Language": "pt-BR,pt;q=0.9",
        "Origin": webBaseURL.absoluteString,
        "Referer": webBaseURL.absoluteString + "/"
    ]

    static var storeInfoURL: URL {
        var components = URLComponents(url: apiBaseURL.appendingPathComponent("/v2/establishments/\(storeSlug)/info"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "mode", value: "slug"),
            URLQueryItem(name: "provider", value: "ggo")
        ]
        return components.url!
    }

    static func menuURL(from rawValue: String) -> URL? {
        guard var components = URLComponents(string: rawValue) else { return nil }
        var items = components.queryItems ?? []
        if !items.contains(where: { $0.name == "provider" }) {
            items.append(URLQueryItem(name: "provider", value: "ggo"))
        }
        components.queryItems = items
        return components.url
    }

    static var profileWebURL: URL { webBaseURL.appendingPathComponent("profile") }
    static var checkoutWebURL: URL { webBaseURL.appendingPathComponent("menu") }
}
