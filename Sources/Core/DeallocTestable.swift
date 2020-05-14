//
//  DeallocTestable.swift
//  DeallocTests
//
//  Created by Dan Cech on 16.01.2019.
//  Copyright © 2019 STRV. All rights reserved.
//

import Foundation

/// We're using objc associated objects to have this `DeinitializationObserver`
/// stored inside the protocol extension

enum AssociatedKeys {
    static var DeinitializationObserver = "DeinitializationObserver"
    static var DeallocTestSupportInstalled = "DeallocTestSupportInstalled"
}

/// Protocol for any object that implements this logic
public protocol DeallocTestable: ClassNameIdentifiable {
    func initializeDeallocTestSupport()
}
