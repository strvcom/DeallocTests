//
//  main.swift
//  DeallocTestsApp
//
//  Created by Jan Schwarz on 13/02/2019.
//  Copyright © 2019 STRV. All rights reserved.
//

import UIKit

private func delegateClass() -> AnyClass {
    NSClassFromString("TestAppDelegate") ?? AppDelegate.self
}

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(delegateClass()))
