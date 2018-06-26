//
//  VMMGlobalVideoHandler.swift
//  VimmiPlayer
//
//  Created by Serhii Yefanov on 4/16/18.
//  Copyright © 2018 Serhii Yefanov. All rights reserved.
//

import Foundation
import GoogleCast

@objc public class VMMGlobalVideoHandler: NSObject {
    
    @objc public static let shared = VMMGlobalVideoHandler.init()
    private override init() {
        super.init()
        VMMChromecastHandler.shared.delegate = self
    }
    
    @objc public var registeredPlayer: VMMCorePlayer?
    @objc public var currentChromecastPlayer: VMMChromecastPlayer?

    @objc public static func registerPlayer(_ player: VMMCorePlayer) {
        shared.registeredPlayer = player
    }
    
    @objc public static func removeRegisteredPlayer() {
        shared.registeredPlayer = nil;
    }
    
    @objc public static func removePlayer(_ player: VMMCorePlayer) {
        shared.registeredPlayer = nil
    }
    
    @objc public static func playAsset(_ asset: VMMAsset) {
        if shared.currentChromecastPlayer != nil {
            if let view = shared.registeredPlayer?.playerView {
                shared.currentChromecastPlayer?.updateWithPlayerView(view)
            }
            
            shared.currentChromecastPlayer!.playAsset(asset as! VMMVideoAsset)
        }
        else {
            shared.registeredPlayer?.currentAsset = asset
            shared.registeredPlayer?.play()
        }
    }
}

extension VMMGlobalVideoHandler: VMMChromecastHandlerDelegate {
    
    func sessionDidStart(session: GCKSession) {
        if let asset = self.registeredPlayer?.currentAsset,
            asset is VMMVideoAsset {
            if self.currentChromecastPlayer == nil {
                self.currentChromecastPlayer = VMMChromecastPlayer()
            }
            session.remoteMediaClient?.add(self.currentChromecastPlayer!)
            
            self.registeredPlayer?.stopPlaying()
            self.registeredPlayer?.detachAsset()
            self.currentChromecastPlayer!.playAsset(asset as! VMMVideoAsset)
            self.changePlayer(self.registeredPlayer, to: self.currentChromecastPlayer)
        }
    }

    func sessionDidEnd(session: GCKSession, withError error: Error?) {
        if self.currentChromecastPlayer != nil {
            session.remoteMediaClient?.remove(self.currentChromecastPlayer!)
        }
        if let _error = error {
            print("session error: \(_error.localizedDescription)")
        }
        else if let asset = self.currentChromecastPlayer?.currentAsset {
            self.registeredPlayer?.currentAsset = asset
            self.changePlayer(self.currentChromecastPlayer, to: self.registeredPlayer)
            self.registeredPlayer?.play()
            self.currentChromecastPlayer = nil
        }
    }
    
    func mediaLoadingFailed(error: Error) {
        print("Chromecast loading error")
    }
    
    
    func changePlayer(_ player: VMMCorePlayer?, to newPlayer: VMMCorePlayer?) {
        if let handlers = player?.playerHandlers {
            for owner in handlers {
                owner.videoPlayer = newPlayer
                newPlayer?.playerHandlers = handlers
                player?.playerHandlers = nil
            }
        }
        if let view = player?.detachPlayerView() {
            newPlayer?.updateWithPlayerView(view)
        }
    }
    
}
