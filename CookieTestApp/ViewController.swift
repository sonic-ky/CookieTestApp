//
//  ViewController.swift
//  CookieTestApp
//
//  Created by k.yamamoto on 2021/09/12.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    @IBOutlet private var webView: WKWebView! {
        didSet {
            webView.navigationDelegate = self
        }
    }
    
    @IBOutlet private var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    @IBOutlet private var textField: UITextField!
    
    private var cookies: [HTTPCookie] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadHome()
    }
    
    @IBAction private func setTestCookie() {
        let cookie = HTTPCookie(properties: [
            .domain: webView.url?.host ?? ".",
            .path: "/",
            .name: "TestCookie",
            .value: "ThisisTestCookie",
            .expires: Date().addingTimeInterval(60),
//            .secure: true,
//            .sameSitePolicy: HTTPCookieStringPolicy.sameSiteLax,
//            .httpOnly: true
        ])!
        setCookie(cookie)
    }
    
    @IBAction func clearCookies() {
        bulkDeleteCookies(cookies)
    }
    
    @IBAction func reload() {
        webView.reload()
    }
    
    @IBAction func loadHome() {
//        let request = URLRequest(url: URL(string: "http://localhost:3000/")!)
        let request = URLRequest(url: URL(string: "https://www.google.com/")!)
        webView.load(request)
    }
}

private extension ViewController {
    var cookieStore: WKHTTPCookieStore {
        webView.configuration.websiteDataStore.httpCookieStore
    }
    
    func fetchCookies() {
        cookieStore.getAllCookies { [weak self] in
            self?.cookies = $0
            self?.tableView.reloadData()
        }
    }
    
    func setCookie(_ cookie: HTTPCookie) {
        cookieStore.setCookie(cookie) { [weak self] in
            self?.fetchCookies()
        }
    }
    
    func deleteCookie(_ cookie: HTTPCookie) {
        cookieStore.delete(cookie) { [weak self] in
            self?.fetchCookies()
        }
    }
    
    func bulkDeleteCookies(_ cookies: [HTTPCookie]) {
        cookies.forEach { [weak self] in
            self?.cookieStore.delete($0)
        }
        fetchCookies()
    }
}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        fetchCookies()
        textField.text = webView.url?.absoluteString
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cookies.count
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cookie = cookies[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        cell.textLabel?.text = "\(cookie.name)=\(cookie.value)"
        cell.detailTextLabel?.text = "\(cookie.domain)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let cookie = cookies[indexPath.row]
        
        let message = """
                Name: \(cookie.name)
                Value: \(cookie.value)
                Domain: \(cookie.domain)
                Path: \(cookie.path)
                Expires: \(cookie.expiresDate?.description ?? "Session")
                HttpOnly: \(cookie.isHTTPOnly)
                Secure: \(cookie.isSecure)
                SameSite: \(cookie.sameSitePolicy?.rawValue ?? "")
                Version: \(cookie.version)
                """
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        let messageText = NSAttributedString(
            string: message,
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),
            ]
        )
        
        let alert = UIAlertController(title: nil, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        alert.setValue(messageText, forKey: "attributedMessage")
        self.present(alert, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let cookie = cookies[indexPath.row]
            deleteCookie(cookie)
        }
    }
}

extension HTTPCookiePropertyKey {
    static let httpOnly = HTTPCookiePropertyKey("HttpOnly")
}
