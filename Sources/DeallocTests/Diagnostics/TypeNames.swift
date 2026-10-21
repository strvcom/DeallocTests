//
//  TypeNames.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

import Foundation

enum TypeNames {
    static func readableName(of object: AnyObject) -> String {
        readableName(of: type(of: object))
    }

    static func readableName(of type: Any.Type) -> String {
        String(reflecting: type)
            .replacingOccurrences(of: #"\(unknown context at \$[0-9a-fA-F]+\)\."#, with: "", options: .regularExpression)
    }
}
