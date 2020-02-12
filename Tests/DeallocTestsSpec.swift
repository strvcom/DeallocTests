//
//  DeallocTestsSpec.swift
//  DeallocTests
//
//  Created by Daniel Cech, Jan Kaltoun on 01/04/19.
//  Copyright © 2019 DanielCech, jankaltoun. All rights reserved.
//

import Quick
import Nimble
@testable import DeallocTests

class DeallocTestsSpec: QuickSpec {
    override func spec() {
        describe("DeallocTestsSpec") {
            it("works") {
                expect(DeallocTests.name) == "DeallocTests"
            }
        }
    }
}
