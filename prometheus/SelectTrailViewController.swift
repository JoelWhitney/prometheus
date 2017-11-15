//
//  SelectTrailViewController.swift
//  prometheus
//
//  Created by Joel Whitney on 11/6/17.
//  Copyright © 2017 JoelWhitney. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import GooglePlaces

class SelectTrailViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var tableView: UITableView!
    
    // MARK: - Variables
    var currentPlace: Place!
    var filterHandler: ((String?) -> Void)?
    private var trails: [Trail] = [] {
        didSet {
            DispatchQueue.main.async {
                self.applyFilter()
            }
        }
    }
    var filteredTrails: [Trail] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    var selectedIndexPath: IndexPath!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        getTrails()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - Methods
    func getTrails(){
        if let place = currentPlace {
            HikingProjectAPI.sharedInstance.get_trails(lat: place.coordinate.latitude, lon: place.coordinate.longitude, maxResults: 60, onCompletion: { (json: JSON) in
                guard let results = json["trails"].array else {
                    return
                }
                self.trails = results.map { Trail(trailJSON: $0) }
            })
        }
    }

    func applyFilter() {
        guard let searchText = searchBar.text?.lowercased(), !searchText.isEmpty else {
            filteredTrails = trails
            //filteredTrails = trails.sorted(by: { $0.name < $1.name })
            filterHandler?(nil)
            return
        }
        filteredTrails = trails.filter { $0.name.lowercased().contains(searchText)}
            //.sorted(by: { $0.name < $1.name })
        filterHandler?(searchText)
    }
    
    // MARK: - Override methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? AddHikeViewController {
            if selectedIndexPath.row == 0 {
                let newTrail = Trail(name: searchBar.text!)
                viewController.selectedTrail = newTrail
            } else {
                let trail = filteredTrails[selectedIndexPath.row - 1]
                viewController.selectedTrail = trail
            }
        }
    }
}

// MARK: - Table view data source
extension SelectTrailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard filteredTrails.count != 0 || searchBar.text != "" else {
            return 0
        }
        return filteredTrails.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = self.tableView!.dequeueReusableCell(withIdentifier: "NewTrailCell", for: indexPath) as! NewTrailCell
            cell.detailsLabel.text = "Add new trail "
            cell.secondaryDetailsLabel.text = "\"" + searchBar.text! + "\""
            return cell
        } else {
            let cell = self.tableView!.dequeueReusableCell(withIdentifier: "TrailDetailsCell", for: indexPath) as! TrailDetailsCell
            let currentTrail = filteredTrails[indexPath.row - 1]
            cell.detailsLabel.text = currentTrail.name
            cell.secondaryDetailsLabel.text = currentTrail.location
            return cell
        }
    }
}

// MARK: - Table view delegate
extension SelectTrailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        self.performSegue(withIdentifier: "unwindToPlanTrip", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Search bar delegate
extension SelectTrailViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applyFilter()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}


class TrailDetailsCell: UITableViewCell {
    
    @IBOutlet var detailsLabel: UILabel!
    @IBOutlet var secondaryDetailsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if #available(iOS 10.0, *) {
            detailsLabel.adjustsFontForContentSizeCategory = true
        } else {
            // Fallback on earlier versions
        }
    }
    
}

class NewTrailCell: UITableViewCell {
    
    @IBOutlet var detailsLabel: UILabel!
    @IBOutlet var secondaryDetailsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if #available(iOS 10.0, *) {
            detailsLabel.adjustsFontForContentSizeCategory = true
        } else {
            // Fallback on earlier versions
        }
    }
    
}
