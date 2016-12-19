//
//  ODPSwissDeparturesParser.swift
//  OpenTransportSwissDepartures
//
//  Created by Vasile Cotovanu on 30/11/16.
//  Copyright © 2016 vasile.ch. All rights reserved.
//

import Foundation

class ODPSwissDeparturesParser: NSObject {
    var stopId: String
    var parser: XMLParser

    var tripDepartures: [ODPCH_TripDeparture]?
    var currentXMLTrip: ODPCH_XML_TripDeparture?
    var currentXMLTripStopTime: ODPCH_XML_TripDepartureStopTime?
    
    var departureDateFormatter = DateFormatter()
    
    var currentPathElements = [""] {
        didSet {
            currentPath = currentPathElements.joined(separator: "/")
        }
    }
    var currentPath = ""
    var foundCharacters = ""
    
    init(stopId: String, xmlData: Data) {
        self.stopId = stopId
        self.parser = XMLParser(data: xmlData)
        super.init()
        
        // 2016-11-30T19:17:00Z
        departureDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        parser.delegate = self
    }
    
    func parse() -> [ODPCH_TripDeparture]? {
        tripDepartures = []
        
        let success = parser.parse()
        if success == false {
            return nil
        }
        
        return tripDepartures
    }
}

extension ODPSwissDeparturesParser: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        currentPathElements.append(elementName)
        
        if currentPath == xmlTripPath() {
            currentXMLTrip = ODPCH_XML_TripDeparture()
            currentXMLTrip?.nextStopTimes = []
        }
        
        if currentPath == xmlTripNextStopPath() {
            currentXMLTripStopTime = ODPCH_XML_TripDepartureStopTime()
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if currentPath == xmlTripPath() {
            if let tripDeparture = tripDepartureFromXML() {
                tripDepartures?.append(tripDeparture)
            }
        }
        
        if currentPath == xmlTripJourneyRefPath() {
            currentXMLTrip?.tripRef = foundCharacters
            
            if let lastPart = foundCharacters.components(separatedBy: ":").last {
                currentXMLTrip?.tripId = lastPart
            }
        }
        
        if currentPath == xmlTripAgencyPath() {
            if let agencyId = parseAgency(xmlContent: foundCharacters) {
                currentXMLTrip?.agencyId = agencyId
            }
        }
        
        if currentPath == xmlTripTypePath() {
            currentXMLTrip?.vehicleType = foundCharacters
        }
        
        if currentPath == xmlTripMainTypePath() {
            currentXMLTrip?.mainVehicleType = foundCharacters
        }
        
        if currentPath == xmlTripLineNumberPath() {
            currentXMLTrip?.tripLineNumber = foundCharacters
        }
        
        if currentPath == xmlTripStopDepartureTime() {
            currentXMLTrip?.tripStopDepartureTime = parseDepartureDate(string: foundCharacters)
        }
        
        if currentPath == xmlTripStopLiveDepartureTime() {
            currentXMLTrip?.tripStopLiveDepartureTime = parseDepartureDate(string: foundCharacters)
        }
        
        if currentPath == xmlTripDestination() {
            currentXMLTrip?.tripDestination = foundCharacters
        }
        
        if currentPath == xmlTripNextStopNamePath() {
            currentXMLTripStopTime?.stopName = foundCharacters
        }
        
        if currentPath == xmlTripNextStopArrivalPath() {
            currentXMLTripStopTime?.arrivalTime = parseDepartureDate(string: foundCharacters)
        }
        
        if currentPath == xmlTripNextStopDeparturePath() {
            currentXMLTripStopTime?.departureTime = parseDepartureDate(string: foundCharacters)
        }
        
        if currentPath == xmlTripNextStopPath() {
            if let xmlTripStopTime = currentXMLTripStopTime {
                currentXMLTrip?.nextStopTimes?.append(xmlTripStopTime)
            }
        }
        
        foundCharacters = ""
        
        if let lastPathElement = currentPathElements.last {
            if lastPathElement == elementName {
                currentPathElements.removeLast()
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        foundCharacters += string.replacingOccurrences(of: "^\\s*", with: "", options: .regularExpression, range: nil)
    }
    
    private func parseDepartureDate(string: String?) -> Date? {
        guard let string = string else { return nil }
        
        return departureDateFormatter.date(from: string)
    }
}

// Parse Helpers
extension ODPSwissDeparturesParser {
    private func parseVehicleType(string: String?) -> ODPCH_VehicleType? {
        guard let string = string else { return nil }
        
        switch string {
        case "bus":
            return .bus
        case "rail":
            return .train
        case "tram":
            return .tram
        case "urbanRail":
            return .train
        default:
            return .unknown
        }
    }
    
    // FIXME - ugly as hell
    private func parseTripDisplayName(vehicleType: ODPCH_VehicleType, lineNumber: String?, tripTypeSourceString: String?) -> String? {
        let defaultName = tripTypeSourceString
        
        if vehicleType == .train {
            if let tripType = tripTypeSourceString {
                if tripType == "S-Bahn" {
                    if let lineNumber = lineNumber {
                        return "S\(lineNumber)"
                    } else {
                        return "S"
                    }
                } else {
                    switch tripType {
                    case "Eurocity":
                        return "EC"
                    case "ICN":
                        return "ICN"
                    case "Intercity":
                        return "IC"
                    case "InterRegio":
                        return "IR"
                    case "RegioExpress":
                        return "RE"
                    default:
                        return tripType
                    }
                }
            } else {
                return defaultName
            }
        } else {
            if let lineNumber = lineNumber {
                if lineNumber == "" {
                    return defaultName
                } else {
                    return lineNumber
                }
            } else {
                return defaultName
            }
        }
    }
    
    internal func tripDepartureFromXML() -> ODPCH_TripDeparture? {
        guard
            let xmlTrip = currentXMLTrip,
            let tripId = xmlTrip.tripId,
            let vehicleType = parseVehicleType(string: xmlTrip.mainVehicleType),
            let departureTime = xmlTrip.tripStopDepartureTime,
            let tripDestination = xmlTrip.tripDestination
        else {
            return nil
        }
        
        let stopTime = GTFS_StopTime(tripId: tripId, stopId: stopId)
        stopTime.departureTime = departureTime
        stopTime.departureRealTime = xmlTrip.tripStopLiveDepartureTime
        
        let trip = GTFS_Trip(tripId: tripId, vehicleType: vehicleType, tripStops: [])
        trip.vehicleLineNumber = xmlTrip.tripLineNumber
        trip.tripDestination = tripDestination
        trip.displayName = parseTripDisplayName(vehicleType: vehicleType, lineNumber: xmlTrip.tripLineNumber, tripTypeSourceString: xmlTrip.vehicleType)
        
        let tripDeparture = ODPCH_TripDeparture(trip: trip, stopTime: stopTime)
        if let xmlNextStopTimes = currentXMLTrip?.nextStopTimes {
            tripDeparture.nextStops = []
            for xmlNextStopTime in xmlNextStopTimes {
                // no stopId offered for now in /StopEvent/OnwardCall/CallAtStop
                let nextStopId = "0"
                
                let stopTime = GTFS_StopTime(tripId: tripId, stopId: nextStopId)
                stopTime.stopName = xmlNextStopTime.stopName
                stopTime.arrivalTime = xmlNextStopTime.arrivalTime
                stopTime.departureTime = xmlNextStopTime.departureTime
                
                tripDeparture.nextStops?.append(stopTime)
            }
        }
        
        return tripDeparture
    }
    
    internal func parseAgency(xmlContent: String) -> String? {
        let parts = xmlContent.components(separatedBy: "odp:")
        return parts.last
    }
    
    internal func xmlTripPath() -> String {
        return "/Trias/ServiceDelivery/DeliveryPayload/StopEventResponse/StopEventResult"
    }
    
    internal func xmlTripJourneyRefPath() -> String {
        return xmlTripPath() + "/StopEvent/Service/JourneyRef"
    }
    
    internal func xmlTripAgencyPath() -> String {
        return xmlTripPath() + "/StopEvent/Service/OperatorRef"
    }
    
    internal func xmlTripTypePath() -> String {
        return xmlTripPath() + "/StopEvent/Service/Mode/Name/Text"
    }
    
    internal func xmlTripMainTypePath() -> String {
        return xmlTripPath() + "/StopEvent/Service/Mode/PtMode"
    }
    
    internal func xmlTripLineNumberPath() -> String {
        return xmlTripPath() + "/StopEvent/Service/PublishedLineName/Text"
    }
    
    internal func xmlTripStopDepartureTime() -> String {
        return xmlTripPath() + "/StopEvent/ThisCall/CallAtStop/ServiceDeparture/TimetabledTime"
    }
    
    internal func xmlTripStopLiveDepartureTime() -> String {
        return xmlTripPath() + "/StopEvent/ThisCall/CallAtStop/ServiceDeparture/EstimatedTime"
    }
    
    internal func xmlTripDestination() -> String {
        return xmlTripPath() + "/StopEvent/Service/DestinationText/Text"
    }
    
    internal func xmlTripNextStopPath() ->String {
        return xmlTripPath() + "/StopEvent/OnwardCall/CallAtStop"
    }
    
    internal func xmlTripNextStopNamePath() ->String {
        return xmlTripPath() + "/StopEvent/OnwardCall/CallAtStop/StopPointName/Text"
    }
    
    internal func xmlTripNextStopArrivalPath() ->String {
        return xmlTripPath() + "/StopEvent/OnwardCall/CallAtStop/ServiceArrival/TimetabledTime"
    }
    
    internal func xmlTripNextStopDeparturePath() ->String {
        return xmlTripPath() + "/StopEvent/OnwardCall/CallAtStop/ServiceDeparture/TimetabledTime"
    }
}
