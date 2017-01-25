//
//  WatchdogInspectorTests.swift
//  SwiftExample
//
//  Created by Christian Menschel on 07/03/16.
//  Copyright © 2016 TAPWORK. All rights reserved.
//

import XCTest
import WatchdogInspector

class WatchdogInspectorTests: XCTestCase {

    func testIsRunning() {
        TWWatchdogInspector.start()
        XCTAssertTrue(TWWatchdogInspector.isRunning())
    }

    func testIsNotRunning() {
        TWWatchdogInspector.start()
        TWWatchdogInspector.stop()
        XCTAssertFalse(TWWatchdogInspector.isRunning())
    }

    func testToggleStart() {
        TWWatchdogInspector.start()
        TWWatchdogInspector.stop()
        TWWatchdogInspector.start()
        XCTAssertTrue(TWWatchdogInspector.isRunning())
    }

    func testWindow() {
        TWWatchdogInspector.start()
        let window = UIApplication.shared.windows.last
        XCTAssertTrue(window?.rootViewController is TWWatchdogInspectorViewController)
    }
}
