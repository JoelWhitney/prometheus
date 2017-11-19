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

class CurrentWeather {
    let sunrise: Double
    let sunset: Double
    let weatherMain: String
    let weatherDescription: String
    let weatherIcon: String
    let temperature: Double
    let humidity: Double
    let pressure: Double
    let tempatureMin: Double
    let temperatureMax: Double
    let windSpeed: Double
    let windDirection: Double
    let rain3h: Double
    let cloudCoverage: Double
    let weatherCity: String
    let weatherTime: Double
    
    init(_ currentWeatherJSON: JSON) {
        self.sunrise = currentWeatherJSON["sys"]["sunrise"].double ?? 0
        self.sunset = currentWeatherJSON["sys"]["sunset"].double ?? 0
        self.weatherMain = currentWeatherJSON["weather"][0]["main"].string ?? ""
        self.weatherDescription = currentWeatherJSON["weather"][0]["description"].string ?? ""
        self.weatherIcon = currentWeatherJSON["weather"][0]["icon"].string ?? ""
        self.temperature = currentWeatherJSON["main"]["temp"].double ?? 0
        self.humidity = currentWeatherJSON["main"]["humidity"].double ?? 0
        self.pressure = currentWeatherJSON["main"]["pressure"].double ?? 0
        self.tempatureMin = currentWeatherJSON["main"]["temp_min"].double ?? 0
        self.temperatureMax = currentWeatherJSON["main"]["temp_max"].double ?? 0
        self.windSpeed = currentWeatherJSON["wind"]["speed"].double ?? 0
        self.windDirection = currentWeatherJSON["wind"]["deg"].double ?? 0
        self.rain3h = currentWeatherJSON["rain"]["3h"].double ?? 0
        self.cloudCoverage = currentWeatherJSON["clouds"]["all"].double ?? 0
        self.weatherCity = currentWeatherJSON["name"].string ?? ""
        self.weatherTime = currentWeatherJSON["dt"].double ?? 0
        
    }
    
    func temperatureFahrenheit(_ temperatureKelvin: Double) -> Double {
        return temperatureKelvin * (9/5) - 459.67
    }
}

class Hike {
    let place: GMSPlace
    let start: Date
    let end: Date
    var trail: Trail
    
    init(place: GMSPlace, trail: Trail, start: Date, end: Date) {
        self.place = place
        self.trail = trail
        self.start = start
        self.end = end
    }
}

class Trail {
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
    var description: String?
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
    }
    
    init(name: String) {
        self.name = name
    }
    
    func updateTrailDetails(trailJSON: JSON, onCompletion: () -> Void) {
        self.trail = returnTrailGeometry(trailGeometryString: trailJSON["points"].string!)
        self.trail?.title = self.difficulty
        self.restrictions = trailJSON["restrictions"].string
        self.description = trailJSON["description"].string
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
