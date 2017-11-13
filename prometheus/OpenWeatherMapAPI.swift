//
//  OpenWeatherMapAPI.swift
//  prometheus
//
//  Created by Joel Whitney on 11/4/17.
//  Copyright © 2017 JoelWhitney. All rights reserved.
//


import Foundation
import SwiftyJSON

typealias ServiceResponse = (JSON, NSError?) -> Void

// https://openweathermap.org/api
class OpenWeatherMapAPI: NSObject {
    static let sharedInstance = OpenWeatherMapAPI()
    let baseURL = "https://api.openweathermap.org/data/2.5"
    let api_key = "f9e16166be587b0f02c0ead609552876"
    
    // MARK: - GET METHODS
    // current weather data
    // https://openweathermap.org/current#current_JSON
    func current_cityname_weather(cityname: String, onCompletion: @escaping (JSON) -> Void) {
        let search_path = "/weather?"
        let parameters = [["name": "q", "value": cityname], //Bangor
                          ["name": "appid", "value": api_key]]
        makeHTTPGetRequest(url: baseURL + search_path, parameters: parameters, onCompletion: { json, err in
            onCompletion(json as JSON)
        })
    }

    func current_citycode_weather(citycode: String, onCompletion: @escaping (JSON) -> Void) {
        let search_path = "/weather?"
        let parameters = [["name": "id", "value": citycode], //2656396
                          ["name": "appid", "value": api_key]]
        makeHTTPGetRequest(url: baseURL + search_path, parameters: parameters, onCompletion: { json, err in
            onCompletion(json as JSON)
        })
    }
    
    func current_latlon_weather(lat: Double, lon: Double, onCompletion: @escaping (JSON) -> Void) {
        let search_path = "/weather?"
        let parameters = [["name": "lat", "value": String(lat)],
                          ["name": "lon", "value": String(lon)],
                          ["name": "appid", "value": api_key]]
        makeHTTPGetRequest(url: baseURL + search_path, parameters: parameters, onCompletion: { json, err in
            onCompletion(json as JSON)
        })
    }
    
    // 5 day -- need paid api
    func forecast5_latlon_weather(lat: Double, lon: Double, onCompletion: @escaping (JSON) -> Void) {
        let search_path = "/forecast?"
        let parameters = [["name": "lat", "value": String(lat)],
                          ["name": "lon", "value": String(lon)],
                          ["name": "appid", "value": api_key]]
        makeHTTPGetRequest(url: baseURL + search_path, parameters: parameters, onCompletion: { json, err in
            onCompletion(json as JSON)
        })
    }
    
    // 16 day -- need paid api
    func forecast16_latlon_weather(lat: Double, lon: Double, days: Int, onCompletion: @escaping (JSON) -> Void) {
        let search_path = "/forecast/daily?"
        let parameters = [["name": "lat", "value": String(lat)],
                          ["name": "lon", "value": String(lon)],
                          ["name": "cnt", "value": String(days)],
                          ["name": "appid", "value": api_key]]
        makeHTTPGetRequest(url: baseURL + search_path, parameters: parameters, onCompletion: { json, err in
            onCompletion(json as JSON)
        })
    }
    
    // MARK: - MAIN GET REQUEST
    private func makeHTTPGetRequest(url: String, parameters: [[String: String]], onCompletion: @escaping ServiceResponse) {
        var urlComponents = URLComponents(string: url)!
        urlComponents.queryItems = []
        for parameter in parameters {
            urlComponents.queryItems?.append(URLQueryItem(name: parameter["name"]!, value: parameter["value"]!))
        }
        let requestURL = urlComponents.url
        print("       API request: " + (requestURL?.absoluteString ?? ""))
        let request = NSMutableURLRequest(url: requestURL!)
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            if let jsonData = data {
                let json = JSON(data: jsonData)
                onCompletion(json, error as NSError?)
            } else {
                onCompletion(JSON.null, error as NSError?)
            }
        })
        task.resume()
    }
}
