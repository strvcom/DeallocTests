//
//  LeakReportTests.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

@testable import DeallocTests
import Testing

private final class PrivateObject {}

@Suite("Leak reports")
struct LeakReportTests {
    @Test func readableNameDropsUnknownContext() {
        let name = TypeNames.readableName(of: PrivateObject())

        #expect(name == "DeallocTestsTests.PrivateObject")
    }

    @Test func messageWithoutHintsGivesGeneralAdvice() {
        let report = LeakReport(typeName: "App.Screen", timeout: .seconds(2))

        #expect(report.message.hasPrefix("App.Screen was not deallocated within 2 sec. Something still holds"))
    }

    @Test(arguments: [
        (Duration.milliseconds(400), "400 ms"),
        (.seconds(2), "2 sec"),
        (.milliseconds(3250), "3.2 sec"),
        (.milliseconds(1999), "1.9 sec"),
    ])
    func durationsReadTheSameInEveryLocale(duration: Duration, text: String) {
        #expect(DurationText.describe(duration) == text)
    }

    @Test @MainActor func pollingReturnsAsSoonAsTheConditionHolds() async {
        let clock = ContinuousClock()
        let start = clock.now

        let result = await Polling.waitUntil(timeout: .seconds(5)) { true }

        #expect(result)
        #expect(clock.now - start < .seconds(1))
    }

    @Test @MainActor func pollingGivesUpAfterTheTimeout() async {
        let result = await Polling.waitUntil(timeout: .milliseconds(50)) { false }

        #expect(!result)
    }
}
