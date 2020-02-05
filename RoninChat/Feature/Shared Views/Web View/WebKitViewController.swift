import WebKit

class WebKitViewController: UIViewController {
    public static let segueIdentifier: String = "ShowWebKitViewController"
    
    @IBOutlet var urlLabel: UILabel!
    @IBOutlet var reloadButton: UIButton!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var webView: WKWebView!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var forwardButton: UIButton!
    
    var url: URL?
    var observation: NSKeyValueObservation?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        progressView.setProgress(0.0, animated: false)
        setProgressBarObservation()
        
        if let url = self.url {
            let request = URLRequest(url: url)
            webView.load(request)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    deinit {
        self.observation = nil
    }
    
    
    // MARK: UI Actions
    
    @IBAction func reloadTouchUpInside(_ sender: UIButton) {
        if !webView.isLoading {
            webView.reloadFromOrigin()
        } else {
            webView.stopLoading()
        }
    }
    
    @IBAction func backButtonTouchUpInside(_ sender: UIButton) {
        webView.goBack()
    }
    
    @IBAction func forwardButtonTouchUpInside(_ sender: UIButton) {
        webView.goForward()
    }
    
    @IBAction func openInBrowserTouchUpInside(_ sender: UIButton) {
        guard let url = webView.url else { return }
        
        UIApplication.shared.open(url)
    }
    
    
    // MARK: Animations
    
    private func setProgressBarObservation() {
        observation = webView.observe(\WKWebView.estimatedProgress, options: .new) { _, change in
            let progress = Float(change.newValue ?? 1.0)
            
            if progress < 1.0 {
                self.progressView.setProgress(progress, animated: true)
            } else {
                self.animateProgressBarComplete()
            }
        }
    }
    
    private func animateProgressBarComplete() {
        UIView.animate(withDuration: 0.1, animations: {
            self.progressView.setProgress(1.0, animated: true)
        }, completion: { completed in
            if completed {
                self.animateProgressBarHidden()
            }
        })
    }
    
    private func animateProgressBarHidden() {
        UIView.animate(withDuration: 1.0, animations: {
            self.progressView.alpha = 0.0
        }, completion: { completed in
            self.progressView.setProgress(0.0, animated: false)
        })
    }
}


// MARK: WKNavigationDelegate

extension WebKitViewController: WKUIDelegate, WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        urlLabel.text = self.webView.url?.host
        reloadButton.setImage(#imageLiteral(resourceName: "ic_clear"), for: .normal)
        progressView.alpha = 1.0
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        reloadButton.setImage(#imageLiteral(resourceName: "ic_refresh.pdf"), for: .normal)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        reloadButton.setImage(#imageLiteral(resourceName: "ic_refresh.pdf"), for: .normal)
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
    }
}
