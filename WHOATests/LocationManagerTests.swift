//
//  LocationManagerTests.swift
//  WHOATests
//
//  Created by Jim Hildensperger on 06/06/2020.
//  Copyright © 2020 The Brewery BV. All rights reserved.
//

import XCTest
import CoreLocation
@testable import WHOA

class TestCLLocationManager: CLLocationManager {
    struct Stub {
        static var authorizationStatus: CLAuthorizationStatus = .notDetermined
    }
    
    var didReceiveRequestWhenInUseAuthorization = false
    var didReceiveStartMonitoringSignificantLocationChanges = false
    
    override class func authorizationStatus() -> CLAuthorizationStatus {
        return Stub.authorizationStatus
    }
    
    override func requestWhenInUseAuthorization() {
        didReceiveRequestWhenInUseAuthorization = true
    }
    
    override func startMonitoringSignificantLocationChanges() {
        didReceiveStartMonitoringSignificantLocationChanges = true
    }
    
}

class TestPlacemark: CLPlacemark {
    override var isoCountryCode: String {
        return "US"
    }
    
    override var country: String {
        return "US of A"
    }
}

class TestGeocoder: CLGeocoder {
    var reverseGeocodeLocationPlacemark: CLPlacemark?
    var didReceiveReverseGeocodeLocation = false
    
    override func reverseGeocodeLocation(_ location: CLLocation, completionHandler: @escaping CLGeocodeCompletionHandler) {
        didReceiveReverseGeocodeLocation = true
        
        if let placemark = reverseGeocodeLocationPlacemark {
            completionHandler([placemark], nil)
        } else {
            completionHandler(nil, nil)
        }
    }
}

class LocationManagerTests: XCTestCase {
    var subject: LocationManager!
    var testCLLocationManager: TestCLLocationManager!
    var testGeocoder: TestGeocoder!
    
    override func setUp() {
        super.setUp()
        subject = LocationManager()
        testCLLocationManager = TestCLLocationManager()
        testGeocoder = TestGeocoder()
        
        subject.locationManager = testCLLocationManager
        subject.geocoder = testGeocoder
    }
    
    func test_getCurrentLocation_whenAuthStatusIsNotDetermined_shouldRequestWhenInUseAuth() {
        XCTAssertFalse(testCLLocationManager.didReceiveRequestWhenInUseAuthorization)
        
        TestCLLocationManager.Stub.authorizationStatus = .notDetermined
        XCTAssertEqual(TestCLLocationManager.authorizationStatus(), .notDetermined)
        
        subject.getCurrentLocation()
        
        XCTAssert(testCLLocationManager.didReceiveRequestWhenInUseAuthorization)
    }
    
    func test_getCurrentLocation_whenAuthStatusIsAuthorizedWhenInUse_shouldStartMonitoring() {
        XCTAssertFalse(testCLLocationManager.didReceiveStartMonitoringSignificantLocationChanges)
        
        TestCLLocationManager.Stub.authorizationStatus = .authorizedWhenInUse
        XCTAssertEqual(TestCLLocationManager.authorizationStatus(), .authorizedWhenInUse)
        
        subject.getCurrentLocation()
        
        XCTAssert(testCLLocationManager.didReceiveStartMonitoringSignificantLocationChanges)
    }
    
    func test_locationManagerDidChangeAuthorization_whenAuthStatusIsAuthorizedWhenInUse_shouldStartMonitoring() {
        XCTAssertFalse(testCLLocationManager.didReceiveStartMonitoringSignificantLocationChanges)
        
        TestCLLocationManager.Stub.authorizationStatus = .authorizedWhenInUse
        XCTAssertEqual(TestCLLocationManager.authorizationStatus(), .authorizedWhenInUse)
        
        subject.locationManager(testCLLocationManager, didChangeAuthorization: .authorizedWhenInUse)
        
        XCTAssert(testCLLocationManager.didReceiveStartMonitoringSignificantLocationChanges)
    }
    
    func test_locationManagerDidChangeAuthorization_whenAuthStatusIsNotDetermined_shouldNotStartMonitoring() {
        XCTAssertFalse(testCLLocationManager.didReceiveStartMonitoringSignificantLocationChanges)
        
        TestCLLocationManager.Stub.authorizationStatus = .authorizedWhenInUse
        XCTAssertEqual(TestCLLocationManager.authorizationStatus(), .authorizedWhenInUse)
        
        subject.locationManager(testCLLocationManager, didChangeAuthorization: .notDetermined)
        
        XCTAssertFalse(testCLLocationManager.didReceiveStartMonitoringSignificantLocationChanges)
    }
    
    func test_locationManagerDidChangeAuthorization_whenAuthStatusIsRestricted_shouldNotStartMonitoring() {
        XCTAssertFalse(testCLLocationManager.didReceiveStartMonitoringSignificantLocationChanges)
        
        TestCLLocationManager.Stub.authorizationStatus = .authorizedWhenInUse
        XCTAssertEqual(TestCLLocationManager.authorizationStatus(), .authorizedWhenInUse)
        
        subject.locationManager(testCLLocationManager, didChangeAuthorization: .restricted)
        
        XCTAssertFalse(testCLLocationManager.didReceiveStartMonitoringSignificantLocationChanges)
    }
    
    func test_locationManagerDidChangeAuthorization_whenAuthStatusIsDenied_shouldNotStartMonitoring() {
        XCTAssertFalse(testCLLocationManager.didReceiveStartMonitoringSignificantLocationChanges)
        
        TestCLLocationManager.Stub.authorizationStatus = .authorizedWhenInUse
        XCTAssertEqual(TestCLLocationManager.authorizationStatus(), .authorizedWhenInUse)
        
        subject.locationManager(testCLLocationManager, didChangeAuthorization: .denied)
        
        XCTAssertFalse(testCLLocationManager.didReceiveStartMonitoringSignificantLocationChanges)
    }
    
    func test_locationManagerDidChangeAuthorization_whenAuthStatusIsAuthorizedAlways_shouldNotStartMonitoring() {
        XCTAssertFalse(testCLLocationManager.didReceiveStartMonitoringSignificantLocationChanges)
        
        TestCLLocationManager.Stub.authorizationStatus = .authorizedWhenInUse
        XCTAssertEqual(TestCLLocationManager.authorizationStatus(), .authorizedWhenInUse)
        
        subject.locationManager(testCLLocationManager, didChangeAuthorization: .authorizedAlways)
        
        XCTAssertFalse(testCLLocationManager.didReceiveStartMonitoringSignificantLocationChanges)
    }
    
    func test_locationManagerDidUpdateLocations_whenThereAreLocations_shouldReverseGeocode() {
        XCTAssertFalse(testGeocoder.didReceiveReverseGeocodeLocation)
        
        subject.locationManager(testCLLocationManager, didUpdateLocations: [CLLocation()])
        
        XCTAssert(testGeocoder.didReceiveReverseGeocodeLocation)
    }
    
    func test_locationManagerDidUpdateLocations_whenThereAreNotLocations_shouldNotReverseGeocode() {
        XCTAssertFalse(testGeocoder.didReceiveReverseGeocodeLocation)
        
        subject.locationManager(testCLLocationManager, didUpdateLocations: [])
        
        XCTAssertFalse(testGeocoder.didReceiveReverseGeocodeLocation)
    }
    
    func test_locationManagerDidUpdateLocations_whenThereAreLocationsAndReverseGeocodeSucceeds_shouldReturnCountry() {
        XCTAssertNil(subject.currentCountry)

        let placemark = TestPlacemark()
        testGeocoder.reverseGeocodeLocationPlacemark = placemark
        subject.locationManager(testCLLocationManager, didUpdateLocations: [CLLocation()])

        XCTAssertEqual(subject.currentCountry?.name, "US of A")
        XCTAssertEqual(subject.currentCountry?.isoCode, "US")
    }
    
    func test_locationManagerDidUpdateLocations_whenThereAreLocationsAndReverseGeocodeHasNoIsoCode_shouldNotReturnCountry() {
        XCTAssertNil(subject.currentCountry)

        subject.locationManager(testCLLocationManager, didUpdateLocations: [CLLocation()])

        XCTAssertNil(subject.currentCountry)
    }
    
}
