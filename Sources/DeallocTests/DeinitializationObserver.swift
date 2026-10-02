//
//  DeinitializationObserver.swift
//  DeallocTests
//
//  Created by Dan Cech on 16.03.2019.
//  Copyright © 2019 STRV. All rights reserved.
//

import Foundation
import os

public protocol ClassNameIdentifiable: AnyObject {
    var myClass: AnyClass { get }
}

public extension ClassNameIdentifiable {
    var myClass: AnyClass {
        return type(of: self)
    }
}

/// Thread-safe record of the instances tracked during a single dealloc test step.
///
/// Every tracked instance gets its own token so leaks are detected per instance,
/// not per class. Deinitialization can happen on any thread, hence the lock.
final class DeallocRegistry: Sendable {
    struct Entry {
        let objectClass: AnyClass
        var isDeallocated: Bool
    }

    private struct State {
        var nextToken = 0
        var entries: [Int: Entry] = [:]
        var isLoggingEnabled = false
    }

    static let shared = DeallocRegistry()

    private let state = OSAllocatedUnfairLock(uncheckedState: State())

    var isLoggingEnabled: Bool {
        get { state.withLockUnchecked { $0.isLoggingEnabled } }
        set { state.withLockUnchecked { $0.isLoggingEnabled = newValue } }
    }

    /// Tracked instances in the order they were registered
    var entries: [Entry] {
        state.withLockUnchecked { state in
            state.entries.sorted { $0.key < $1.key }.map(\.value)
        }
    }

    var hasLiveInstances: Bool {
        state.withLockUnchecked { state in
            state.entries.values.contains { !$0.isDeallocated }
        }
    }

    func reset() {
        state.withLockUnchecked { $0.entries = [:] }
    }

    func registerAllocation(of objectClass: AnyClass) -> Int {
        let token = state.withLockUnchecked { state in
            let token = state.nextToken
            state.nextToken += 1
            state.entries[token] = Entry(objectClass: objectClass, isDeallocated: false)
            return token
        }
        log("Alloc \(objectClass)")
        return token
    }

    func registerDeallocation(token: Int, of objectClass: AnyClass) {
        state.withLockUnchecked { $0.entries[token]?.isDeallocated = true }
        log("Dealloc \(objectClass)")
    }

    func log(_ message: @autoclosure () -> String) {
        guard isLoggingEnabled else {
            return
        }
        print(message())
    }
}

/// This is a simple object whose job is to report to `DeallocRegistry`
/// when it deinitializes together with its owner.
final class DeinitializationObserver {
    private let token: Int
    private let myClass: AnyClass
    private let registry: DeallocRegistry

    init(myClass: AnyClass, registry: DeallocRegistry = .shared) {
        self.myClass = myClass
        self.registry = registry
        token = registry.registerAllocation(of: myClass)
    }

    deinit {
        registry.registerDeallocation(token: token, of: myClass)
    }
}
