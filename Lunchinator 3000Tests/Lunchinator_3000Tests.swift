//
//  Lunchinator_3000Tests.swift
//  Lunchinator 3000Tests
//
//  Created by David Ulbrich on 7/11/17.
//  Copyright © 2017 David Ulbrich. All rights reserved.
//

import XCTest
@testable import Lunchinator_3000

class Lunchinator_3000Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testRestaurantsClass() {
        //currently fails because description cannot be used as a variable.
        let restaurant = Restaurants()
        XCTAssert(restaurant.description == "")
    }
    
    func testSortingOfRestaurants() {
        let networking = Networking()
        let sorted = networking.testGetRestaurants()
        //TODO: Fix concurrency issue
        XCTAssert(sorted)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
