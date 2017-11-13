//
//  MapViewController.swift
//  prometheus
//
//  Created by Joel Whitney on 11/7/17.
//  Copyright © 2017 JoelWhitney. All rights reserved.
//

import Foundation
import Mapbox
import SwiftyJSON
import MapKit
import Alamofire

class MapViewController: UIViewController, MGLMapViewDelegate {
    var hike: Hike!   {
        didSet {
            loadDefaultMap(hike: hike)
            getHikingTrail()
        }
    }
    var hikingTrail: MGLPolyline! {
        didSet {
            DispatchQueue.main.async(execute: {
                let pointAnnotations = [self.hike.trail.startPoint!, self.hike.trail.endPoint!, self.hikingTrail!] as! [MGLAnnotation]
                self.mapView.addAnnotations(pointAnnotations)
                self.adjustMaptoTrail(trail: self.hike.trail)
                if !self.isMapDownloaded()  {
                    self.startOfflinePackDownload()
                }
            })
        }
    }
    var mapView: MGLMapView!
    var progressView: UIProgressView!
    var mapBounds: MGLCoordinateBounds!
    var status = "online"
    var downloadedMapBounds: MGLCoordinateBounds!
    var coordinates: [CLLocationCoordinate2D]! {
        didSet {
            print("coordinates set")
            print(coordinates)

        }
    }
    let reachabilityManager = NetworkReachabilityManager()
    
    @IBOutlet weak var downloadedImage: UIImageView!
    @IBOutlet weak var offlineView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.sendSubview(toBack: offlineView)
        listenForReachability()
    }
    
    func listenForReachability() {
        self.reachabilityManager!.listener = { status in
            switch status {
            case .notReachable:
                print("The network is not reachable")
                self.onInternetDisconnection()
            case .unknown :
                print("It is unknown whether the network is reachable")
                self.onInternetDisconnection() // not sure what to do for this case
            case .reachable(.ethernetOrWiFi):
                print("The network is reachable over the WiFi connection")
                self.onInternetConnection()
            case .reachable(.wwan):
                print("The network is reachable over the WWAN connection")
                self.onInternetConnection()
            }
        }
        self.reachabilityManager?.startListening()
    }
    
    func onInternetDisconnection() {
        // present offline view
        // set map bpunds to DLed area
        mapView.setVisibleCoordinateBounds(downloadedMapBounds, animated: true)
        status = "offline"
        view.bringSubview(toFront: offlineView)
    }
    
    func onInternetConnection() {
        // if was offline remove offline view and show online temporarily
        // remove map bounds
        // mapBounds = mapView.coord
        status = "online"
        view.sendSubview(toBack: offlineView)
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        //startOfflinePackDownload()
    }
    
    func mapView(_ mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        // Set the alpha for all shape annotations to 1 (full opacity)
        return 1
    }
    
    func mapView(_ mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat {
        // Set the line width for polyline annotations
        return 2.0
    }
    
    
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        switch annotation.title! {
        case "green", "greenBlue":
            return UIColor(red: 79/255, green: 147/255, blue: 63/255, alpha: 1.0)
        case "blue", "blueBlack":
            return UIColor(red: 62/255, green: 76/255, blue: 145/255, alpha: 1.0)
        case "black":
            return UIColor(red: 14/255, green: 33/255, blue: 25/255, alpha: 1.0)
        default:
            return UIColor(red: 221/255, green: 221/255, blue: 221/255, alpha: 1.0)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func adjustMaptoTrail(trail: Trail) {
        // map center
        mapView.setVisibleCoordinateBounds(trail.coordinateBounds!, animated: false)
        let newZoom = mapView.zoomLevel - 2
        mapView.setCenter(mapView.centerCoordinate, zoomLevel: newZoom, animated: false)
        // map bounds
        mapBounds = mapView.visibleCoordinateBounds
        downloadedMapBounds = mapBounds
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        let annotationView = MGLAnnotationView()
        annotationView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        annotationView.layer.cornerRadius = (annotationView.frame.size.width) / 2
        annotationView.layer.borderWidth = 2.0
        annotationView.layer.borderColor = UIColor.white.cgColor
        if annotation.title! == "Trail Start" {
            annotationView.backgroundColor = UIColor(red: 90/255, green: 173/255, blue: 102/255, alpha: 1.0)
        } else {
            annotationView.backgroundColor = UIColor(red: 196/255, green: 125/255, blue: 102/255, alpha: 1.0)
        }
        return annotationView
    }
    
    func loadDefaultMap(hike: Hike) {
        mapView = MGLMapView(frame: view.bounds, styleURL: MGLStyle.outdoorsStyleURL())
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.tintColor = .gray
        mapView.delegate = self
        view.addSubview(mapView)
        
        // map center
        let center = CLLocationCoordinate2D(latitude: (hike.trail.latitude)!, longitude: (hike.trail.longitude)!)
        mapView.setCenter(center, zoomLevel: 11, animated: false)
        // map bounds
        mapBounds = mapView.visibleCoordinateBounds
        mapView.allowsTilting = false
        // Setup offline pack notification handlers.
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackProgressDidChange), name: NSNotification.Name.MGLOfflinePackProgressChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveError), name: NSNotification.Name.MGLOfflinePackError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveMaximumAllowedMapboxTiles), name: NSNotification.Name.MGLOfflinePackMaximumMapboxTilesReached, object: nil)
        
        downloadedImage.image = #imageLiteral(resourceName: "downloaded")
    }
    
    
    func getHikingTrail() {
        HikingProjectAPI.sharedInstance.get_trail_details(ids: [(hike?.trail.id)!], onCompletion: { (json: JSON) in
            guard let trailDetails = json.array?[0] else {
                return
            }
            self.hike.trail.updateTrailDetails(trailJSON: trailDetails) {
                self.hikingTrail = self.hike.trail.trail
            }
        })
    }
    
    func isMapDownloaded() -> Bool {
        view.sendSubview(toBack: downloadedImage)
        guard MGLOfflineStorage.shared().packs?.first(where: { (NSKeyedUnarchiver.unarchiveObject(with: $0.context) as! [String: String])["trailId"] == String(describing: hike?.trail.id)  }) != nil else {
            return false
        }
        print("Map already downloaded! ;-)")
        view.bringSubview(toFront: downloadedImage)
        return true
    }
    
    func startOfflinePackDownload() {
        let region = MGLTilePyramidOfflineRegion(styleURL: mapView.styleURL, bounds: mapView.visibleCoordinateBounds, fromZoomLevel: mapView.zoomLevel, toZoomLevel: 16)
        
        // store locally for trail
        let mapInfo = ["trailId": String(describing: hike?.trail.id)]
        let context = NSKeyedArchiver.archivedData(withRootObject: mapInfo)
        
        // create and register an offline pack with the shared offline storage object.
        MGLOfflineStorage.shared().addPack(for: region, withContext: context) { (pack, error) in
            guard error == nil else {
                // The pack couldn’t be created for some reason.
                print("Error: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            // start downloading.
            pack!.resume()
        }
        
    }
    
    // MARK: - MGLOfflinePack notification handlers
    @objc func offlinePackProgressDidChange(notification: NSNotification) {
        // Get the offline pack this notification is regarding,
        // and the associated user info for the pack; in this case, `name = My Offline Pack`
        if let pack = notification.object as? MGLOfflinePack,
            let mapInfo = NSKeyedUnarchiver.unarchiveObject(with: pack.context) as? [String: String] {
            let progress = pack.progress
            // or notification.userInfo![MGLOfflinePackProgressUserInfoKey]!.MGLOfflinePackProgressValue
            let completedResources = progress.countOfResourcesCompleted
            let expectedResources = progress.countOfResourcesExpected
            
            // Calculate current progress percentage.
            let progressPercentage = Float(completedResources) / Float(expectedResources)
            
            // Setup the progress bar.
            if progressView == nil {
                progressView = UIProgressView(progressViewStyle: .default)
                let frame = view.bounds.size
                progressView.frame = CGRect(x: frame.width / 4, y: frame.height * 0.02, width: frame.width / 2, height: 10)
                view.addSubview(progressView)
            }
            
            progressView.progress = progressPercentage

            // If this pack has finished, print its size and resource count.
            if completedResources == expectedResources {
                let byteCount = ByteCountFormatter.string(fromByteCount: Int64(pack.progress.countOfBytesCompleted), countStyle: ByteCountFormatter.CountStyle.memory)
                print("Offline pack “\(mapInfo["trailId"] ?? "unknown")” completed: \(byteCount), \(completedResources) resources")
                progressView.removeFromSuperview()
                view.bringSubview(toFront: downloadedImage)
            } else {
                // Otherwise, print download/verification progress.
                print("Offline pack “\(mapInfo["trailId"] ?? "unknown")” has \(completedResources) of \(expectedResources) resources — \(progressPercentage * 100)%.")
            }
        }
    }
    
    @objc func offlinePackDidReceiveError(notification: NSNotification) {
        if let pack = notification.object as? MGLOfflinePack,
            let mapInfo = NSKeyedUnarchiver.unarchiveObject(with: pack.context) as? [String: String],
            let error = notification.userInfo?[MGLOfflinePackUserInfoKey.error] as? NSError {
            print("Offline pack “\(mapInfo["trailId"] ?? "unknown")” received error: \(error.localizedFailureReason ?? "unknown error")")
        }
    }
    
    @objc func offlinePackDidReceiveMaximumAllowedMapboxTiles(notification: NSNotification) {
        if let pack = notification.object as? MGLOfflinePack,
            let mapInfo = NSKeyedUnarchiver.unarchiveObject(with: pack.context) as? [String: String],
            let maximumCount = (notification.userInfo?[MGLOfflinePackUserInfoKey.maximumCount] as AnyObject).uint64Value {
            print("Offline pack “\(mapInfo["trailId"] ?? "unknown")” reached limit of \(maximumCount) tiles.")
        }
    }

    
    func mapView(_ mapView: MGLMapView, shouldChangeFrom oldCamera: MGLMapCamera, to newCamera: MGLMapCamera) -> Bool {

        // Get the current camera to restore it after.
        let currentCamera = mapView.camera

        // From the new camera obtain the center to test if it’s inside the boundaries.
        let newCameraCenter = newCamera.centerCoordinate

        // Set the map’s visible bounds to newCamera.
        mapView.camera = newCamera
        let newVisibleCoordinates = mapView.visibleCoordinateBounds

        // Revert the camera.
        mapView.camera = currentCamera

        // Test if the newCameraCenter and newVisibleCoordinates are inside self.mapBounds
        let inside = MGLCoordinateInCoordinateBounds(newCameraCenter, self.mapBounds)
        let intersects = MGLCoordinateInCoordinateBounds(newVisibleCoordinates.ne, self.mapBounds) && MGLCoordinateInCoordinateBounds(newVisibleCoordinates.sw, self.mapBounds)

        // set bounds if offline
        if status == "offline" {
            return (inside && intersects)
        } else {
            return true
        }
    }
    
}

