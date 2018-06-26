//
//  VMMAssetAudioTrack.swift
//  VimmiPlayer
//
//  Created by Serhii Yefanov on 3/15/18.
//  Copyright © 2018 Serhii Yefanov. All rights reserved.
//

import UIKit

public class VMMAssetAudioTrack: NSObject {
    @objc public var languageTag : String = ""
    @objc public var possibleLanguageTags : [String]?
    @objc public var language : String = ""
}
