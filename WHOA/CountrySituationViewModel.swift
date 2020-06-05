//
//  CountrySituationViewModel.swift
//  WHOA
//
//  Created by Jim Hildensperger on 06/06/2020.
//  Copyright © 2020 The Brewery BV. All rights reserved.
//

import Foundation

struct CountrySituationViewModel {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = NSLocale.autoupdatingCurrent
        formatter.groupingSize = 3
        formatter.usesGroupingSeparator = true
        return formatter
    }()
    
    let titleText: String
    let casesNumberText: String
    let casesTitleText: String
    let deathsText: String
    let sentenceText: String
        
    init?(country: Country?, data: Situation?) {
        guard let data = data,
            let formattedCases = CountrySituationViewModel.formatter.string(for: data.cumulativeCases),
            let deathsFormatted = CountrySituationViewModel.formatter.string(for: data.cumulativeDeaths),
            let isoCode = country?.isoCode else {
            return nil
        }
        casesNumberText = formattedCases
        casesTitleText = NSLocalizedString("Confirmed Cases", comment: "")
        titleText = String.localizedStringWithFormat(NSLocalizedString("%@'s Situation in Numbers", comment: ""), isoCode)
        deathsText = String.localizedStringWithFormat(NSLocalizedString("%@ Total Deaths", comment: ""), deathsFormatted)
        sentenceText = "\(titleText) \(casesNumberText) \(casesTitleText) \(deathsText)."
    }
}
