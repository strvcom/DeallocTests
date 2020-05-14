//
//  Configuration.swift
//  iWeather MVVM
//
//  Created by Jan Schwarz on 27/11/2019.
//  Copyright © 2019 STRV. All rights reserved.
//

import Foundation

public struct Configuration: Decodable {
    private enum CodingKeys: String, CodingKey {
        case apiBaseUrl = "API_BASE_URL"
        case apiAppId = "API_APP_ID"
        case sceneManifest = "UIApplicationSceneManifest"
    }

    public let apiBaseUrl: String
    public let apiAppId: String
    public let sceneManifest: SceneManifest?
}

// MARK: Static properties
public extension Configuration {
    static let `default`: Configuration = {
        guard let propertyList = Bundle.main.infoDictionary else {
            fatalError("Unable to get property list.")
        }

        guard let data = try? JSONSerialization.data(withJSONObject: propertyList, options: []) else {
            fatalError("Unable to instantiate data from property list.")
        }

        let decoder = JSONDecoder()

        guard let configuration = try? decoder.decode(Configuration.self, from: data) else {
            fatalError("Unable to decode the Environment configuration file.")
        }

        return configuration
    }()
}
