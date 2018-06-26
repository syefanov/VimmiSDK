//
//  VMMPlayer.swift
//  VimmiPlayer
//
//  Created by Serhii Yefanov on 3/30/18.
//  Copyright © 2018 Serhii Yefanov. All rights reserved.
//

import UIKit
import MediaPlayer

@objc public class VMMCorePlayer: NSObject {
    @objc public var playerHandlers: [VMMPlayerHandler]?
    @objc public var currentAsset : VMMAsset?
    
    @objc public var volume: Float = 0.0
    @objc public var volumeView : MPVolumeView?
    
    var playerView : VMMPlayerView?
    
    @objc public var isPlaying : Bool {
        return false
    }
    
    @objc public func play() { }
    @objc public func pause() { }
    
    @objc public func setPlayerPlaybackTime(timeInSeconds time: Double, completion: (()->Void)?) { }
    @objc public func moveForward(onSeconds seconds: Double) { }
    @objc public func moveBackward(onSeconds seconds: Double) { }
    
    @objc public func stopPlaying() { }
    @objc public func detachAsset() { }
    
    @objc public func detachPlayerView() -> UIView? { return nil }
    @objc public func updateWithPlayerView(_ playerView: UIView) { }
    
    @objc public func currentAspectRatio() -> AVLayerVideoGravity? { return nil }
    @objc public func setAspectRatio(_ aspectRatio: AVLayerVideoGravity) { }

    @objc public func addHandler(_ handler: VMMPlayerHandler) {
        if self.playerHandlers == nil {
            self.playerHandlers = [VMMPlayerHandler]()
        }
        
        self.playerHandlers?.append(handler)
    }
    
    @objc public func removeHandler(_ handler: VMMPlayerHandler) {
        if self.playerHandlers != nil,
            let index = self.playerHandlers?.index(where: { (_handler) -> Bool in _handler === handler }) {
            self.playerHandlers?.remove(at: index)
        }
    }
    
// MARK: - Delegate methods
    internal func playerDidStartPlaying() {
        if let handlers = self.playerHandlers,
            !handlers.isEmpty {
            for handler in handlers {
                handler.playerDidStartPlaying?(player: self)
            }
        }
    }
    
    internal func playerDidPause() {
        if let handlers = self.playerHandlers,
            !handlers.isEmpty {
            for handler in handlers {
                handler.playerDidPause?(player: self)
            }
        }
    }
    
    internal func playerDidFinishPlaying() {
        if let handlers = self.playerHandlers,
            !handlers.isEmpty {
            for handler in handlers {
                handler.playerDidFinishPlaying?(player: self)
            }
        }
    }
    
    internal func playerDidChangePlaybackTime(time: Double) {
        if let handlers = self.playerHandlers,
            !handlers.isEmpty {
            for handler in handlers {
                handler.playerDidChangePlaybackTime?(player: self, time: time)
            }
        }
    }
    internal func playerFailedPlayingAsset(_ asset: VMMAsset, error: Error?) {
        if let handlers = self.playerHandlers,
            !handlers.isEmpty {
            for handler in handlers {
                handler.playerFailedPlayingAsset?(player: self, asset: asset, error: error)
            }
        }
    }
    
    internal func playerDidStartBuffering() {
        if let handlers = self.playerHandlers,
            !handlers.isEmpty {
            for handler in handlers {
                handler.playerDidStartBuffering?(player: self)
            }
        }
    }
    internal func playerDidFinishBuffering() {
        if let handlers = self.playerHandlers,
            !handlers.isEmpty {
            for handler in handlers {
                handler.playerDidFinishBuffering?(player: self)
            }
        }
    }
    internal func playerTimeObserverFired(time: Double) {
        if let handlers = self.playerHandlers,
            !handlers.isEmpty {
            for handler in handlers {
                handler.playerTimeObserverFired?(player: self, time: time)
            }
        }
    }
    
    internal func playerDidLoadAsset(_ asset: VMMAsset) {
        if let handlers = self.playerHandlers,
            !handlers.isEmpty {
            for handler in handlers {
                handler.playerDidLoadAsset?(player: self, asset: asset)
            }
        }
    }
    internal func playerDidFailLoadingAsset(_ asset: VMMAsset?, error: Error) {
        if let handlers = self.playerHandlers,
            !handlers.isEmpty {
            for handler in handlers {
                handler.playerDidFailLoadingAsset?(player: self, asset: asset, error: error)
            }
        }
    }
}
