//
//  Container+Convenience.swift
//  iWeather MVVM
//
//  Created by Abel Osorio on 10/11/18.
//  Copyright © 2018 STRV. All rights reserved.
//

import Foundation

#if canImport(Swinject)
    import Swinject

    public extension Container {
        func forceResolve<Service>(_ serviceType: Service.Type) -> AnyObject {
            guard let service = resolve(serviceType) else {
                fatalError("forceResolve method could not resolve \(serviceType)")
            }
            return service as AnyObject
        }
    }
#endif
