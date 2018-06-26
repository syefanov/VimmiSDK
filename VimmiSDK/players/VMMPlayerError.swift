//
//  VMMPlayerError.swift
//  VimmiPlayer
//
//  Created by Serhii Yefanov on 3/12/18.
//  Copyright © 2018 Serhii Yefanov. All rights reserved.
//

import Foundation

@objc public enum VMMPlayerError : Int, Error {
    case AssetLoadingFailed
    case WrongAsset
    case WrongSDKSettings
    case MediaLinkEmpty
    case MissingVideoURL
    case ChromecastLoadingError
}

extension VMMPlayerError : LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .AssetLoadingFailed: return "Failed loading asset"
        case .MediaLinkEmpty: return "Media link is empty"
        case .WrongSDKSettings: return "Wrong SDK Settings"
        case .WrongAsset: return ""
        case .MissingVideoURL: return "Missing video URL"
        case .ChromecastLoadingError: return "Chromecast loading error"
        }
    }
}
