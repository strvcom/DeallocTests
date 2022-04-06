//
//  DeallocTestConformances.swift
//  DeallocTestsAppTests
//
//  Created by Daniel Cech on 01/05/2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation
import DeallocTestsDIFree
@testable import DeallocTestsAppSPM

extension MainCoordinator: DeallocTestable {}
extension FirstViewController: DeallocTestable {}
extension SecondViewController: DeallocTestable {}
extension ThirdViewController: DeallocTestable {}
