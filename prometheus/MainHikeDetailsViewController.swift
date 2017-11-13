//
//  MainHikeDetailsViewController.swift
//  prometheus
//
//  Created by Joel Whitney on 11/7/17.
//  Copyright © 2017 JoelWhitney. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import MapKit

class MainHikeDetailsViewController: SlidingPanelViewController {
    var hike: Hike? {
        didSet {
            print("mhdVC hike set")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.panelPosition = .summary
        setChildren(hike: hike!)
    }
    
    func setChildren(hike: Hike) {
        guard let mapViewController = childViewControllers.first(where: { $0 is MapViewController }) as? MapViewController,
            let hikeDetailsViewController = childViewControllers.first(where: { $0 is HikeDetailsController }) as? HikeDetailsController else {
                return
        }
        mapViewController.hike = hike
        hikeDetailsViewController.hike = hike
    }

    override var slidingPanelFullHeight: CGFloat {
        return super.slidingPanelFullHeight
    }
    
    override var slidingPanelPartialHeight: CGFloat {
        return super.slidingPanelPartialHeight
    }
    
    override func updateSlidingPanelPosition() {
        super.updateSlidingPanelPosition()
    }
    
    @IBAction func unwindToMainViewController(segue: UIStoryboardSegue) {
    }
    
    
}
