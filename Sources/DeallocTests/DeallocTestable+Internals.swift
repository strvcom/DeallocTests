//
//  DeallocTestable+Internals.swift
//  DeallocTests
//
//  Created by Dan Cech on 08.04.2019.
//  Copyright © 2019 STRV. All rights reserved.
//

import Foundation

extension DeallocTestable {
    /// This stores the `DeinitializationObserver`. It's fileprivate so you
    /// cannot interfere with this outside. Also we're using a strong retain
    /// which will ensure that the `DeinitializationObserver` is deinitialized
    /// at the same time as your object.
    private var deinitializationObserver: DeinitializationObserver {
        get {
            // swiftlint:disable:next force_cast
            return objc_getAssociatedObject(self, &AssociatedKeys.DeinitializationObserver) as! DeinitializationObserver
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.DeinitializationObserver,
                newValue,
                objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    public var deallocTestSupportInstalled: Bool? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.DeallocTestSupportInstalled) as? Bool
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.DeallocTestSupportInstalled,
                newValue,
                objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// This is what you call to add a block that should execute on `deinit`
    public func initializeDeallocTestSupport() {
        if deallocTestSupportInstalled != nil {
            return
        }
        
        deinitializationObserver = DeinitializationObserver(
            execute: { className in
                print("Dealloc \(className)")
                deallocatedClasses.append(className)
            },
            myClass: myClass
        )

        deallocTestSupportInstalled = true
    }
}
