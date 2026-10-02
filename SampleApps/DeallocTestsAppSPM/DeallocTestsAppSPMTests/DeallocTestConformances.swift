//
//  DeallocTestConformances.swift
//  DeallocTestsAppTests
//
//  Created by Daniel Cech on 01/05/2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation
import DeallocTests
@testable import DeallocTestsAppSPM

@available(*, deprecated)
extension MainCoordinator: @retroactive DeallocTestable {}
@available(*, deprecated)
extension FirstViewController: @retroactive DeallocTestable {}
@available(*, deprecated)
extension SecondViewController: @retroactive DeallocTestable {}
@available(*, deprecated)
extension ThirdViewController: @retroactive DeallocTestable {}
@available(*, deprecated)
extension APIManager: @retroactive DeallocTestable {}
