//
//  LeakHints.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

import Foundation

/// Looks at the stored properties of a leaked object and points at the usual suspects.
enum LeakHints {
    static let maximumCycleDepth = 4
    static let maximumVisitedObjects = 300

    static func hints(for object: AnyObject) -> [String] {
        var hints = [String]()

        for property in storedProperties(of: object) {
            if let kind = suspiciousKind(of: property.value) {
                hints.append("`\(property.label)` is \(kind)")
            }
        }

        hints += cycles(from: object).map { path in
            "`\(path)` refers back to the object. That's a retain cycle unless one of the references is weak"
        }

        return hints
    }

    // MARK: - Suspicious properties

    private static func suspiciousKind(of value: Any) -> String? {
        guard let value = unwrapped(value), !isEmptyCollection(value) else {
            return nil
        }

        let typeName = String(describing: type(of: value))

        if typeName.contains("->") {
            return "a closure. Make sure it captures self weakly"
        }

        if typeName.contains("AnyCancellable") {
            return "a Combine subscription. Make sure its sink captures self weakly"
        }

        if typeName.hasPrefix("Task<") {
            return "a task. Make sure it's cancelled or captures self weakly"
        }

        if value is Timer {
            return "a timer. A scheduled timer keeps its target until it's invalidated"
        }

        return nil
    }

    private static func unwrapped(_ value: Any) -> Any? {
        let mirror = Mirror(reflecting: value)

        guard mirror.displayStyle == .optional else {
            return value
        }

        return mirror.children.first.flatMap { unwrapped($0.value) }
    }

    private static func isEmptyCollection(_ value: Any) -> Bool {
        let mirror = Mirror(reflecting: value)

        switch mirror.displayStyle {
        case .collection, .set, .dictionary:
            return mirror.children.isEmpty
        default:
            return false
        }
    }

    // MARK: - Cycles

    private static func cycles(from root: AnyObject) -> [String] {
        let rootIdentifier = ObjectIdentifier(root)
        var visited: Set<ObjectIdentifier> = [rootIdentifier]
        var queue: [(object: AnyObject, path: String, depth: Int)] = [(root, "self", 0)]
        var found = [String]()

        while !queue.isEmpty, visited.count < maximumVisitedObjects {
            let (object, path, depth) = queue.removeFirst()

            guard depth < maximumCycleDepth else {
                continue
            }

            for property in storedProperties(of: object) {
                for child in referencedObjects(in: property.value) {
                    let childPath = "\(path).\(property.label)"
                    let childIdentifier = ObjectIdentifier(child)

                    if childIdentifier == rootIdentifier {
                        found.append(childPath)
                    } else if isUserDefined(type(of: child)), visited.insert(childIdentifier).inserted {
                        queue.append((child, childPath, depth + 1))
                    }
                }
            }
        }

        return found
    }

    // MARK: - Reflection

    private struct Property {
        let label: String
        let value: Any
    }

    private static func storedProperties(of object: AnyObject) -> [Property] {
        var properties = [Property]()
        var mirror: Mirror? = Mirror(reflecting: object)

        while let currentMirror = mirror {
            if let subjectType = currentMirror.subjectType as? AnyClass, !isUserDefined(subjectType) {
                break
            }

            for child in currentMirror.children {
                guard let label = child.label, !label.hasPrefix("_$") else {
                    continue
                }
                properties.append(Property(label: cleaned(label), value: child.value))
            }

            mirror = currentMirror.superclassMirror
        }

        return properties
    }

    private static func referencedObjects(in value: Any, depth: Int = 0) -> [AnyObject] {
        let mirror = Mirror(reflecting: value)

        if mirror.displayStyle == .class {
            return [value as AnyObject]
        }

        guard depth < 3 else {
            return []
        }

        return mirror.children.prefix(50).flatMap { referencedObjects(in: $0.value, depth: depth + 1) }
    }

    private static func isUserDefined(_ objectClass: AnyClass) -> Bool {
        guard let bundleIdentifier = Bundle(for: objectClass).bundleIdentifier else {
            return true
        }
        return !bundleIdentifier.hasPrefix("com.apple.")
    }

    private static func cleaned(_ label: String) -> String {
        let label = label.replacingOccurrences(of: "$__lazy_storage_$_", with: "")
        return label.hasPrefix("_") ? String(label.dropFirst()) : label
    }
}
