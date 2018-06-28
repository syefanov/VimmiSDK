//
//  VMMPlayerItemAsset.swift
//  VimmiSDK
//
//  Created by Serhii Yefanov on 6/20/18.
//  Copyright © 2018 Serhii Yefanov. All rights reserved.
//

import Foundation
import AVKit

@objc public protocol VMMPlayerItemAsset: VMMAsset {
    
    var asset : AVURLAsset? { get set }
    var playerItem: AVPlayerItem? { get set }
    
    func stopLoadingAsset()
}
