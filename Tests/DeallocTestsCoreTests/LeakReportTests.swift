//
//  LeakReportTests.swift
//  DeallocTestsCoreTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

@testable import DeallocTestsCore
import Testing

private final class PrivateObject {}

final class ClosureHolder {
    var onUpdate: (() -> Void)?
}

@Suite("Core")
struct LeakReportTests {
    @Test func readableNameDropsUnknownContext() {
        let name = TypeNames.readableName(of: PrivateObject())

        #expect(name == "DeallocTestsCoreTests.PrivateObject")
    }

    @Test func messageWithoutHintsGivesGeneralAdvice() {
        let report = LeakReport(typeName: "App.Screen", timeout: .seconds(2))

        #expect(report.message.hasPrefix("App.Screen was not deallocated within 2 sec. Something still holds"))
    }

    @Test func messageWithHintsListsCausesAndExternalOwners() {
        let report = LeakReport(typeName: "App.Screen", timeout: .milliseconds(500), hints: ["`onUpdate` is a closure"])

        #expect(report.message == """
        App.Screen was not deallocated within 500 ms. Possible causes:
          • `onUpdate` is a closure
          • Or something outside still holds it: a parent's list of children, a cache or a singleton
        """)
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

    @Test func lateReleaseMessageExplainsBoundedRetention() {
        let message = LeakReport.lateReleaseMessage(typeName: "App.Store", releasedAfter: .milliseconds(3250), timeout: .seconds(2))

        #expect(message.hasPrefix("App.Store was released after 3.2 sec, later than the 2 sec timeout. That's bounded retention, not a leak"))
    }

    @Test func messageMentionsTheGracePeriod() {
        let report = LeakReport(typeName: "App.Screen", timeout: .seconds(2), gracePeriod: .seconds(3))

        #expect(report.message.hasPrefix("App.Screen was not deallocated within 2 sec. It was watched for another 3 sec after that."))
    }

    @Test func hintsNameClosureProperties() {
        let holder = ClosureHolder()
        holder.onUpdate = {}

        #expect(LeakHints.hints(for: holder).contains { $0.hasPrefix("`onUpdate` is a closure") })
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
