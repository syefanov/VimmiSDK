//
//  VimmiAsset.swift
//  VimmiPlayer
//
//  Created by Serhii Yefanov on 3/2/18.
//  Copyright © 2018 Serhii Yefanov. All rights reserved.
//

import Foundation
import AVKit

@objc public protocol VMMAsset {
    
    var assetDuration : Double { get set }
    var isLoaded : Bool { get set }
    var currentPlaybackTime : Double { get set }
    var title : String { get set }
    var imagePoster : UIImage? { get set }
    var imagePosterLink : String? { get set }
    var imageBackdrop : UIImage? { get set }
    var imageBackdropLink : String? { get set }
    
    var sourcesCount : Int { get set }
    
    var availableAudioTracks : [VMMAssetAudioTrack]? { get set }
    var preferredAudioTrack : VMMAssetAudioTrack? { get set }
    var availableSubtitles : [VMMAssetSubtitles]? { get set }
    
    func prepareForPlay(completion: @escaping (VMMAsset?, Error?)->Void)
    func selectAudioTrack(_ track: VMMAssetAudioTrack)
    func selectSubtitles(_ track: VMMAssetSubtitles?)
}
