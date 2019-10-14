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
    
    fileprivate let queue = DispatchQueue.init(label: "DownloadManager")
    
    fileprivate lazy var cache: LRUCache = {
        let c = LRUCache()
        c.setCacheCapacity(capacity: 20)
        return c
    }()
    
    func setCacheCapacity(capacity: Int) {
        cache.setCacheCapacity(capacity: capacity)
    }
    
    func clearCache() {
        cache.removeAll()
    }
    
    fileprivate var downloadOperations = [String: ItemDownloadOperation]()
    
    func cancelAll() {
        queue.async { [weak self] in
            self?.downloadQueue.cancelAllOperations()
            self?.downloadOperations.removeAll()
        }
    }
    
    private lazy var downloadQueue: OperationQueue = {
        var opQueue = OperationQueue()
        opQueue.name = "Download queue"
        opQueue.maxConcurrentOperationCount = 10
        return opQueue
    }()
    
    func downloadItem(atURL url: URL, completionHandler: @escaping (Data?) -> ()) -> ItemDownloadRequest? {
        var downloadRequest: ItemDownloadRequest?
        queue.sync {
            if let val = cache.value(forKey: url.absoluteString) {
                print("hit")
                completionHandler(val as? Data)
                downloadRequest = nil
            } else if let pendingOp = downloadOperations[url.absoluteString] {
                print("missed")
                let commonDownloadRequest = pendingOp.commonDownloadRequest!
                downloadRequest = commonDownloadRequest.addRequest(completionHandler: completionHandler)
            } else {
                print("queued")
                let item = DownloadItem.init(url: url)
                let operation = ItemDownloadOperation.init(item: item)
                downloadOperations[item.url.absoluteString] = operation
                
                let commonDownloadRequest = CommonDownloadRequest.init(downloadOp: operation)
                commonDownloadRequest.downloadManager = self
                operation.commonDownloadRequest = commonDownloadRequest
                downloadRequest = commonDownloadRequest.addRequest(completionHandler: completionHandler)
                downloadQueue.addOperation(operation)
            }
        }
        
        return downloadRequest
    }
}

fileprivate class CommonDownloadRequest {
    
    private var maxReqId = 0
    
    private weak var downloadOperation: ItemDownloadOperation?
    
    fileprivate weak var downloadManager: DownloadManager?
    
    fileprivate init(downloadOp: ItemDownloadOperation) {
        self.downloadOperation = downloadOp
        
        downloadOp.completionBlock = {  [weak self] in
            
            guard let self = self else {
                return
            }
            
            if let q = self.downloadManager?.queue {
                q.async {
                    self.downloadManager?.downloadOperations.removeValue(forKey: downloadOp.downloadItem.url.absoluteString)
                    if let data = downloadOp.downloadItem.data {
                        self.downloadManager?.cache.set(value: data, key: downloadOp.downloadItem.url.absoluteString)
                    }
                    
                    for request in self.requests {
                        DispatchQueue.main.async {
                            request?.completionHandler?(downloadOp.downloadItem.data)
                        }
                    }
                }
            }
        }
    }
    
    fileprivate func addRequest(completionHandler: @escaping (Data?) -> ()) -> ItemDownloadRequest {
        let itemDownloadRequest = ItemDownloadRequest.init(reqId: maxReqId)
        itemDownloadRequest.completionHandler = completionHandler
        itemDownloadRequest.commonDownloadRequest = self
        requests.append(itemDownloadRequest)
        
        return itemDownloadRequest
    }
    
    private var requests = [ItemDownloadRequest?]()
    
    func cancel(itemDownloadRequest: ItemDownloadRequest) {
        downloadManager?.queue.async { [weak self] in
            self?.requests[itemDownloadRequest.reqId] = nil
            self?.decreaseRequestCount()
        }
    }
    
    private func increaseRequestCount() {
        downloadOperation?.increaseRequestCount()
    }
    
    private func decreaseRequestCount() {
        if let downloadOperation = downloadOperation {
            downloadOperation.decreaseRequestCount()
            if downloadOperation.isCancelled {
                downloadManager?.downloadOperations.removeValue(forKey: downloadOperation.downloadItem.url.absoluteString)
            }
        }
    }
}

class ItemDownloadRequest {
    
    fileprivate let reqId: Int!
    
    fileprivate weak var commonDownloadRequest: CommonDownloadRequest?
    
    fileprivate var completionHandler: ((Data?) -> ())?
    
    func cancel() {
        self.commonDownloadRequest?.cancel(itemDownloadRequest: self)
    }
    
    init(reqId: Int) {
        self.reqId = reqId
    }
}

fileprivate class ItemDownloadOperation: Operation {
    
    var commonDownloadRequest: CommonDownloadRequest!
    
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
        let semaphore = DispatchSemaphore(value: 0)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let urlRequest = URLRequest.init(url: downloadItem.url,
                                         cachePolicy: .reloadIgnoringLocalCacheData,
                                         timeoutInterval: 3.0)
        let task = session.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            guard let self = self else { return }
            if let data = data {
                self.downloadItem.data = data
                self.downloadItem.state = .downloaded
            } else {
                self.downloadItem.data = nil
                self.downloadItem.state = .failed
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
//        guard let data = try? Data(contentsOf: downloadItem.url) else { return }
    }
}
