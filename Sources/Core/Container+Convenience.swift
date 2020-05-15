//
//  Container+Convenience.swift
//  iWeather MVVM
//
//  Created by Abel Osorio on 10/11/18.
//  Copyright © 2018 STRV. All rights reserved.
//

import Foundation
import Swinject

public extension Container {
    func forceResolve<Service>(_ serviceType: Service.Type) -> Service {
        guard let service = resolve(serviceType) else {
            fatalError("forceResolve method could not resolve \(serviceType)")
        }
        return service
    }
}
