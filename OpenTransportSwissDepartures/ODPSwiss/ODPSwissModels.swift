//
//  ODPSwissModels.swift
//  OpenTransportSwissDepartures
//
//  Created by Vasile Cotovanu on 05/12/16.
//  Copyright © 2016 vasile.ch. All rights reserved.
//

import Foundation

enum ODPCH_VehicleType {
    case cablecar
    case boat
    case bus
    case tram
    case train
    case unknown
}

enum ODPCH_DepartureStatus {
    case notAvailable
    case onTime
    case delayed
}

class ODPCH_XML_TripDeparture: NSObject {
    var tripId: String?
    var tripRef: String?
    var agencyId: String?
    var vehicleType: String?
    var mainVehicleType: String?
    var tripLineNumber: String?
    var tripStopArrivalTime: Date?
    var tripStopLiveArrivalTime: Date?
    var tripStopDepartureTime: Date?
    var tripStopLiveDepartureTime: Date?
    var tripDestination: String?
    var nextStopTimes: [ODPCH_XML_TripDepartureStopTime]?
    var prevStopTimes: [ODPCH_XML_TripDepartureStopTime]?
}

class ODPCH_XML_TripDepartureStopTime: NSObject {
    var stopId: String?
    var stopName: String?
    var arrivalTime: Date?
    var arrivalRealTime: Date?
    var departureTime: Date?
    var departureRealTime: Date?
}

// Variation of https://developers.google.com/transit/gtfs/reference/trips-file
class GTFS_Trip: NSObject {
    var tripId: String
    var vehicleType: ODPCH_VehicleType
    var tripStops: [GTFS_StopTime]
    
    var tripDestination: String?
    var vehicleLineNumber: String?
    var displayName: String?
    
    init(tripId: String, vehicleType: ODPCH_VehicleType, tripStops: [GTFS_StopTime]) {
        self.tripId = tripId
        self.vehicleType = vehicleType
        self.tripStops = tripStops
        
        super.init()
    }
}

// Variation of https://developers.google.com/transit/gtfs/reference/stop_times-file
class GTFS_StopTime: NSObject {
    var tripId: String
    var stopId: String
    var stopName: String?
    
    var arrivalTime: Date?
    var arrivalRealTime: Date? {
        didSet {
            // simpler logic than departureRealTime.didSet{}
            // TODO - still can we reuse this logic ?
            guard
                let arrivalTime = arrivalTime,
                let arrivalRealTime = arrivalRealTime
            else { return }
            
            let delay = Int(arrivalRealTime.timeIntervalSince(arrivalTime) / 60)
            delayArrivalMinutes = delay
        }
    }
    var delayArrivalMinutes: Int?
    var departureTime: Date?
    var departureRealTime: Date? {
        didSet {
            guard
                let departureTime = departureTime,
                let departureRealTime = departureRealTime
            else { return }
            
            let delay = Int(departureRealTime.timeIntervalSince(departureTime) / 60)
            if delay > 0 {
                departureStatus = .delayed
            } else {
                departureStatus = .onTime
            }
            
            delayMinutes = delay
        }
    }
    var departureStatus: ODPCH_DepartureStatus
    var delayMinutes: Int?
    
    init(tripId: String, stopId: String) {
        self.tripId = tripId
        self.stopId = stopId
        self.departureStatus = .notAvailable
        
        super.init()
    }
}

// No equivalent in GTFS world, used to aggregate departures from a given stop
class ODPCH_TripDeparture: NSObject {
    var trip: GTFS_Trip
    var stopTime: GTFS_StopTime
    
    var prevStops: [GTFS_StopTime]?
    var nextStops: [GTFS_StopTime]?
    
    init(trip: GTFS_Trip, stopTime: GTFS_StopTime) {
        self.trip = trip
        self.stopTime = stopTime
        
        super.init()
    }
}


