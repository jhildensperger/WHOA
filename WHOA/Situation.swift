//
//  Situation.swift
//  WHOA
//
//  Created by Jim Hildensperger on 05/06/2020.
//  Copyright © 2020 The Brewery BV. All rights reserved.
//

/*
// 20200605181554
// https://services.arcgis.com/5T5nSi527N4F7luB/arcgis/rest/services/COVID19_hist_cases_adm0_v5_view/FeatureServer/0/query?where=ISO_2_CODE+%3D+%27US%27+&geometryType=esriGeometryEnvelope&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&returnGeodetic=false&outFields=CumCase%2CCumDeath&returnHiddenFields=false&returnGeometry=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=date_epicrv+DESC&resultRecordCount=1&returnZ=false&returnM=false&returnExceededLimitFeatures=false&sqlFormat=none&f=pjson

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
*/

import Foundation

struct Situation: Decodable {
    let cumulativeCases: Int
    let cumulativeDeaths: Int
    
    enum SituationCodingKeys: String, CodingKey {
        case cumulativeDeaths = "CumDeath"
        case cumulativeCases = "CumCase"
    }
    
    enum ResponseCodingKeys: String, CodingKey {
        case features
    }
    
    enum AttributesCodingKeys: String, CodingKey {
        case attributes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ResponseCodingKeys.self)
        var nestedUnkeyedContainer = try container.nestedUnkeyedContainer(forKey: .features)
        let attributesContainer = try nestedUnkeyedContainer.nestedContainer(keyedBy: AttributesCodingKeys.self)
        let nestedContainer = try attributesContainer.nestedContainer(keyedBy: SituationCodingKeys.self, forKey: .attributes)
        
        cumulativeDeaths = try nestedContainer.decode(Int.self, forKey: .cumulativeDeaths)
        cumulativeCases = try nestedContainer.decode(Int.self, forKey: .cumulativeCases)
    }
}

extension Situation {
    private static let jsonDecoder = JSONDecoder()
    static var urlSession = URLSession(configuration: .default)
    
    private static func urlString(isoCode: String) -> String {
        return "https://services.arcgis.com/5T5nSi527N4F7luB/arcgis/rest/services/COVID19_hist_cases_adm0_v5_view/FeatureServer/0/query?where=ISO_2_CODE+%3D+%27\(isoCode)%27+&geometryType=esriGeometryEnvelope&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&returnGeodetic=false&outFields=CumCase%2CCumDeath&returnHiddenFields=false&returnGeometry=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=date_epicrv+DESC&resultRecordCount=1&returnZ=false&returnM=false&returnExceededLimitFeatures=false&sqlFormat=none&f=pjson"
    }
    
    static func getSituation(country: Country, completion: @escaping (Situation?) -> ()) {
        guard let url = URL(string: urlString(isoCode: country.isoCode)) else {
            preconditionFailure()
        }
        
        var dataTask: URLSessionDataTask?
        
        dataTask = urlSession.dataTask(with: url) { data, response, error in
            guard let data = data, let situation = try? jsonDecoder.decode(Situation.self, from: data) else {
                return DispatchQueue.main.async {
                    completion(nil)
                }
            }
            
            DispatchQueue.main.async {
                completion(situation)
            }
        }
        
        dataTask?.resume()
    }
}
