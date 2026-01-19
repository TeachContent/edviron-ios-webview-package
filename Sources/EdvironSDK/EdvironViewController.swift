import UIKit
@preconcurrency import WebKit

public enum EdvironMode {
    case production
    case development
}

public class EdvironViewController: UIViewController, WKNavigationDelegate {

    private var webView: WKWebView!

    public var collectRequestId: String
    public var mode: EdvironMode
    public var onSuccess: (() -> Void)?
    public var onError: (() -> Void)?

    public init(
        collectRequestId: String,
        mode: EdvironMode = .production,
        onSuccess: (() -> Void)? = nil,
        onError: (() -> Void)? = nil
    ) {
        self.collectRequestId = collectRequestId
        self.mode = mode
        self.onSuccess = onSuccess
        self.onError = onError
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupWebView()
        setupNavigationBar()
        loadPaymentPage()
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.navigationDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)
    }

    private func setupNavigationBar() {
        self.title = "Edviron Payment"
        if #available(iOS 13.0, *) {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(closeView)
            )
        }
    }

    private func loadPaymentPage() {
        let prefix = mode == .production ? "pg" : "dev.pg"
        let urlString = "https://\(prefix).edviron.in/collect-sdk-payments?collect_id=\(collectRequestId)"
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    @objc private func closeView() {
        self.navigationController?.popViewController(animated: true)
    }

    // MARK: - WKNavigationDelegate

    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        let urlString = url.absoluteString
        print("Navigating to: \(urlString)")
        
        if urlString.contains("pg.edviron.in/payment-success") {
            onSuccess?()
            self.navigationController?.popViewController(animated: true)
            decisionHandler(.cancel)
            return
        } else if urlString.contains("pg.edviron.in/payment-failure") {
            onError?()
            self.navigationController?.popViewController(animated: true)
            decisionHandler(.cancel)
            return
        }

        // Convert tez:// to gpay:// if needed
        if url.scheme == "tez" {
            let gpayURLString = urlString.replacingOccurrences(of: "tez://", with: "gpay://")
            if let gpayURL = URL(string: gpayURLString), UIApplication.shared.canOpenURL(gpayURL) {
                UIApplication.shared.open(gpayURL, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
                return
            }
        }

        if let scheme = url.scheme?.lowercased(),
           ["upi", "gpay", "phonepe", "paytmmp"].contains(scheme) {
            
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                let alert = UIAlertController(
                    title: "UPI App Not Found",
                    message: "No installed app can handle this UPI payment.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

}
