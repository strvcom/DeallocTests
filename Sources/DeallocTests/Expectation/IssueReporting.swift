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

struct TestSourceLocation: Sendable {
    let fileID: StaticString
    let filePath: StaticString
    let line: UInt
    let column: UInt
}

func reportIssue(_ message: String, at location: TestSourceLocation) {
    #if canImport(Testing)
        if Test.current != nil {
            recordSwiftTestingIssue(message, at: location)
            return
        }
    #endif

    XCTFail(message, file: location.filePath, line: location.line)
}

#if canImport(Testing)

private func recordSwiftTestingIssue(_ message: String, at location: TestSourceLocation) {
    let sourceLocation = SourceLocation(
        fileID: String(describing: location.fileID),
        filePath: String(describing: location.filePath),
        line: Int(location.line),
        column: Int(location.column)
    )

    Issue.record(Comment(rawValue: message), sourceLocation: sourceLocation)
}

#endif
