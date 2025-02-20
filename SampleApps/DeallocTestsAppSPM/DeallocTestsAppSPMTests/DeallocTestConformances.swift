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

extension MainCoordinator: @retroactive DeallocTestable {}
extension FirstViewController: @retroactive DeallocTestable {}
extension SecondViewController: @retroactive DeallocTestable {}
extension ThirdViewController: @retroactive DeallocTestable {}
extension APIManager: @retroactive DeallocTestable {}
