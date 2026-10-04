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

func reportIssue(_ message: String, at location: TestSourceLocation, severity: DeallocationIssueSeverity = .error) {
    #if canImport(Testing)
        if Test.current != nil {
            recordSwiftTestingIssue(message, at: location, severity: severity)
            return
        }
    #endif

    switch severity {
    case .error:
        XCTFail(message, file: location.filePath, line: location.line)
    case .warning:
        let options = XCTExpectedFailure.Options()
        options.isStrict = false
        XCTExpectFailure("Reported as a warning", options: options) {
            XCTFail(message, file: location.filePath, line: location.line)
        }
    }
}

#if canImport(Testing)

private func recordSwiftTestingIssue(_ message: String, at location: TestSourceLocation, severity: DeallocationIssueSeverity) {
    let sourceLocation = SourceLocation(
        fileID: String(describing: location.fileID),
        filePath: String(describing: location.filePath),
        line: Int(location.line),
        column: Int(location.column)
    )

    switch severity {
    case .error:
        Issue.record(Comment(rawValue: message), sourceLocation: sourceLocation)
    case .warning:
        #if compiler(>=6.3)
            Issue.record(Comment(rawValue: message), severity: .warning, sourceLocation: sourceLocation)
        #else
            withKnownIssue("Reported as a warning", isIntermittent: true) {
                Issue.record(Comment(rawValue: message), sourceLocation: sourceLocation)
            }
        #endif
    }
}

#endif
