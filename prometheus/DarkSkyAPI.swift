//
//  DarkSkyAPI.swift
//  prometheus
//
//  Created by Joel Whitney on 11/4/17.
//  Copyright © 2017 JoelWhitney. All rights reserved.
//

import Foundation
import SwiftyJSON


// https://darksky.net/dev/docs
// https://api.darksky.net/forecast/[key]/[latitude],[longitude]
class DarkSkyAPI: NSObject {
    static let sharedInstance = DarkSkyAPI()
    let baseURL = "https://api.darksky.net"
    let api_key = "6b356357602fd6d0997d9af6a515f840"
    
    // MARK: - GET METHODS
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
    
    func current_latlon_weather(lat: String, lon: String, onCompletion: @escaping (JSON) -> Void) {
        let search_path = "/weather?"
        let parameters = [["name": "lat", "value": lat],
                          ["name": "lon", "value": lon],
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
