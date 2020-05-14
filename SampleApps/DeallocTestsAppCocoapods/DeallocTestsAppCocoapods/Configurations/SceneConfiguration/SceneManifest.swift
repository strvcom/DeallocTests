//
//  SceneConfiguration.swift
//  Utilities
//
//  Created by Jan on 08/04/2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

public struct SceneManifest {
    private enum CodingKeys: String, CodingKey {
        case supportsMultipleScenes = "UIApplicationSupportsMultipleScenes"
        case configurations = "UISceneConfigurations"
    }

    public let supportsMultipleScenes: Bool
    public let configurations: SceneConfigurationsContainer
}

// MARK: - Decodable
extension SceneManifest: Decodable {}
