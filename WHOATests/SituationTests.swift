//
//  SituationTests.swift
//  WHOATests
//
//  Created by Jim Hildensperger on 06/06/2020.
//  Copyright © 2020 The Brewery BV. All rights reserved.
//

import XCTest
@testable import WHOA
    let usUrlString = "https://services.arcgis.com/5T5nSi527N4F7luB/arcgis/rest/services/COVID19_hist_cases_adm0_v5_view/FeatureServer/0/query?where=ISO_2_CODE+%3D+%27US%27+&geometryType=esriGeometryEnvelope&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&returnGeodetic=false&outFields=CumCase%2CCumDeath&returnHiddenFields=false&returnGeometry=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=date_epicrv+DESC&resultRecordCount=1&returnZ=false&returnM=false&returnExceededLimitFeatures=false&sqlFormat=none&f=pjson"

    let frUrlString = "https://services.arcgis.com/5T5nSi527N4F7luB/arcgis/rest/services/COVID19_hist_cases_adm0_v5_view/FeatureServer/0/query?where=ISO_2_CODE+%3D+%27FR%27+&geometryType=esriGeometryEnvelope&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&returnGeodetic=false&outFields=CumCase%2CCumDeath&returnHiddenFields=false&returnGeometry=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=date_epicrv+DESC&resultRecordCount=1&returnZ=false&returnM=false&returnExceededLimitFeatures=false&sqlFormat=none&f=pjson"

    let exampleJsonString = """
{
  "objectIdFieldName": "OBJECTID",
  "uniqueIdField": {
    "name": "OBJECTID",
    "isSystemMaintained": true
  },
  "globalIdFieldName": "",
  "geometryType": "esriGeometryPoint",
  "spatialReference": {
    "wkid": 4326,
    "latestWkid": 4326
  },
  "fields": [
    {
      "name": "CumCase",
      "type": "esriFieldTypeInteger",
      "alias": "CumCase",
      "sqlType": "sqlTypeOther",
      "domain": null,
      "defaultValue": null
    },
    {
      "name": "CumDeath",
      "type": "esriFieldTypeInteger",
      "alias": "CumDeath",
      "sqlType": "sqlTypeOther",
      "domain": null,
      "defaultValue": null
    },
    {
      "name": "OBJECTID",
      "type": "esriFieldTypeOID",
      "alias": "OBJECTID",
      "sqlType": "sqlTypeOther",
      "domain": null,
      "defaultValue": null
    }
  ],
  "exceededTransferLimit": true,
  "features": [
    {
      "attributes": {
        "CumCase": 1837803,
        "CumDeath": 106876,
        "OBJECTID": 19099
      }
    }
  ]
}
"""

class TestURLProtocol: URLProtocol {
    static var currentRequest: URLRequest?
    static var responseData = Data()
    
    override class func canInit(with request: URLRequest) -> Bool {
      return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
      return request
    }
    
    override func stopLoading() {}
    
    override func startLoading() {
        TestURLProtocol.currentRequest = request
        let response = URLResponse(url: request.url!, mimeType: "application/json", expectedContentLength: TestURLProtocol.responseData.count, textEncodingName: nil)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: TestURLProtocol.responseData)
        client?.urlProtocolDidFinishLoading(self)
    }
}

class SituationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [TestURLProtocol.self]
        Situation.urlSession = URLSession(configuration: configuration)
    }
    
    func test_getSituation_forCountryFR_shouldUseTheCorrectURL() {
        let expecation = expectation(description: "The url should be correct")
        let fr = Country(name: "", isoCode: "FR")
        
        Situation.getSituation(country: fr) { _ in
            XCTAssertEqual(TestURLProtocol.currentRequest?.url?.absoluteString, frUrlString)
            expecation.fulfill()
        }
        
        wait(for: [expecation], timeout: 1)
    }
    
    func test_getSituation_forCountryUS_shouldReturnASituation() {
        let expecation = expectation(description: "The url should be correct and the data should be parsed")
        let us = Country(name: "US of A", isoCode: "US")
        
        guard let data = exampleJsonString.data(using: .utf8) else {
            return XCTFail()
        }
        TestURLProtocol.responseData = data
        
        Situation.getSituation(country: us) { (situation) in
            XCTAssertEqual(situation?.cumulativeCases, 1837803)
            XCTAssertEqual(situation?.cumulativeDeaths, 106876)
            XCTAssertEqual(TestURLProtocol.currentRequest?.url?.absoluteString, usUrlString)
            expecation.fulfill()
        }
        
        wait(for: [expecation], timeout: 1)
    }
    
    func test_getSituation_forCountryUSWhenThereIsNoData_shouldNotReturnASituation() {
        let expecation = expectation(description: "The url should be correct and the data should be parsed")
        let us = Country(name: "US of A", isoCode: "US")
        
        TestURLProtocol.responseData = Data()
        
        Situation.getSituation(country: us) { (situation) in
            XCTAssertNil(situation)
            expecation.fulfill()
        }
        
        wait(for: [expecation], timeout: 1)
    }
}
