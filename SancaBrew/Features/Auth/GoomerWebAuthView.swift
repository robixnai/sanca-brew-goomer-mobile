import SwiftUI
import WebKit

/// Bridges a sign in performed on the Goomer SSO (the store only enables Google
/// and e-mail code) into a native `UserSession`.
///
/// The web page persists the Firebase credential in `localStorage`; the injected
/// script forwards it to the app as soon as it appears, so the native side ends
/// up with the same ID token / refresh token the web client uses.
struct GoomerWebAuthView: UIViewRepresentable {
    let url: URL
    let onSession: (FirebaseWebSession) -> Void
    @Binding var isLoading: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(onSession: onSession, isLoading: $isLoading)
    }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: Coordinator.messageName)
        controller.addUserScript(
            WKUserScript(
                source: Coordinator.bridgeScript,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: false
            )
        )

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        // Google refuses to render its account chooser for the default WKWebView
        // agent string, so the view identifies itself as mobile Safari.
        webView.customUserAgent = Coordinator.safariUserAgent
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        static let messageName = "goomerAuth"
        static let safariUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

        static var bridgeScript: String {
            """
            (function () {
              var key = "\(GoomerEnvironment.firebaseWebSessionKey)";
              var last = null;
              function report() {
                try {
                  var raw = window.localStorage.getItem(key);
                  if (raw && raw !== last) {
                    last = raw;
                    window.webkit.messageHandlers.\(Coordinator.messageName).postMessage(raw);
                  }
                } catch (error) { /* cross-origin frame, ignore */ }
              }
              report();
              window.setInterval(report, 600);
            })();
            """
        }

        private let onSession: (FirebaseWebSession) -> Void
        @Binding private var isLoading: Bool

        init(onSession: @escaping (FirebaseWebSession) -> Void, isLoading: Binding<Bool>) {
            self.onSession = onSession
            self._isLoading = isLoading
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == Self.messageName,
                  let json = message.body as? String,
                  let session = FirebaseWebSession.decode(from: json) else { return }
            onSession(session)
        }

        nonisolated func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Task { @MainActor in self.isLoading = true }
        }

        nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in self.isLoading = false }
        }

        nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in self.isLoading = false }
        }
    }
}

/// Reusable container for the Goomer web flows the app still delegates to the
/// site (sign in and checkout).
struct GoomerWebFlowView: View {
    let title: String
    let url: URL
    var onSession: ((FirebaseWebSession) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                GoomerWebAuthView(url: url, onSession: { onSession?($0) }, isLoading: $isLoading)
                    .ignoresSafeArea(edges: .bottom)
                if isLoading {
                    ProgressView().controlSize(.large)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }
}
