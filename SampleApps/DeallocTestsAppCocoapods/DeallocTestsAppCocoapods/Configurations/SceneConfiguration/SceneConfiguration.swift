//
//  SceneConfiguration.swift
//  Utilities
//
//  Created by Jan on 08/04/2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

public struct SceneConfiguration {
    private enum CodingKeys: String, CodingKey {
        case name = "UISceneConfigurationName"
        case delegateClassName = "UISceneDelegateClassName"
    }

    public let delegateClassName: String
    public let name: String
}

// MARK: - Decodable
extension SceneConfiguration: Decodable {}

// MARK: - Hashable
extension SceneConfiguration: Hashable {}
