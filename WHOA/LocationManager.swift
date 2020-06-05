//
//  Location.swift
//  WHOA
//
//  Created by Jim Hildensperger on 05/06/2020.
//  Copyright © 2020 The Brewery BV. All rights reserved.
//

import Foundation
import CoreLocation

class LocationManager: NSObject {
    var locationManager = CLLocationManager()
    var geocoder = CLGeocoder()
    
    override init() {
        super.init()
        
        locationManager.delegate = self
    }
    
    internal private(set) var currentCountry: Country? {
        didSet {
            currentCountryDidUpdate?(currentCountry)
        }
    }
    
    var currentCountryDidUpdate: ((Country?) -> ())?
    
    func getCurrentLocation() {
        guard type(of: locationManager).authorizationStatus() == .notDetermined else {
            return startMonitoring()
        }
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Private
    
    private func startMonitoring() {
        locationManager.startMonitoringSignificantLocationChanges()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            startMonitoring()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let firstLocation = locations.first else {
            return currentCountry = nil
        }
        
        geocoder.reverseGeocodeLocation(firstLocation) { [weak self](placemarks, error) in
            if let isoCountryCode = placemarks?.first?.isoCountryCode, let name = placemarks?.first?.country {
                self?.currentCountry = Country(name: name, isoCode: isoCountryCode)
            } else {
                self?.currentCountry = nil
            }
        }
    }
}
