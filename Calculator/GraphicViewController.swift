//
//  GraphicViewController.swift
//  Calculator
//
//  Created by Sergei Kultenko on 05/09/2017.
//  Copyright © 2017 Sergey Kultenko. All rights reserved.
//

import UIKit

class GraphicViewController: UIViewController, UIScrollViewDelegate
{
    let kGraphicSettingsKey = "GraphicSettingsKey"
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
        }
    }
    
    private var lastScrollViewContentOffset: CGPoint = CGPoint.zero
    
    @IBOutlet weak var graphicView: GraphicView!
    
    public var graphDataSource: GraphDataSource? {
        didSet {
            graphicView?.graphDataSource = graphDataSource
            navigationItem.title = graphDataSource?.description
        }
    }

    var settingsLoaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false
        graphicView?.graphDataSource = graphDataSource
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !settingsLoaded {
            _ = loadSettings()
            settingsLoaded = true
        }
        if graphicView.scale <= 1 {
            graphicView.frame = scrollView.bounds
            scrollView.contentSize = graphicView.frame.size
            scrollView.contentOffset = CGPoint.zero
            graphicView.setNeedsDisplay()
        }
    }

    @IBAction func scaleChangeAction(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .began {
            sender.scale = graphicView.scale
        } else {
            if sender.scale < 4 && sender.scale > 0.1 {
                if sender.scale < 1 {
                    graphicView.frame = scrollView.bounds
                    scrollView.contentSize = graphicView.frame.size
                    scrollView.contentOffset = CGPoint.zero
                } else {
                    let graphicNewWidth = view.frame.width * sender.scale
                    let graphicNewHeight = view.frame.height * sender.scale
                    
                    graphicView.frame = CGRect(x: 0, y: 0, width: graphicNewWidth, height: graphicNewHeight)
                    scrollView.contentSize = CGSize(width: graphicNewWidth, height: graphicNewHeight)
                    scrollView.contentOffset = CGPoint(x: graphicNewWidth/2 - scrollView.frame.width/2 , y: graphicNewHeight/2 - scrollView.frame.height/2)
                }
                graphicView.setNeedsDisplay()
                graphicView.scale = sender.scale
            }
        }
        saveSettings()
    }
    
    @IBAction func doubleTapAction(_ sender: UITapGestureRecognizer) {
        let centerPoint = sender.location(in: view)
        scrollView.contentOffset = CGPoint(x: graphicView.frame.width/2 - centerPoint.x , y: graphicView.frame.height/2 - centerPoint.y)
        saveSettings()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        lastScrollViewContentOffset = scrollView.contentOffset
        saveSettings()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
//        if UIDevice.current.orientation.isLandscape {
//            print("Landscape \(size)")
//        } else {
//            print("Portrait \(size)")
//        }
    }
    
    @objc func deviceOrientationDidChange() {
//        switch UIDevice.current.orientation {
//        case .faceDown:
//            print("Face down")
//        case .faceUp:
//            print("Face up")
//        case .unknown:
//            print("Unknown")
//        case .landscapeLeft:
//            print("Landscape left")
//        case .landscapeRight:
//            print("Landscape right")
//        case .portrait:
//            print("Portrait")
//        case .portraitUpsideDown:
//            print("Portrait upside down")
//        }
    }
    
    func saveSettings() {
        guard settingsLoaded else {
            return
        }
        let graphicSettings = GraphicSettings(graphicViewFrame: graphicView.frame,
                                              scrollViewContentSize: scrollView.contentSize,
                                              scrollViewContentOffset: scrollView.contentOffset,
                                              scale: graphicView.scale)
        //print("saved \(graphicSettings)")
        UserDefaults.standard.set(graphicSettings.encode(), forKey: kGraphicSettingsKey)
        UserDefaults.standard.synchronize()
    }
    
    func loadSettings()->Bool {
        guard
            let graphicSettingsData = UserDefaults.standard.object(forKey: kGraphicSettingsKey) as? Data,
            let graphicSettings = GraphicSettings(data:graphicSettingsData)
        else {
            return false
        }
        graphicView.frame = graphicSettings.graphicViewFrame
        scrollView.contentSize = graphicSettings.scrollViewContentSize
        scrollView.contentOffset = graphicSettings.scrollViewContentOffset
        graphicView.scale = graphicSettings.scale
        return true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
}

struct GraphicSettings: Codable {
    let graphicViewFrame: CGRect
    let scrollViewContentSize: CGSize
    let scrollViewContentOffset: CGPoint
    let scale: CGFloat
    
    init(graphicViewFrame: CGRect, scrollViewContentSize: CGSize, scrollViewContentOffset: CGPoint, scale: CGFloat) {
        self.graphicViewFrame = graphicViewFrame
        self.scrollViewContentSize = scrollViewContentSize
        self.scrollViewContentOffset = scrollViewContentOffset
        self.scale = scale
    }
    
    init?(data: Data) {
        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode(GraphicSettings.self, from: data) {
            self = decoded
        } else {
            return nil
        }
    }
    
    func encode() -> Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }
    

}

//extension GraphicSettings {
//    init?(data: Data) {
//        if let coding = NSKeyedUnarchiver.unarchiveObject(with: data) as? GraphicSettingsEncoding {
//            graphicViewFrame = coding.graphicViewFrame as CGRect
//            scrollViewContentSize = coding.scrollViewContentSize as CGSize
//            scrollViewContentOffset = coding.scrollViewContentOffset as CGPoint
//            scale = coding.scale as CGFloat
//        } else {
//            return nil
//        }
//    }
//
//    func encode() -> Data {
//        return NSKeyedArchiver.archivedData(withRootObject: GraphicSettingsEncoding(self))
//    }
//
//    private class GraphicSettingsEncoding: NSObject, NSCoding {
//        let graphicViewFrame: CGRect
//        let scrollViewContentSize: CGSize
//        let scrollViewContentOffset: CGPoint
//        let scale: CGFloat
//
//        init(_ graphicSettings: GraphicSettings) {
//            graphicViewFrame = graphicSettings.graphicViewFrame
//            scrollViewContentSize = graphicSettings.scrollViewContentSize
//            scrollViewContentOffset = graphicSettings.scrollViewContentOffset
//            scale = graphicSettings.scale
//        }
//
//        required init?(coder aDecoder: NSCoder) {
//            graphicViewFrame = aDecoder.decodeCGRect(forKey: "graphicViewFrame")
//            scrollViewContentSize = aDecoder.decodeCGSize(forKey: "scrollViewContentSize")
//            scrollViewContentOffset = aDecoder.decodeCGPoint(forKey: "scrollViewContentOffset")
//            scale = CGFloat(aDecoder.decodeFloat(forKey: "scale"))
//        }
//
//        public func encode(with aCoder: NSCoder) {
//            aCoder.encode(graphicViewFrame, forKey: "graphicViewFrame")
//            aCoder.encode(scrollViewContentSize, forKey: "scrollViewContentSize")
//            aCoder.encode(scrollViewContentOffset, forKey: "scrollViewContentOffset")
//            aCoder.encode(Float(scale), forKey: "scale")
//        }
//    }
//}
