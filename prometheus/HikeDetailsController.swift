//
//  HikeDetailsController.swift
//  prometheus
//
//  Created by Joel Whitney on 11/4/17.
//  Copyright © 2017 JoelWhitney. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

class HikeDetailsController: UIViewController, SlidingPanelContentProvider {
    var contentScrollView: UIScrollView? {
        return tableView
    }

    var summaryHeight: CGFloat = 115
    var hike: Hike?  {
        didSet {
            populateHeaderDetails()
            getWeather()
        }
    }
    var currentWeather: CurrentWeather? {
        didSet {
            DispatchQueue.main.async {
                self.populateHeaderDetails()
                self.tableView.reloadData()
            }
        }
    }
    var forecastWeather: JSON? {
        didSet {
            DispatchQueue.main.async {
                self.populateHeaderDetails()
                self.tableView.reloadData()
            }
        }
    }
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var endLabel: UILabel!
    

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func getWeather() {
        OpenWeatherMapAPI.sharedInstance.current_latlon_weather(lat: (hike?.place.coordinate.latitude)!, lon: (hike?.place.coordinate.longitude)!, onCompletion: { (currentWeatherJSON: JSON) in
            self.currentWeather = CurrentWeather(currentWeatherJSON)
        })
        OpenWeatherMapAPI.sharedInstance.forecast5_latlon_weather(lat: (hike?.place.coordinate.latitude)!, lon: (hike?.place.coordinate.longitude)!, onCompletion: { (json: JSON) in
            self.forecastWeather = json
        })
    }
    
    func populateHeaderDetails() {
        if let hikeDetails = hike {
            locationLabel.text = hikeDetails.trail.name
            startLabel.text = returnDatePickerLabel(date: (hikeDetails.start))
            endLabel.text = returnDatePickerLabel(date: (hikeDetails.end))
        }
    }
    
    func returnDatePickerLabel(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "EST")
        formatter.dateFormat = "MMM d, yyyy  h:mm a"
        return formatter.string(from: date)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? MapViewController {
            if let currentHike = hike {
                viewController.hike = currentHike
            }
        }
        if let viewController = segue.destination as? WeatherDetailsController {
            viewController.currentWeather = self.currentWeather
        }
    }
    
}

// MARK: - Table view data source
extension HikeDetailsController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            // weather
            let cell = tableView.dequeueReusableCell(withIdentifier: "WeatherTableCell", for: indexPath) as! WeatherTableCell
            cell.weatherIcon.downloadedFrom(link: "https://openweathermap.org/img/w/\(String(describing: currentWeather?.weatherIcon)).png")
            cell.currentTemp.text = String(describing: currentWeather?.temperature) + "°"
            cell.currentTempRange.text = "\(String(describing: currentWeather?.tempatureMin)) ° / \(String(describing: currentWeather?.temperatureMax))°"
            cell.currentWeatherDesc.text = currentWeather?.weatherDescription
            return cell
        }
        if indexPath.row == 1 {
            // checklist
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChecklistCell", for: indexPath) as! ChecklistCell
            return cell
        }
        else {
            // gear recommendations
            let cell = tableView.dequeueReusableCell(withIdentifier: "GearRecommendationsCell", for: indexPath) as! GearRecommendationsCell
            return cell
        }
    }
    

    @IBAction func unwindToHikeDetailsController(segue: UIStoryboardSegue) {
        //
    }
}



extension HikeDetailsController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let slidingPanelViewController = parent as? SlidingPanelViewController {
            slidingPanelViewController.panelContentDidScroll(self, scrollView: scrollView)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let slidingPanelViewController = parent as? SlidingPanelViewController {
            slidingPanelViewController.panelContentWillBeginDecelerating(self, scrollView: scrollView)
        }
    }
}


class WeatherTableCell: UITableViewCell {
    
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var currentTemp: UILabel!
    @IBOutlet weak var currentTempRange: UILabel!
    @IBOutlet weak var currentWeatherDesc: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

class GearRecommendationsCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

class ChecklistCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
