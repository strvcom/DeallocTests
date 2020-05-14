//
//  SceneConfigurationsContainer.swift
//  Utilities
//
//  Created by Jan on 08/04/2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

public struct SceneConfigurationsContainer {
    private enum CodingKeys: String, CodingKey {
        case applicationScenes = "UIWindowSceneSessionRoleApplication"
        case externalDisplayScenes = "UIWindowSceneSessionRoleExternalDisplay"
    }

    public let applicationScenes: [SceneConfiguration]
    public let externalDisplayScenes: [SceneConfiguration]

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        applicationScenes = try values.decode([SceneConfiguration].self, forKey: .applicationScenes)
        externalDisplayScenes = try values.decodeIfPresent([SceneConfiguration].self, forKey: .externalDisplayScenes) ?? []
    }
}

// MARK: - Decodable
extension SceneConfigurationsContainer: Decodable {}
