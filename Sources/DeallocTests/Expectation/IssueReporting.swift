//
//  IssueReporting.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

import XCTest

#if canImport(Testing)
    import Testing
#endif

/// Place in the test source where a failure is reported
struct TestSourceLocation: Sendable {
    let fileID: StaticString
    let filePath: StaticString
    let line: UInt
    let column: UInt

    init(fileID: StaticString, filePath: StaticString, line: UInt, column: UInt) {
        self.fileID = fileID
        self.filePath = filePath
        self.line = line
        self.column = column
    }
}

/// Reports a failure to Swift Testing when running inside a Swift Testing test, otherwise to XCTest
func reportIssue(_ message: String, at location: TestSourceLocation) {
    #if canImport(Testing)
        if Test.current != nil {
            Issue.record(
                Comment(rawValue: message),
                sourceLocation: SourceLocation(
                    fileID: String(describing: location.fileID),
                    filePath: String(describing: location.filePath),
                    line: Int(location.line),
                    column: Int(location.column)
                )
            )
            return
        }
    #endif

    XCTFail(message, file: location.filePath, line: location.line)
}
