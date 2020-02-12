//
//  PostInitBehavior.swift
//  iWeather MVVM Tests
//
//  Created by Jan Kaltoun on 10.05.2019.
//  Copyright © 2019 STRV. All rights reserved.
//

import Foundation
import Swinject

class PostInitBehavior: Behavior {
    func container<Type, Service>(
        _: Container,
        didRegisterType _: Type.Type,
        toService entry: ServiceEntry<Service>,
        withName _: String?
    ) {
        entry.initCompleted { _, service in
            (service as? DeallocTestable)?.initializeDeallocTestSupport()
        }
    }
}
