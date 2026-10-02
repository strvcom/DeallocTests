//
//  DeallocTestable+Internals.swift
//  DeallocTests
//
//  Created by Dan Cech on 08.04.2019.
//  Copyright © 2019 STRV. All rights reserved.
//

import Foundation

@available(*, deprecated)
extension DeallocTestable {
    /// This stores the `DeinitializationObserver`. It's private so you
    /// cannot interfere with this outside. Also we're using a strong retain
    /// which will ensure that the `DeinitializationObserver` is deinitialized
    /// at the same time as your object.
    private var deinitializationObserver: DeinitializationObserver? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.deinitializationObserver) as? DeinitializationObserver
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.deinitializationObserver,
                newValue,
                objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    public var deallocTestSupportInstalled: Bool? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.deallocTestSupportInstalled) as? Bool
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.deallocTestSupportInstalled,
                newValue,
                objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// Starts tracking this instance. Calling it repeatedly has no effect.
    public func initializeDeallocTestSupport() {
        if deallocTestSupportInstalled != nil {
            return
        }

        deinitializationObserver = DeinitializationObserver(myClass: myClass)
        deallocTestSupportInstalled = true
    }
}
