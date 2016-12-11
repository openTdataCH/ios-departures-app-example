//
//  ODPSwissDeparturesNetworkController.swift
//  OpenTransportSwissDepartures
//
//  Created by Vasile Cotovanu on 30/11/16.
//  Copyright © 2016 vasile.ch. All rights reserved.
//

import Foundation

class ODPSwissDeparturesNetworkController: NSObject {
    var authorizationToken: String
    
    init(token: String) {
        self.authorizationToken = token
        
        super.init()
    }
    
    func payloadDeparturesAPI(stopId: String) -> String? {
        guard let url = Bundle.main.url(forResource: "payload-template-departures", withExtension: "xml") else {
            return nil
        }
        
        do {
            var xml = try String(contentsOf: url, encoding: .utf8)
            xml = xml.replacingOccurrences(of: "[STOP_ID]", with: stopId)
            return xml
        } catch {
            
        }
        
        return nil
    }
    
    func fetchDeparturesForStopId(stopId: String, handler: @escaping ([ODPCH_TripDeparture]) -> () ) {
        guard let payloadXML = payloadDeparturesAPI(stopId: stopId) else { return }
        
        guard let url = URL(string: "https://api.opentransportdata.swiss/trias") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(authorizationToken, forHTTPHeaderField: "Authorization")
        request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.httpBody = payloadXML.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            if error != nil {
                // TODO: handle error
            } else {
                if let data = data {
                    // print("Response: \n\(String(data: data, encoding: .utf8))")
                    let parser = ODPSwissDeparturesParser(stopId: stopId, xmlData: data)
                    if let tripDepartures = parser.parse() {
                        print("PARSE \(url.absoluteString) -> \(tripDepartures.count) departures")
                        handler(tripDepartures)
                    } else {
                        // TODO: handle error
                    }
                }
            }
        }
        task.resume()
    }
}
