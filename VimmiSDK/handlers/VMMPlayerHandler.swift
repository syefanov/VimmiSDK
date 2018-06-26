//
//  VMMPlayerHandler.swift
//  VimmiPlayer
//
//  Created by Serhii Yefanov on 3/9/18.
//  Copyright © 2018 Serhii Yefanov. All rights reserved.
//

import UIKit
import AVKit

@objc public protocol VMMPlayerHandler {
    
    var videoPlayer : VMMCorePlayer? { get set }
    
    //MARK: - Public methods
    
    @objc optional func playerDidStartPlaying(player: VMMCorePlayer)
    @objc optional func playerDidPause(player: VMMCorePlayer)
    @objc optional func playerDidFinishPlaying(player: VMMCorePlayer)
    
    @objc optional func playerDidChangePlaybackTime(player: VMMCorePlayer, time: Double)
    
    @objc optional func playerDidStartBuffering(player: VMMCorePlayer)
    @objc optional func playerDidFinishBuffering(player: VMMCorePlayer)
    
    @objc optional func playerTimeObserverFired(player: VMMCorePlayer, time: Double)
    @objc optional func playerFailedPlayingAsset(player: VMMCorePlayer, asset: VMMAsset, error: Error?)
    
    @objc optional func playerDidLoadAsset(player: VMMCorePlayer, asset: VMMAsset)
    @objc optional func playerDidFailLoadingAsset(player: VMMCorePlayer, asset: VMMAsset?, error: Error)
}
