//
//  CoordinatesSet.swift
//  Calculator
//
//  Created by Sergei Kultenko on 06/09/2017.
//  Copyright © 2017 Sergey Kultenko. All rights reserved.
//

import Foundation
import UIKit

struct CoordinatesSet: Sequence, IteratorProtocol
{
    let center: CGPoint
    let halfWidth: CGFloat
    let halfHeight: CGFloat
    let pointsPerUnit: CGFloat
    
    var startingPointX: CGFloat

    init(center: CGPoint, halfWidth: CGFloat, halfHeight: CGFloat, pointsPerUnit: CGFloat) {
        self.center = center
        self.halfWidth = halfWidth
        self.halfHeight = halfHeight
        self.pointsPerUnit = pointsPerUnit
        
        startingPointX = center.x - halfWidth
    }
    
    mutating func next() -> CGFloat? {
        if startingPointX >= (center.x + halfWidth) {
            return nil
        } else {
            defer { startingPointX += 1 }
            return xUnitFromPoint(startingPointX)
        }
    }
    
    func convertToCGPointFromUnits(xUnit x:CGFloat, yUnit y:CGFloat) -> CGPoint? {
        guard pointsPerUnit > 0 else {
            return nil
        }
        let xPoints = x * pointsPerUnit + center.x
        let yPoints = center.y - y * pointsPerUnit
        
        return CGPoint(x: xPoints, y: yPoints)
    }
    
    func xUnitFromPoint(_ point: CGFloat) -> CGFloat? {
        guard pointsPerUnit > 0 else {
            return nil
        }
        return CGFloat(point - center.x)/pointsPerUnit
    }
}
