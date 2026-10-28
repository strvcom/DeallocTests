# Configuration and Grace Period

Set the timeout, the grace period and the severity of leaks for a test, a suite or a test case class.

## Overview

`timeout` is the only option ``expectDeallocation(_:timeout:afterRelease:fileID:filePath:line:column:of:)``
takes, because it describes the object: some screens take longer to go away. Everything else is a
policy for a whole test or suite, set through ``DeallocationConfiguration``:

| Option | Default | Swift Testing trait |
|---|---|---|
| ``DeallocationConfiguration/timeout`` | 2 sec | ``Testing/Trait/deallocationTimeout(_:)`` |
| ``DeallocationConfiguration/gracePeriod`` | 3 sec | ``Testing/Trait/deallocationGracePeriod(_:)`` |
| ``DeallocationConfiguration/severity`` | `.error` | ``Testing/Trait/deallocationIssues(_:)`` |

A passing check ends as soon as the object is gone, so a longer timeout only slows down tests
that find a leak.

### Grace period

An object still alive at the timeout is watched for the grace period. If it goes away then, the
check reports a warning instead of failing:

```
MyApp.SearchViewModel was released after 3.2 sec, later than the 2 sec timeout. That's bounded retention, not a leak: something kept it alive for a while, e.g. a task, an animation or a delayed callback. If that's expected, raise the timeout.
```

Only real leaks take the timeout plus the grace period to report. `.zero` turns the grace period
off, and an object still alive at the timeout is then a leak.

The check judges by when the object was actually released, not by when the test got to look, so
a busy main thread doesn't turn a leak into a warning.

### Severity

With ``DeallocationIssueSeverity/warning``, leaks are reported as warnings that don't fail the
test, e.g. while adopting dealloc tests in an existing project. The grace period is skipped then,
since it can't change the outcome.

### Swift Testing

Add the traits to a suite or a test. A test's own trait wins over its suite's, and a `timeout`
passed to the call wins over both.

```swift
@Suite(.deallocationTimeout(.seconds(5)))
struct ScreenDeallocTests { … }

// Adopting dealloc tests in an existing project: report leaks as warnings for now
@Suite(.deallocationIssues(.warning))
struct LegacyDeallocTests { … }
```

### XCTest

Use ``withDeallocationConfiguration(_:isolation:operation:)`` around a test's code, or the
synchronous ``withDeallocationConfiguration(_:operation:)`` around `invokeTest()` for a whole test
case class:

```swift
await withDeallocationConfiguration({ $0.timeout = .seconds(5) }) {
    await expectDeallocation(.present) { makeProfileViewController() }
}

final class LegacyDeallocTests: XCTestCase {
    override func invokeTest() {
        withDeallocationConfiguration({ $0.severity = .warning }) {
            super.invokeTest()
        }
    }
}
```

### Which configuration applies

Each object is checked with the configuration in effect where it's tracked: where
`expectDeallocation` is called, or where `trackForDeallocation(_:)` is called. Objects tracked in
one test can therefore have different timeouts.
