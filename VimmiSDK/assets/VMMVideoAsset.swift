//
//  VMMVideoAsset.swift
//  VimmiPlayer
//
//  Created by Serhii Yefanov on 3/19/18.
//  Copyright © 2018 Serhii Yefanov. All rights reserved.
//

import UIKit
import AVKit

fileprivate let assetKeys = ["playable", "hasProtectedContent", "duration"]

@objc public class VMMVideoAsset: NSObject, VMMPlayerItemAsset {
    
    public var sourcesCount: Int
    public var title: String
    public var imagePoster: UIImage?
    public var imagePosterLink: String?
    public var imageBackdrop: UIImage?
    public var imageBackdropLink: String?
    public var assetDuration: Double
    public var isLoaded: Bool
    public var currentPlaybackTime: Double
    
    @objc public var assetUrl: URL
    public var asset : AVURLAsset?
    public var playerItem: AVPlayerItem?
    @objc public var availableAudioTracks : [VMMAssetAudioTrack]? = [VMMAssetAudioTrack]()
    public var preferredAudioTrack: VMMAssetAudioTrack?
    @objc public var availableSubtitles : [VMMAssetSubtitles]? = [VMMAssetSubtitles]()

    
    @objc public init(url: URL) {
        self.assetUrl = url
        self.assetDuration = 0.0
        self.isLoaded = false
        self.currentPlaybackTime = 0.0
        self.imagePoster = nil
        self.imageBackdrop = nil
        self.sourcesCount = 0
        self.title = ""
        self.asset = AVURLAsset(url: url)
        self.playerItem = AVPlayerItem(asset: self.asset!)
    }
    
    @objc public convenience init?(urlString: String) {
        if let url = URL(string: urlString) {
            self.init(url: url)
        }
        else {
            return nil
        }
    }
    
    public func prepareForPlay(completion: @escaping (VMMAsset?, Error?) -> Void) {
        self.asset = AVURLAsset(url: self.assetUrl)
        self.asset!.loadValuesAsynchronously(forKeys: assetKeys, completionHandler: { [weak self] in
            DispatchQueue.main.async {
                guard let asset = self?.asset else { completion(self, VMMPlayerError.AssetLoadingFailed); return }
                self?.isLoaded = true
                self?.assetDuration = asset.duration.seconds
                self?.playerItem = AVPlayerItem(asset: asset)
                if let audioTracks = self?.asset?.mediaSelectionGroup(forMediaCharacteristic: .audible)?.options {
                    self?.availableAudioTracks?.removeAll()
                    for option in audioTracks {
                        let track = VMMAssetAudioTrack()
                        track.language = option.displayName
                        track.languageTag = option.extendedLanguageTag ?? ""
                        self?.availableAudioTracks?.append(track)
                    }
                }
                if let subtitles = self?.asset?.mediaSelectionGroup(forMediaCharacteristic: .legible)?.options {
                    self?.availableSubtitles?.removeAll()
                    for option in subtitles {
                        let subs = VMMAssetSubtitles()
                        subs.name = option.displayName
                        self?.availableSubtitles?.append(subs)
                    }
                }
                completion(self, nil)
            }
        })
    }
    
    @objc public func stopLoadingAsset() {
        self.asset?.cancelLoading()
    }
    
    @objc public func selectAudioTrack(_ track: VMMAssetAudioTrack) {
        guard let mediaGroup = self.asset?.mediaSelectionGroup(forMediaCharacteristic: .audible) else { return }
        for option in mediaGroup.options {
            if option.displayName == track.language {
                self.playerItem?.select(option, in: mediaGroup)
            }
        }
    }
    
    @objc public func selectSubtitles(_ track: VMMAssetSubtitles?) {
        guard let mediaGroup = self.asset?.mediaSelectionGroup(forMediaCharacteristic: .legible) else { return }
        if let _track = track {
            for option in mediaGroup.options {
                if option.displayName == _track.name {
                    self.playerItem?.select(option, in: mediaGroup)
                }
            }
        }
        else {
            if mediaGroup.allowsEmptySelection {
                self.playerItem?.select(nil, in: mediaGroup)
            }
        }
    }
}
