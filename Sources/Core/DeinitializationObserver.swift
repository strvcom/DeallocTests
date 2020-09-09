//
//  DeinitializationObserver.swift
//  DeallocTests
//
//  Created by Dan Cech on 16.03.2019.
//  Copyright © 2019 STRV. All rights reserved.
//

import Foundation

typealias ClassClosureType = (AnyClass) -> Void

var allocatedClasses = [AnyClass]()
var deallocatedClasses = [AnyClass]()

public protocol ClassNameIdentifiable: AnyObject {
    var myClass: AnyClass { get }
}

public extension ClassNameIdentifiable {
    var myClass: AnyClass {
        return type(of: self)
    }
}

/// This is a simple object whose job is to execute
/// some closure when it deinitializes
class DeinitializationObserver {
    let execute: (AnyClass) -> Void
    var myClass: AnyClass

    init(execute: @escaping (AnyClass) -> Void, myClass: AnyClass) {
        self.execute = execute
        self.myClass = myClass

        print("Alloc \(myClass)")
        DispatchQueue.main.async {
            allocatedClasses.append(myClass)
        }
    }

    deinit {
        execute(myClass)
    }
}
