//
//  URLDetailsViewController.swift
//  ImageLoadingProject
//
//  Created by Teacher on 16.11.2020.
//

import MobileCoreServices
import UIKit
import WebKit

class URLDetailsViewController: UIViewController, URLSessionDownloadDelegate {

    var pageUrl: URL?
    private var progressBar: UIProgressView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.progressBar = UIProgressView(frame: CGRect(x: self.view.frame.width / 2 - 50, y: self.view.frame.height / 2 , width: 100, height: 20))
        
        self.view.addSubview(progressBar!)
        self.view.backgroundColor = .white
        
        loadURL()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        webView?.frame = webViewFrame()
    }

    private var webView: WKWebView?

    private func webViewFrame() -> CGRect {
        view.bounds.inset(by: UIEdgeInsets(top: view.layoutMargins.top, left: 0, bottom: view.layoutMargins.bottom, right: 0))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let data = try! Data(contentsOf: location)

        DispatchQueue.main.sync {
            self.progressBar?.isHidden = true
            self.process(data: data)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.sync {
            progressBar?.progress = Float(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite))
        }
    }

    private func loadURL() {
        let urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        guard self.pageUrl != nil else { return }
        let dataTask = urlSession.downloadTask(with: self.pageUrl!)
        dataTask.resume()
    }

    private func process(data: Data) {
        guard let documentsDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Could not create documents directory url")
            return
        }

        var documentUrl: URL? = nil

        if pageUrl?.containsImage ?? false {
            documentUrl = documentsDirectoryUrl.appendingPathComponent("\(UUID().uuidString).jpeg")
        } else {
            documentUrl = documentsDirectoryUrl.appendingPathComponent("\(UUID().uuidString).html")
        }

        guard let htmlDocumentUrl = documentUrl else {
            return
        }

        guard FileManager.default.createFile(atPath: htmlDocumentUrl.path, contents: data) else {
            print("Could not create page at url: \(htmlDocumentUrl)")
            return
        }

        let webView = WKWebView()
        webView.loadFileURL(htmlDocumentUrl, allowingReadAccessTo: htmlDocumentUrl)
        view.addSubview(webView)
        webView.frame = webViewFrame()
    }
}

extension URL {
    func mimeType() -> String {
        let pathExtension = self.pathExtension
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
    var containsImage: Bool {
        let mimeType = self.mimeType()
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue() else {
            return false
        }
        return UTTypeConformsTo(uti, kUTTypeImage)
    }
    var containsAudio: Bool {
        let mimeType = self.mimeType()
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue() else {
            return false
        }
        return UTTypeConformsTo(uti, kUTTypeAudio)
    }
    var containsVideo: Bool {
        let mimeType = self.mimeType()
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue() else {
            return false
        }
        return UTTypeConformsTo(uti, kUTTypeMovie)
    }

}
