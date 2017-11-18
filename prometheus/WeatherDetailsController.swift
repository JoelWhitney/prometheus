//
//  WeatherDetailsController.swift
//  prometheus
//
//  Created by Joel Whitney on 11/12/17.
//  Copyright © 2017 JoelWhitney. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

class WeatherDetailsController: UIViewController {
    var currentWeather: CurrentWeather!
    @IBOutlet weak var currentWeatherTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let weather = currentWeather else {
            return
        }
        currentWeatherTextView.text = currentWeather.weatherDescription
    }
    
    @IBAction func close(_ sender: Any) {
        performSegue(withIdentifier: "unwindToHikeDetailsController", sender: nil)
    }
}
