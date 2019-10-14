//
//  DownloadManagerTests.swift
//  CacheDemoTests
//
//  Created by Raunak Poddar on 14/10/19.
//  Copyright © 2019 Raunak. All rights reserved.
//

import XCTest
@testable import CacheDemo

class DownloadManagerTests: XCTestCase {
    
    let paths = [
        "https://images.unsplash.com/profile-1464495186405-68089dcd96c3?ixlib=rb-0.3.5&q=80&fm=jpg&crop=faces&fit=crop&h=32&w=32&s=63f1d805cffccb834cf839c719d91702",
        "https://images.unsplash.com/photo-1464550838636-1a3496df938b?ixlib=rb-0.3.5&q=80&fm=jpg&crop=entropy&w=1080&fit=max&s=67b8dcbfc47e2ba3f39d2d01a8177864",
        "https://images.unsplash.com/photo-1464550580740-b3f73fd373cb?ixlib=rb-0.3.5&q=80&fm=jpg&crop=entropy&w=1080&fit=max&s=899c346de4765f353375b8a5bd6cfc0e"
    ]

    let downloadManager = DownloadManager()
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        downloadManager.cancelAll()
        downloadManager.clearCache()
    }

    func testSimpleDownload() {
        if let url = URL.init(string: paths[0]) {
            let expectation = XCTestExpectation(description: "Download data")
            let expectedData = try! Data(contentsOf: url)
            var downloadedData: Data?
            let _ = downloadManager.downloadItem(atURL: url) { (data: Data?) in
                downloadedData = data
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 10.0)
            XCTAssert(downloadedData!.count == expectedData.count, "size mismatch")
        }
    }
    
    func testCancelDownload() {
        if let url = URL.init(string: paths[0]) {
            let expectation = XCTestExpectation(description: "Download data")
            let expectedData = try! Data(contentsOf: url)
            var downloadedData: Data?
            let downloadRequest = downloadManager.downloadItem(atURL: url) { (data: Data?) in
                downloadedData = data
                expectation.fulfill()
            }
            downloadRequest?.cancel()
            wait(for: [expectation], timeout: 10.0)
            if let downloadedData = downloadedData {
                XCTAssert(downloadedData.count == expectedData.count, "size mismatch")
            }
            
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
