//
//  GraphicView.swift
//  Calculator
//
//  Created by Sergei Kultenko on 05/09/2017.
//  Copyright © 2017 Sergey Kultenko. All rights reserved.
//

import UIKit

@IBDesignable class GraphicView: UIView
{
    private var axesDrawer = AxesDrawer()
    public var graphDataSource: GraphDataSource? {
        didSet {
            opQueue.maxConcurrentOperationCount = 1
            opQueue.qualityOfService = .userInteractive
            recalculateBufer()
        }
    }
    
    @IBInspectable var scale: CGFloat = 1.0 {
        didSet {
            axesDrawer.contentScaleFactor = scale
            recalculateBufer()
        }
    }
    let opQueue = OperationQueue()
    var pointsBuffer: [CGPoint] = []
    
    func calculateBufferAsync(for coordinates: CoordinatesSet, with dataSource: GraphDataSource) {
        opQueue.cancelAllOperations()
        opQueue.addOperation { [weak self] in
            var points: [CGPoint] = []
            for x in coordinates {
                let y = CGFloat(dataSource.calculateY(forX: Double(x)))
                points.append(CGPoint(x: x, y: y))
            }
            self?.pointsBuffer = points
            DispatchQueue.main.async {
                self?.setNeedsDisplay()
            }
        }
    }
    
    func recalculateBufer() {
        guard let dataSource = graphDataSource else {
            return
        }
        let coordinates = CoordinatesSet(center: CGPoint(x: bounds.width/2, y: bounds.height/2),
                                         halfWidth: bounds.width/2,
                                         halfHeight: bounds.height/2,
                                         pointsPerUnit: 50.0 * scale)
        calculateBufferAsync(for: coordinates, with: dataSource)
        DispatchQueue.main.async { [weak self] in
            self?.setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        axesDrawer.drawAxes(in: bounds, origin: CGPoint(x: bounds.width/2, y: bounds.height/2), pointsPerUnit: 50.0 * scale)
        drawBorder()

        let coordinates = CoordinatesSet(center: CGPoint(x: bounds.width/2, y: bounds.height/2),
                                         halfWidth: bounds.width/2,
                                         halfHeight: bounds.height/2,
                                         pointsPerUnit: 50.0 * scale)
        UIGraphicsGetCurrentContext()?.saveGState()
        let path = UIBezierPath()
        var firstPoint = true
        for pointInUnits in pointsBuffer {
            if let point = coordinates.convertToCGPointFromUnits(xUnit: pointInUnits.x, yUnit: pointInUnits.y), point.x.isFinite, point.y.isFinite  {
                if firstPoint {
                    path.move(to: point)
                    firstPoint = false
                } else {
                    path.addLine(to: point)
                }
            }
        }
        path.stroke()
        UIGraphicsGetCurrentContext()?.restoreGState()
    }
    
    private func drawBorder() {
        UIGraphicsGetCurrentContext()?.saveGState()
        let points = [CGPoint(x: bounds.minX, y: bounds.minY),
                      CGPoint(x: bounds.maxX, y: bounds.minY),
                      CGPoint(x: bounds.maxX, y: bounds.maxY),
                      CGPoint(x: bounds.minX, y: bounds.maxY)]
        
        let path = UIBezierPath()
        path.move(to: points[0])
        path.addLine(to: points[1])
        path.addLine(to: points[2])
        path.addLine(to: points[3])
        path.addLine(to: points[0])
        path.stroke()
        UIGraphicsGetCurrentContext()?.restoreGState()
    }
}
