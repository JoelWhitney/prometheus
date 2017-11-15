//
//  DataModels.swift
//  prometheus
//
//  Created by Joel Whitney on 11/4/17.
//  Copyright © 2017 JoelWhitney. All rights reserved.
//

import Foundation
import SwiftyJSON
import GooglePlaces
import Mapbox
import ArcGIS
import UIKit

class Place: NSObject {
    let id: String
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    
    init(_ place: GMSPlace) {
        self.id = place.placeID
        self.name = place.name
        self.address = place.formattedAddress ?? ""
        self.coordinate = place.coordinate
        super.init()
    }
}

class HikeStore {
    // MARK: - variables/constants
    var hikes = [Hike]()
    let hikeArchiveURL: URL = {
        let documentsDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentsDirectories.first!
        return documentDirectory.appendingPathComponent("hikes.archive")
    }()
    
    // MARK: - initializers
    init() {
        if let archivedHikes = NSKeyedUnarchiver.unarchiveObject(withFile: hikeArchiveURL.path) as? [Hike] {
            print("Retrieving data from File System")
            hikes = archivedHikes
        }
        print(hikes)
    }
    
    // MARK: - class methods
    func removeHike(hike: Hike) {
        if let index = hikes.index(of: hike) {
            hikes.remove(at: index)
            print("hike removed from itemStore")
        }
        saveChanges()
    }
    
    func removeHike(_ item: Hike) {
        if let index = hikes.index(of: item) {
            hikes.remove(at: index)
            print("Item removed from itemStore")
        }
        saveChanges()
    }
    
    func removeAllHikes() {
        hikes = [Hike]()
        saveChanges()
    }
    
    func addHike(hike: Hike) {
        print("Adding \(hike) to URLItemStore")
        hikes.insert(hike, at: 0)
        saveChanges()
    }
    
    func saveChanges() -> Bool {
        print("Saving items to: \(hikeArchiveURL.path)")
        return NSKeyedArchiver.archiveRootObject(hikes, toFile: hikeArchiveURL.path)
    }
}

class Hike: NSObject, NSCoding {
    let hikeKey: String
    let place: Place
    let start: Date
    let end: Date
    var trail: Trail
    
    init(place: Place, trail: Trail, start: Date, end: Date) {
        self.hikeKey = UUID().uuidString
        self.place = place
        self.trail = trail
        self.start = start
        self.end = end
    }
    
    required init(coder aDecoder: NSCoder) {
        hikeKey = aDecoder.decodeObject(forKey: "hikeKey") as! String
        place = aDecoder.decodeObject(forKey: "place") as! Place
        start = aDecoder.decodeObject(forKey: "start") as! Date
        end = aDecoder.decodeObject(forKey: "end") as! Date
        trail = aDecoder.decodeObject(forKey: "trail") as! Trail
        super.init()
        
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(hikeKey, forKey: "hikeKey")
        aCoder.encode(place, forKey: "place")
        aCoder.encode(start, forKey: "start")
        aCoder.encode(end, forKey: "end")
        aCoder.encode(trail, forKey: "trail")
    }
}

class Trail: NSObject {
    // initial api call details
    var name: String
    var id: Int?
    var type: String?
    var summary: String?
    var difficulty: String?
    var location: String?
    var length: Double?
    var ascent: Double?
    var descent: Double?
    var high: Double?
    var low: Double?
    var longitude: Double?
    var latitude: Double?
    
    // additional optionals from the hacked call
    var trail: MGLPolyline?
    var startPoint: MGLPointAnnotation?
    var endPoint: MGLPointAnnotation?
    var restrictions: String?
    var descrip: String?
    var coordinateBounds: MGLCoordinateBounds?
    var xMax: Double?
    var xMin: Double?
    var yMax: Double?
    var yMin: Double?
    var gradeAvg: Double?
    var gradeMax: Double?
    
    
    init(trailJSON: JSON) {
        self.id =  trailJSON["id"].int
        self.name = trailJSON["name"].string ?? ""
        self.type =  trailJSON["type"].string
        self.summary = trailJSON["summary"].string
        self.difficulty = trailJSON["difficulty"].string
        self.location = trailJSON["location"].string
        self.length = trailJSON["length"].double
        self.ascent = trailJSON["ascent"].double
        self.descent = trailJSON["descent"].double
        self.high = trailJSON["high"].double
        self.low = trailJSON["low"].double
        self.longitude = trailJSON["longitude"].double
        self.latitude = trailJSON["latitude"].double
        super.init()
    }
    
    init(name: String) {
        self.name = name
        super.init()
    }
    
    func updateTrailDetails(trailJSON: JSON, onCompletion: () -> Void) {
        self.trail = returnTrailGeometry(trailGeometryString: trailJSON["points"].string!)
        self.trail?.title = self.difficulty
        self.restrictions = trailJSON["restrictions"].string
        self.descrip = trailJSON["description"].string
        self.gradeAvg = trailJSON["gradeAvg"].double
        self.gradeMax = trailJSON["gradeMax"].double
        // bounding box
        let southWestWGS84 = mercatortoWGS84(x: trailJSON["xMin"].double!, y: trailJSON["yMin"].double!)
        let northEastWGS84 = mercatortoWGS84(x: trailJSON["xMax"].double!, y: trailJSON["yMax"].double!)
        let southWest = CLLocationCoordinate2D(latitude: southWestWGS84.y, longitude: southWestWGS84.x)
        let northEast = CLLocationCoordinate2D(latitude: northEastWGS84.y, longitude: northEastWGS84.x)
        self.coordinateBounds = MGLCoordinateBounds(sw: southWest, ne: northEast)
        onCompletion()
    }
    
    private func returnTrailGeometry(trailGeometryString: String) -> MGLPolyline {
        let trailCoord = trailGeometryString.replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
        let trainCoordString = String(describing: trailCoord)
        let coordinateList = trainCoordString.components(separatedBy: ",")
        var coordianteListConverted = [AGSPoint]()
        var counter = 0
        var x = 0.0
        var y = 0.0
        for coord in coordinateList {
            counter += 1
            if counter == 1 {
                x = Double(coord)!
            }
            if counter == 2 {
                y = Double(coord)!
                
            }
            if counter == 6 {
                let point = AGSPoint(x: x, y: y, spatialReference: .webMercator())
                let wgs84Point = AGSGeometryEngine.projectGeometry(point, to: .wgs84())
                coordianteListConverted.append(wgs84Point as! AGSPoint)
                counter = 0
                x = 0.0
                y = 0.0
            }
        }
        let convertedCoordinates = coordianteListConverted.map( { CLLocationCoordinate2D(latitude: $0.y, longitude: $0.x) } )
        // start
        self.startPoint = MGLPointAnnotation()
        self.startPoint?.coordinate = CLLocationCoordinate2D(latitude: (convertedCoordinates.first?.latitude)!, longitude: (convertedCoordinates.first?.longitude)!)
        self.startPoint?.title = "Trail Start"
        // end
        self.endPoint = MGLPointAnnotation()
        self.endPoint?.coordinate = CLLocationCoordinate2D(latitude: (convertedCoordinates.last?.latitude)!, longitude: (convertedCoordinates.last?.longitude)!)
        self.endPoint?.title = "Trail End"
        // return line
        return MGLPolyline(coordinates: convertedCoordinates, count: UInt(convertedCoordinates.count))
    }
    
    private func mercatortoWGS84(x: Double, y: Double) -> AGSPoint {
        let point = AGSPoint(x: x, y: y, spatialReference: .webMercator())
        return AGSGeometryEngine.projectGeometry(point, to: .wgs84()) as! AGSPoint
    }
}
