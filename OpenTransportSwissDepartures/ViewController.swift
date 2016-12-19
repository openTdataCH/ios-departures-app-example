//
//  ViewController.swift
//  OpenTransportSwissDepartures
//
//  Created by Vasile Cotovanu on 25/11/16.
//  Copyright © 2016 vasile.ch. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var stopId: String?
    var networkController: ODPSwissDeparturesNetworkController?
    var departures = [ODPCH_TripDeparture]()
    var timeHHMMFormatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get a free token here https://opentransportdata.swiss/dev-dashboard
        let apiToken = "VDV_431_KEY"
        networkController = ODPSwissDeparturesNetworkController(token: apiToken)
        
        searchBar.delegate = self
        searchBar.text = "8503000" // Zürich HB
        // searchBar.text = "8591233" // Klusplatz
        // searchBar.text = "8501008" // Geneve Cornavin
        // searchBar.text = "8505000" // Luzern
        // searchBar.text = "8590129" // Bern Wankdorf, Bahnhof
        // Get one from https://opentransportdata.swiss/en/dataset/didok
        
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = 70
        tableView.allowsSelection = false
        
        timeHHMMFormatter.dateFormat = "HH:mm"
        
        updateDepartures()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension ViewController {
    public func updateDepartures() {
        
        stopId = searchBar.text
        
        if let stopId = stopId {
            DispatchQueue.global(qos: .background).async {
                self.networkController?.fetchDeparturesForStopId(stopId: stopId, handler: { (newDepartures) in
                    DispatchQueue.main.async(){
                        self.departures = newDepartures
                        self.tableView.reloadData()
                    }
                })
            }
        }
    }
}

extension ViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        updateDepartures()
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return departures.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaultCell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? DepartureCell else {
            return defaultCell
        }
        
        if indexPath.row >= departures.count {
            return defaultCell
        }
        
        let tripDeparture = departures[indexPath.row]
        
        if let departureTime = tripDeparture.stopTime.departureTime {
            cell.tripDepartureTime.text = timeHHMMFormatter.string(from: departureTime)
        } else {
            cell.tripDepartureTime.text = ""
        }
        
        cell.tripId.text = tripDeparture.trip.tripId
        
        cell.tripDisplayName.text = tripDeparture.trip.displayName
        cell.tripDisplayName.layer.borderWidth = 0.5
        cell.tripDisplayName.layer.borderColor = UIColor.darkGray.cgColor
        cell.tripDisplayName.minimumScaleFactor = 0.5
        cell.tripDisplayName.adjustsFontSizeToFitWidth = true
        cell.tripDisplayName.baselineAdjustment = .alignCenters
        
        cell.tripDestination.text = tripDeparture.trip.tripDestination
        
        switch tripDeparture.stopTime.departureStatus {
        case .onTime :
            cell.tripRealTimeInfo.text = " ON TIME "
            cell.tripRealTimeInfo.backgroundColor = UIColor(red:0.22, green:0.60, blue:0.20, alpha:1.0)
        case .delayed :
            if let minutes = tripDeparture.stopTime.delayMinutes {
                cell.tripRealTimeInfo.text = " +\(minutes)' "
            } else {
                cell.tripRealTimeInfo.text = "?'"
            }
            cell.tripRealTimeInfo.backgroundColor = UIColor.orange
        default:
            cell.tripRealTimeInfo.text = " NO INFO "
            cell.tripRealTimeInfo.backgroundColor = UIColor.darkGray
        }
        cell.tripRealTimeInfo.textColor = UIColor.white
        cell.tripRealTimeInfo.layer.masksToBounds = true
        cell.tripRealTimeInfo.layer.cornerRadius = 4
        
        cell.tripNextStations.text = tripNextStationsText(nextStops: tripDeparture.nextStops)
        cell.tripNextStations.numberOfLines = 0
        cell.tripNextStations.lineBreakMode = .byWordWrapping
        cell.tripNextStations.textColor = UIColor.darkGray
        
        return cell
    }
    
    private func tripNextStationsText(nextStops: [GTFS_StopTime]?) -> String {
        guard let nextStops = nextStops else { return "" }
        
        var nextStopsList = [String]()
        for nextStopTime in nextStops {
            guard
                let stopName = nextStopTime.stopName,
                let stopArrival = nextStopTime.arrivalTime
            else {
                continue
            }
            
            let nextStopArrival = timeHHMMFormatter.string(from: stopArrival)
            let nextStopText = "\(stopName) (\(nextStopArrival))"
            nextStopsList.append(nextStopText)
        }
        
        return " - " + nextStopsList.joined(separator: " - ")
    }
}

class DepartureCell: UITableViewCell {
    @IBOutlet weak var tripDisplayName: UILabel!
    @IBOutlet weak var tripId: UILabel!
    @IBOutlet weak var tripDestination: UILabel!
    @IBOutlet weak var tripNextStations: UILabel!
    @IBOutlet weak var tripDepartureTime: UILabel!
    @IBOutlet weak var tripRealTimeInfo: UILabel!
}


