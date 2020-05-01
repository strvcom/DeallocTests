//
//  TestHelper.swift
//  DeallocTests
//
//  Created by Dan Cech on 08.04.2019.
//  Copyright © 2019 STRV. All rights reserved.
//

import Foundation

public func delay(_ delay: Double, closure: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
        execute: closure
    )
}
