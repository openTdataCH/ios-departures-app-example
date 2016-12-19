## About

This iOS project brings you up to speed in using the live [arrivals/departures](https://opentransportdata.swiss/de/cookbook/abfahrts-ankunftsanzeiger/) APIs provided by [Open Data Platform Swiss Public Transport](https://opentransportdata.swiss/en/) portal. 

The project is developed with Xcode 8.1, Swift 3.x and supports iOS 8.4+ devices

## Setup

- clone / download / unzip a copy of this repo on your machine
- get a free API key from [opentransportdata.swiss](https://opentransportdata.swiss/dev-dashboard)
- add your key inside `OpenTransportSwissDepartures/ViewController.swift`, search for `let apiToken = "VDV_431_KEY"` line
- build and run, you should see the departures for Zürich HB, stop_id = [8503000](https://opentransportdata.swiss/en/dataset/didok)

![App running in the iOS simulator](https://api.monosnap.com/rpc/file/download?id=ifjuVWXpTQp1ShCMU3hXTWnXTTrcbH)

## Include the code in your project

In the near future we will offer iOS framework or 3rd party CocoaPods/Carthage library support. 
Until then you have to import the library manually:

- copy `OpenTransportSwissDepartures/ODPSwiss/*` files in your project
- make sure the files are added to your app main target
- instantiate `ODPSwissDeparturesNetworkController` object in the VC with your API token
- call the `fetchDeparturesForStopId` on a background thread and use the result array which is of type `ODPCH_TripDeparture`. 

>     DispatchQueue.global(qos: .background).async {
>       self.networkController?.fetchDeparturesForStopId(stopId: stopId, handler:{ (newDepartures) in
>         DispatchQueue.main.async(){
>           // DO something with newDepartures 
>         }
>       })
>     }

- check `OpenTransportSwissDepartures/ODPSwiss/ODPSwissModels.swift` for more info about the [GTFS](https://developers.google.com/transit/gtfs/reference/) and ODPCH models used

## Contact

For questions related to OpenData APIs please contact [ODPCH team](https://opentransportdata.swiss/en/contact-2/) 

Do you want to contribute to this project? Please send us your feedback or even better, a pull request! 

### Contributors:
- Vasile Coțovanu: [Web](http://www.vasile.ch) • [Twitter](http://twitter.com/vasile23) • [Github](https://github.com/vasile)

## License

This project is licensed under the terms of the [MIT license](https://en.wikipedia.org/wiki/MIT_License). See the [LICENSE](LICENSE) file.

> This project is open source under the MIT license, which means you have full access to the source code and can modify it to fit your own needs. You are fully responsible for how you use this project.

 