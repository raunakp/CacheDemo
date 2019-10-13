//
//  LRUCacheTests.swift
//  CacheDemoTests
//
//  Created by Raunak Poddar on 13/10/19.
//  Copyright © 2019 Raunak. All rights reserved.
//

import XCTest
@testable import CacheDemo

class LRUCacheTests: XCTestCase {
    
    var cache = LRUCache()
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        XCTAssert(cache.count == 0, "Expected 0 count")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        cache.removeAll()
    }
    
    func testSimpleSetGet() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        cache.set(value: 1, key: "1")
        let val = cache.value(forKey: "1")
        XCTAssert((val as! Int) == 1, "Invalid value")
    }
    
    func testAsync() {
        DispatchQueue.concurrentPerform(iterations: 10) { (index) in
            cache.set(value: index + 1, key: String(index))
            let val = cache.value(forKey: String(index))
            XCTAssert((val as! Int) == index + 1, "Invalid value")
        }
    }
    
    func testMaxCapacity() {
        for i in 0..<11 {
            cache.set(value: i, key: String(i))
        }
        
        let val0 = cache.value(forKey: "0")
        XCTAssertNil(val0, "Expected nil")
        let val1 = cache.value(forKey: "1")
        XCTAssert((val1 as! Int) == 1, "Invalid value")
        let val10 = cache.value(forKey: "10")
        XCTAssert((val10 as! Int) == 10, "Invalid value")
        
        let val11 = cache.value(forKey: "11")
        XCTAssertNil(val11, "Invalid value")
    }
    
    func testPerformanceAsyncReadWrite() {
        self.measure {
            let writeQueue = DispatchQueue(
                label: String("writeQueue"),
                attributes: .concurrent
            )
            let readQueue = DispatchQueue(
                label: String("readQueue"),
                attributes: .concurrent
            )
            
            let dispatchGroup = DispatchGroup()
            
            dispatchGroup.enter()
            for i in 0..<9999 {
                writeQueue.async { [unowned self] in
                    print("setting: \(i)")
                    self.cache.set(value: i, key: String(i))
                    print("done setting: \(i)")
                    XCTAssert(self.cache.count <= self.cache.maxCapacity , "self.cache.count: \(self.cache.count)")
                }
            }
            writeQueue.async(flags: .barrier) {
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            for i in 0..<9999 {
                readQueue.async { [unowned self] in
                    print("reading: \(i)")
                    let val = self.cache.value(forKey: String(i))
                    print("done reading: \(i)")
                    if let val = val {
                        XCTAssert((val as! Int) == i, "Invalid value")
                    }
                }
            }
            readQueue.async(flags: .barrier) {
                dispatchGroup.leave()
            }
            
            let result = dispatchGroup.wait(timeout: DispatchTime.now() + .seconds(100))
            print(result)
            XCTAssert(result == DispatchTimeoutResult.success, "timed out")
            XCTAssert(cache.count <= cache.maxCapacity , "self.cache.count: \(self.cache.count)")
        }
    }
    
    func testPerformance() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            DispatchQueue.concurrentPerform(iterations: 999) { (index) in
                cache.set(value: index + 1, key: String(index))
                let val = cache.value(forKey: String(index))
                XCTAssert((val as! Int) == index + 1, "Invalid value")
            }
        }
    }
    
}
