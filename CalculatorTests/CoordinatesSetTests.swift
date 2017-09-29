//
//  CoordinatesSetTests.swift
//  Calculator
//
//  Created by Sergei Kultenko on 06/09/2017.
//  Copyright © 2017 Sergey Kultenko. All rights reserved.
//

import XCTest
@testable import Calculator

class CoordinatesSetTests: XCTestCase
{
    var coordinates:CoordinatesSet?
    
    let pointsPerUnit: CGFloat = 100
    let halfWidth: CGFloat = 1000
    let halfHeight: CGFloat = 2000
    
    override func setUp() {
        super.setUp()
        
        coordinates = CoordinatesSet(center: CGPoint(x: halfWidth, y: halfHeight),
                                     halfWidth: halfWidth,
                                     halfHeight: halfHeight,
                                     pointsPerUnit: pointsPerUnit)
    }
    
    override func tearDown() {
        coordinates = nil
        
        super.tearDown()
    }
    
    func testIterator() {
        //Given
        guard coordinates != nil else {
            XCTAssertNotNil(coordinates)
            return
        }
        
        //When
        var coordinatesArray = Array<CGFloat>()
        for x in coordinates! {
            coordinatesArray.append(x)
        }
        
        //Then
        XCTAssertEqual(coordinatesArray[0], -10)
        XCTAssertEqual(coordinatesArray[1000], 0)
        XCTAssertEqual(coordinatesArray[1900], 9)
    }
    
    
    func testCoordinates1() {
        //Given
        //When
        let point = coordinates?.convertToCGPointFromUnits(xUnit: 1.0, yUnit: 1.0)
        
        //Then
        XCTAssertNotNil(point)
        if point != nil {
            XCTAssertEqual(point!.x, 1100.0)
            XCTAssertEqual(point!.y, 1900.0)
        }
    }

    func testCoordinates2() {
        //Given
        //When
        let point = coordinates?.convertToCGPointFromUnits(xUnit: -1.0, yUnit: -1.0)
        
        //Then
        XCTAssertNotNil(point)
        if point != nil {
            XCTAssertEqual(point!.x, 900.0)
            XCTAssertEqual(point!.y, 2100.0)
        }
    }

    func testCoordinates3() {
        //Given
        //When
        let point = coordinates?.convertToCGPointFromUnits(xUnit: -1.0, yUnit: 1.0)
        
        //Then
        XCTAssertNotNil(point)
        if point != nil {
            XCTAssertEqual(point!.x, 900.0)
            XCTAssertEqual(point!.y, 1900.0)
        }
    }

    func testCoordinates4() {
        //Given
        //When
        let point = coordinates?.convertToCGPointFromUnits(xUnit: 1.0, yUnit: -1.0)
        
        //Then
        XCTAssertNotNil(point)
        if point != nil {
            XCTAssertEqual(point!.x, 1100.0)
            XCTAssertEqual(point!.y, 2100.0)
        }
    }

}
