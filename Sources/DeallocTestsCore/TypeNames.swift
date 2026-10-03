//
//  TypeNames.swift
//  DeallocTestsCore
//
//  Copyright © 2026 STRV. All rights reserved.
//

import Foundation

package enum TypeNames {
    /// Module-qualified type name without the `(unknown context at $…)` part
    /// that Swift adds for private and local types
    package static func readableName(of object: AnyObject) -> String {
        readableName(of: type(of: object))
    }

    package static func readableName(of type: Any.Type) -> String {
        String(reflecting: type)
            .replacingOccurrences(of: #"\(unknown context at \$[0-9a-fA-F]+\)\."#, with: "", options: .regularExpression)
    }
}
