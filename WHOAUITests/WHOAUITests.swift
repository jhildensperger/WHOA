//
//  WHOAUITests.swift
//  WHOAUITests
//
//  Created by Jim Hildensperger on 05/06/2020.
//  Copyright © 2020 The Brewery BV. All rights reserved.
//

import XCTest

class WHOAUITests: XCTestCase {
    let app = XCUIApplication()
    var firstCell: XCUIElement!
    var secondCell: XCUIElement!
        
    override func setUp() {
        super.setUp()
        app.launch()
        
        firstCell = app.collectionViews.cells["introCell"]
        XCTAssert(firstCell.exists)
        XCTAssertEqual(app.collectionViews.cells.count, 1)
        
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let button = springboard.alerts.firstMatch.buttons["Allow Once"]
        
        XCTAssert(button.waitForExistence(timeout: 10))
        button.tap()
        
        secondCell = app.collectionViews.cells["countrySituationCell"]
        XCTAssert(secondCell.waitForExistence(timeout: 10))
        
        XCTAssertEqual(app.collectionViews.cells.count, 2)
    }
    
    func test_appLaunch_withNYCLocation_shouldLoadTheSitationForUS() {
        let titleLabel = secondCell.staticTexts["titleLabel"]
        XCTAssertEqual(titleLabel.label, "US's Situation in Numbers")
    }
    
    func test_pageControl_onTap_shouldChangeThePage() {
        let animationExpectation = expectation(description: "Animations should complete")
        animationExpectation.expectedFulfillmentCount = 2
        
        let collectionView = app.collectionViews.firstMatch
        let centerPoint = CGPoint(x: collectionView.frame.midX, y: collectionView.frame.midY)
        
        XCTAssert(firstCell.frame.contains(centerPoint))
        XCTAssertFalse(secondCell.frame.contains(centerPoint))
        
        app.pageIndicators.firstMatch.tap()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssert(self.secondCell.frame.contains(centerPoint))
            XCTAssertFalse(self.firstCell.frame.contains(centerPoint))
            animationExpectation.fulfill()
            
            self.app.pageIndicators.firstMatch.tap()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssert(self.firstCell.frame.contains(centerPoint))
            XCTAssertFalse(self.secondCell.frame.contains(centerPoint))
            animationExpectation.fulfill()
        }
        
        wait(for: [animationExpectation], timeout: 3.0)
    }
    
    func test_secondCell_onTap_shouldShowShareSheet() {
        secondCell.tap()
        
        let activityView = app.navigationBars["UIActivityContentView"]
        XCTAssert(activityView.waitForExistence(timeout: 10))
    }
}
