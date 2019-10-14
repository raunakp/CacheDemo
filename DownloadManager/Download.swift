//
//  Download.swift
//  CacheDemo
//
//  Created by Raunak Poddar on 13/10/19.
//  Copyright © 2019 Raunak. All rights reserved.
//

import Foundation

fileprivate enum DownloadItemState {
    case new, downloaded, failed
}

fileprivate class DownloadItem {
    let url: URL
    var state = DownloadItemState.new
    var data: Data?
    
    init(url: URL) {
        self.url = url
    }
}

class DownloadManager {
    
    fileprivate var cache = LRUCache()
    
    func clearCache() {
        cache.removeAll()
    }
    
    fileprivate var downloadOperations = [String: ItemDownloadOperation]()
    
    func cancelAll() {
        downloadQueue.cancelAllOperations()
        downloadOperations.removeAll()
    }
    
    private lazy var downloadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Download queue"
        queue.maxConcurrentOperationCount = 10
        return queue
    }()
    
    func downloadItem(atURL url: URL, completionHandler: @escaping (Data?) -> ()) -> ItemDownloadRequest? {
        var downloadRequest: ItemDownloadRequest?
        
        if let val = cache.value(forKey: url.absoluteString) {
            completionHandler(val as? Data)
            downloadRequest = nil
        } else if let pendingOp = downloadOperations[url.absoluteString] {
            downloadRequest = pendingOp.downloadRequest!
            downloadRequest?.increaseRequestCount()
            downloadRequest?.addCompletionHandler(completionHandler: completionHandler)
        } else {
            let item = DownloadItem.init(url: url)
            let operation = ItemDownloadOperation.init(item: item)
            downloadOperations[item.url.absoluteString] = operation
            downloadRequest = ItemDownloadRequest.init(downloadOp: operation)
            operation.downloadRequest = downloadRequest
            downloadRequest?.addCompletionHandler(completionHandler: completionHandler)
            downloadQueue.addOperation(operation)
        }
        
        downloadRequest?.downloadManager = self
        downloadRequest?.addCompletionHandler(completionHandler: completionHandler)
        return downloadRequest
    }
}

class ItemDownloadRequest {
    
    private var completionHandlers = [(Data?) -> ()]()
    
    fileprivate func addCompletionHandler(completionHandler: @escaping (Data?) -> ()) {
        self.completionHandlers.append(completionHandler)
    }
    
    func cancel() {
        self.decreaseRequestCount()
    }
    
    private weak var downloadOperation: ItemDownloadOperation?
    
    fileprivate weak var downloadManager: DownloadManager?
    
    fileprivate init(downloadOp: ItemDownloadOperation) {
        self.downloadOperation = downloadOp
        downloadOp.completionBlock = {  [weak self] in
            guard let self = self else {
                return
            }
            if let data = downloadOp.downloadItem.data {
                self.downloadManager?.cache.set(value: data, key: downloadOp.downloadItem.url.absoluteString)
            }
            
            for handler in self.completionHandlers {
                handler(downloadOp.downloadItem.data)
            }
        }
    }
    
    fileprivate func increaseRequestCount() {
        downloadOperation?.increaseRequestCount()
    }
    
    fileprivate func decreaseRequestCount() {
        if let downloadOperation = downloadOperation {
            downloadOperation.decreaseRequestCount()
            if downloadOperation.isCancelled {
                downloadManager?.downloadOperations.removeValue(forKey: downloadOperation.downloadItem.url.absoluteString)
            }
        }
    }
}

fileprivate class ItemDownloadOperation: Operation {
    
    var downloadRequest: ItemDownloadRequest!
    
    let downloadItem: DownloadItem
    
    private var requestCount = 1
    
    func increaseRequestCount() {
        requestCount += 1
    }
    
    func decreaseRequestCount() {
        requestCount -= 1
        if requestCount == 0 {
            self.cancel()
        }
    }
    
    init(item: DownloadItem) {
        self.downloadItem = item
    }
    
    override func main() {
        if isCancelled {
            return
        }
        
        guard let data = try? Data(contentsOf: downloadItem.url) else { return }
        
        if !data.isEmpty {
            downloadItem.data = data
            downloadItem.state = .downloaded
        } else {
            downloadItem.data = nil
            downloadItem.state = .failed
        }
    }
}
