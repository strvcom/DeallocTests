//
//  DeallocTestable.swift
//  DeallocTests
//
//  Created by Dan Cech on 16.01.2019.
//  Copyright © 2019 STRV. All rights reserved.
//

import Foundation

/// We're using objc associated objects to have this `DeinitializationObserver`
/// stored inside the protocol extension. The keys are only used for their address.
enum AssociatedKeys {
    @MainActor static var deinitializationObserver: UInt8 = 0
    @MainActor static var deallocTestSupportInstalled: UInt8 = 0
}

/// Protocol for any object that implements this logic
@MainActor
public protocol DeallocTestable: ClassNameIdentifiable {
    func initializeDeallocTestSupport()
}
