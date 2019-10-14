//
//  PhotosDecodingTests.swift
//  CacheDemoTests
//
//  Created by Raunak Poddar on 14/10/19.
//  Copyright © 2019 Raunak. All rights reserved.
//

import XCTest
@testable import CacheDemo

class PhotosDecodingTests: XCTestCase {
    
    let downloadManager = DownloadManager()
    let path = "http://pastebin.com/raw/wgkJgazE"

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        if let url = URL.init(string: path) {
            let expectation = XCTestExpectation(description: "Download data")
            var photos: Photos?
            let downloadRequest = downloadManager.downloadItem(atURL: url) { (data: Data?) in
                if let data = data {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    photos = try! decoder.decode(Photos.self, from: data) as Photos
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 100.0)
            XCTAssert(photos != nil, "Decoding failed")
            XCTAssert(photos!.count > 0, "Decoding failed")
        } else {
            XCTAssert(false, "failed to create URL")
        }
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
