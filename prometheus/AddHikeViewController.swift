//
//  ViewController.swift
//  prometheus
//
//  Created by Joel Whitney on 11/4/17.
//  Copyright © 2017 JoelWhitney. All rights reserved.
//


import Foundation
import UIKit
import GooglePlaces

class AddHikeViewController: UITableViewController {
    var googlePlace: GMSPlace! {
        didSet {
            print("set place")
            populateDetails()
        }
    }
    var selectedTrail: Trail? {
        didSet {
            print("set trail")
            populateDetails()
        }
    }
    var startDate = Date()
    var endDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
    var showStartDatePicker = false
    var showEndDatePicker = false
    let locationManager = CLLocationManager()
    var delegate: isAbleToPassNewHike!

    @IBOutlet var createButton: UIButton!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet weak var trailLabel: UILabel!
    @IBOutlet var startLabel: UILabel!
    @IBOutlet var endLabel: UILabel!
    @IBOutlet var startDatePickerCell: UITableViewCell!
    @IBOutlet var startDatePicker: UIDatePicker!
    @IBOutlet var endDatePickerCell: UITableViewCell!
    @IBOutlet var endDatePicker: UIDatePicker!
    @IBAction func unwindToPlanTrip(segue: UIStoryboardSegue) {}
    @IBOutlet var cancelButton: UIBarButtonItem!
    
    @IBAction func cancelAddSchedule () {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func createHike () {
        print("hike createD")
        let hike = Hike(place: googlePlace, trail: selectedTrail!, start: startDate, end: endDate!)
        delegate.passHike(hike: hike)
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        populateDetails()
//        // Ask for Authorisation from the User.
//        self.locationManager.requestAlwaysAuthorization()
//
//        // For use in foreground
//        self.locationManager.requestWhenInUseAuthorization()
//
//        if CLLocationManager.locationServicesEnabled() {
//            locationManager.delegate = self
//            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
//            locationManager.startUpdatingLocation()
//        }
        tableView.tableFooterView = UIView()
    }
    
    func returnDatePickerLabel(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "EST")
        formatter.dateFormat = "MMM d, yyyy  h:mm a"
        return formatter.string(from: date)
    }
    
    func requirementsMet() -> Bool {
        return googlePlace != nil
    }
    
    func populateDetails() {
        if let placeName = googlePlace?.name {
            print("place is googleplace")
            locationLabel.text = placeName
        } else {
            print("place is NOT googleplace")
            locationLabel.text = "Choose Location >"
        }
        if let trail = selectedTrail {
            trailLabel.text = trail.name
        } else {
            trailLabel.text = "Select Trail >"
        }
        startDatePicker.addTarget(self, action: #selector(startDateValueChanged), for: UIControlEvents.valueChanged)
        startDatePicker.date = startDate
        startLabel.text = returnDatePickerLabel(date: startDate)
        endDatePicker.addTarget(self, action: #selector(endDateValueChanged), for: UIControlEvents.valueChanged)
        endDatePicker.date = endDate!
        endLabel.text = returnDatePickerLabel(date: endDate!)
        if requirementsMet() {
            enableCreateButton()
        } else {
            disableCreateButton()
        }
    }
    
    @objc func startDateValueChanged() {
        startDate = startDatePicker.date
        startLabel.text = returnDatePickerLabel(date: startDate)
        if startDate > endDate! {
            print("passed end")
            endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)
            endDatePicker.date = endDate!
            endLabel.text = returnDatePickerLabel(date: endDate!)
        }
    }
    
    @objc func endDateValueChanged() {
        endDate = endDatePicker.date
        endLabel.text = returnDatePickerLabel(date: endDate!)
    }
    
    func enableCreateButton() {
        createButton.isEnabled = true
        createButton.isUserInteractionEnabled = true
        createButton.backgroundColor = UIColor(red: 0.0/255.0, green: 107.0/255.0, blue: 161.0/255.0, alpha: 1.0)
    }
    
    func disableCreateButton() {
        createButton.isEnabled = false
        createButton.isUserInteractionEnabled = false
        createButton.backgroundColor = UIColor.lightGray
    }
    
    func showStartDatePickerCell(onComplete: () -> Void) {
        if showEndDatePicker { showEndDatePickerCell() {} }
        if showStartDatePicker {
            showStartDatePicker = false
            startLabel.textColor = UIColor.lightGray
        }
        else {
            showStartDatePicker = true
            startLabel.textColor = UIColor.red
        }
        onComplete()
    }
    
    func showEndDatePickerCell(onComplete: () -> Void) {
        if showStartDatePicker{ showStartDatePickerCell() {}}
        if showEndDatePicker {
            showEndDatePicker = false
            endLabel.textColor = UIColor.lightGray
        }
        else {
            showEndDatePicker = true
            endLabel.textColor = UIColor.red
        }
        onComplete()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if let mainHikeVC = segue.destination as? MainHikeDetailsViewController {
//            let currentHike = Hike(place: googlePlace!, trail: selectedTrail!, start: startDate, end: endDate!)
//            mainHikeVC.hike = currentHike
//            print(mainHikeVC.hike)
//        }
        if let destController = segue.destination as? SelectTrailViewController {
            destController.currentPlace = googlePlace
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let acController = GMSAutocompleteViewController()
            acController.delegate = self
            present(acController, animated: true, completion: nil)
        }
        if indexPath.row == 2 {
            showStartDatePickerCell() {
                DispatchQueue.main.async(execute: {
                    tableView.reloadData()
                })
            }
        }
        if indexPath.row == 4 {
            showEndDatePickerCell() {
                DispatchQueue.main.async(execute: {
                    tableView.reloadData()
                })
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if cell == self.startDatePickerCell, showStartDatePicker == false {
            return 0
        }
        if cell == self.endDatePickerCell, showEndDatePicker == false {
            return 0
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
}

extension AddHikeViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("locations = \(locValue.latitude) \(locValue.longitude)")
    }
}

extension AddHikeViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress)")
        print("Place attributions: \(place.attributions)")
        print("Place coordinates: \(place.coordinate)")
        self.googlePlace = place
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: \(error)")
        dismiss(animated: true, completion: nil)
    }
    
    // User cancelled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        print("Autocomplete was cancelled.")
        dismiss(animated: true, completion: nil)
    }
}
