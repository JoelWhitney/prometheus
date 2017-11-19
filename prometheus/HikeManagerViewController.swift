//
//  HikeManagerViewController.swift
//  prometheus
//
//  Created by Joel Whitney on 11/12/17.
//  Copyright © 2017 JoelWhitney. All rights reserved.
//

import Foundation
import UIKit

class HikeManagerViewController: UIViewController, isAbleToPassNewHike {
    var filterHandler: ((String?) -> Void)?
    var hikes: [Hike] = [] {
        didSet {
            applyFilter()
        }
    }
    var filteredHikes: [Hike] = [] {
        didSet {
            print("filtered results")
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    var selectedHike: Hike!
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //fetchHikes()
    }
    
    func passHike(hike: Hike) {
        print("received hike")
        hikes.append(hike)
        applyFilter()
    }
    
    func fetchHikes() {
        // retrieve hikes or create empty hikes
        hikes = []
    }
    
    func addHike(hike: Hike) {
        hikes.append(hike)
        print(hikes)
        applyFilter()
    }
        
    func applyFilter() {
        guard let searchText = searchBar.text?.lowercased(), !searchText.isEmpty, hikes.count > 0 else {
            filteredHikes = hikes.sorted(by: { $0.trail.name < $1.trail.name })
            filterHandler?(nil)
            return
        }
        filteredHikes = hikes.filter { $0.trail.name.lowercased().contains(searchText)}
            .sorted(by: { $0.trail.name < $1.trail.name })
        filterHandler?(searchText)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "AddHikeViewController") {
            print("added passhike delegate to vc")
            let destController = segue.destination.childViewControllers.first(where: { $0 is AddHikeViewController }) as? AddHikeViewController
            destController!.delegate = self
        }
        if let destController = segue.destination as? MainHikeDetailsViewController {
            print(selectedHike)
            destController.hike = selectedHike
        }
    }
}

// MARK: - Table view data source
extension HikeManagerViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredHikes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HikeSummaryCell", for: indexPath) as! HikeSummaryCell
        let hike = filteredHikes[indexPath.row]
        // cell details
        cell.detailsLabel.text = hike.trail.name
        cell.secondaryDetailsLabel.text = hike.place.name
        return cell
    }
    
}
    
extension HikeManagerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedHike = filteredHikes[indexPath.row]
        print(selectedHike)
        tableView.deselectRow(at: indexPath, animated: true)
        searchBar.resignFirstResponder()
        self.performSegue(withIdentifier: "HikeDetailsViewController", sender: self)
    }
    
}

extension HikeManagerViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.applyFilter), object: nil)
        self.perform(#selector(self.applyFilter), with: nil, afterDelay: 0.25)
        tableView.setContentOffset(CGPoint.zero, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("search")
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("cancel")
        
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        print("did begin editing")
        searchBar.becomeFirstResponder()
    }
    
}

protocol isAbleToPassNewHike {
    func passHike(hike: Hike)
}

class HikeSummaryCell: UITableViewCell {
    
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
