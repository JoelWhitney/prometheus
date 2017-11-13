//
//  HikingProjectAPI.swift
//  prometheus
//
//  Created by Joel Whitney on 11/6/17.
//  Copyright © 2017 JoelWhitney. All rights reserved.
//

import Foundation
import SwiftyJSON


// https://www.hikingproject.com/data
class HikingProjectAPI: NSObject {
    static let sharedInstance = HikingProjectAPI()
    let baseURL = "https://www.hikingproject.com"
    let api_key = "200140862-d451ee625ebfe21edf391811b0c34988"
    
    //https://www.hikingproject.com/api?action=getTrails&apiVersion=2&deviceId=F688EE26-965C-4F15-B14F-E9487A417697&ids=7036753&os=iOS&osVersion=11.1&v=3.1.10
    
    
    // MARK: - GET METHODS
    //    maxDistance - Max distance, in miles, from lat, lon. Default: 30. Max: 200.
    //    maxResults - Max number of trails to return. Default: 10. Max: 500.
    //    sort - Values can be 'quality', 'distance'. Default: quality.
    //    minLength - Min trail length, in miles. Default: 0 (no minimum).
    //    minStars - Min star rating, 0-4. Default: 0.
    func get_trails(lat: Double, lon: Double, maxResults: Int = 60, onCompletion: @escaping (JSON) -> Void) {
        let search_path = "/data/get-trails?"
        let parameters = [["name": "lat", "value": String(lat)],
                          ["name": "lon", "value": String(lon)],
                          ["name": "sort", "value": "distance"],
                          ["name": "maxResults", "value": String(maxResults)],
                          ["name": "key", "value": api_key]]
        makeHTTPGetRequest(url: baseURL + search_path, parameters: parameters, onCompletion: { json, err in
            onCompletion(json as JSON)
        })
    }
    
    func get_trail_details(ids: Array<Int>, onCompletion: @escaping (JSON) -> Void) {
        let search_path = "/api?"
        let parameters = [["name": "action", "value": "getTrails"],
                          ["name": "apiVersion", "value": "2"],
                          ["name": "deviceId", "value": "F685E26-965C-515-B14F-E945417697"],
                          ["name": "ids", "value": ids.map({"\($0)"}).joined(separator: ",")],
                          ["name": "os", "value": "iOS"],
                          ["name": "osVersion", "value": "11.1"],
                          ["name": "v", "value": "3.1.10"]]
        makeHTTPGetRequest(url: baseURL + search_path, parameters: parameters, onCompletion: { json, err in
            onCompletion(json as JSON)
        })
    }
    
    func get_conditions(ids: Array<Int>, onCompletion: @escaping (JSON) -> Void) {
        let search_path = "/data/get-conditions?"
        let parameters = [["name": "ids", "value": ids.map({"\($0)"}).joined(separator: ",")],
                          ["name": "key", "value": api_key]]
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
