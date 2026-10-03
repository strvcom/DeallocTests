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

/// Reports an issue to Swift Testing when running inside a Swift Testing test, otherwise to
/// XCTest. Exactly one framework gets it: since Swift 6.4 each framework also records the
/// other's failures, so reporting to both would show every issue twice.
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
        // Shown as an expected failure; the test passes
        let options = XCTExpectedFailure.Options()
        options.isStrict = false
        XCTExpectFailure("Reported as a warning (DeallocationConfiguration.severity)", options: options) {
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
            withKnownIssue("Reported as a warning (DeallocationConfiguration.severity)", isIntermittent: true) {
                Issue.record(Comment(rawValue: message), sourceLocation: sourceLocation)
            }
        #endif
    }
}

#endif
