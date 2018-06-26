//
//  VimmiPlayer.swift
//  VimmiSDK
//
//  Created by Serhii Yefanov on 6/12/18.
//  Copyright © 2018 Serhii Yefanov. All rights reserved.
//

import Foundation

public class VimmiPlayer {
    
    private var player: VMMVideoPlayer
    private var playerView: UIView!
    private var fullScreenView: UIView?
    private var playerUI: VMMPlayerUI?
    private weak var parentController: UIViewController!
    private var mediaId: String?
    private var asset: VMMProTVAsset?
    private var isFullScreen: Bool = false
    private var playerError: Error?
    
    private var isMediaLoaded: Bool = false
    
    private var progressBarColorMin: UIColor = VMMPlayerUI.defaultProgressMinColor
    private var progressBarColorMax: UIColor = VMMPlayerUI.defaultProgressMaxColor
    private var progressBarColorThumb: UIColor = VMMPlayerUI.defaultProgressThumbColor
    
    public init(withView view: UIView, onController vc: UIViewController) {
        self.playerView = view
        self.parentController = vc
        
        player = VMMVideoPlayer()
        //player.playerHandlers = [self]
    }
    
    deinit {
        self.playerView = nil
        self.parentController = nil
    }
    
    // MARK: - Public methods
    
    public func loadMediaWithId(_ id: String, autoplay: Bool, completion: @escaping (_ success: Bool, _ error: Error?)->Void) {
        if player.currentAsset != nil {
            player.stopPlaying()
            player.detachAsset()
            asset = nil
        }

        player.updateWithPlayerView(self.playerView)
        self.setupPlayerUIView()
        self.mediaId = id
        self.asset = VMMProTVAsset(mediaId: self.mediaId!)
        
        self.asset!.prepareForPlay(autoPlay: autoplay) { [completion, autoplay] (_asset, error) in
            self.isMediaLoaded = true
            if autoplay {
                self.loadVideoStream(completion: completion)
            }
            else {
                self.showOverlayView(true)
                completion(true, nil)
            }
        }
    }
    
    public func setProgressBarColor(min: UIColor, max: UIColor, thumb: UIColor) {
        self.progressBarColorMin = min
        self.progressBarColorMax = max
        self.progressBarColorThumb = thumb
        
        self.playerUI?.setProgressBarColor(min: min, max: max, thumb: thumb)
    }
    
    // MARK: - Private methods
    
    private func  setupPlayerUIView() {
        if self.playerUI != nil {
            self.playerUI?.removeFromSuperview()
            self.playerUI = nil
        }
        
        if self.player.playerView != nil {
            self.playerUI = VMMPlayerUI(frame: self.player.playerView!.bounds)
            self.playerUI?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.playerUI?.delegate = self
            self.playerUI?.setBigPlayButtonHidden(self.player.isPlaying)
            self.player.playerView!.addSubview(self.playerUI!)
            if let duration = self.asset?.assetDuration {
                self.playerUI?.setMaximumDuration(duration)
            }
            if let currentPosition = self.asset?.currentPlaybackTime {
                self.playerUI?.updatePlaybackTime(currentPosition)
            }
            self.playerUI?.setProgressBarColor(min:self.progressBarColorMin,
                                               max: self.progressBarColorMax,
                                               thumb: self.progressBarColorThumb)
            self.playerUI?.updatePlayButtonImage(isPlaying: self.player.isPlaying)
            self.playerUI?.updateSoundButtonImage(soundEnabled: self.player.volume > 0.0)
            self.playerUI?.updateFullScreenButtonImage(isFullScreen: self.isFullScreen)
        }
    }

    func showOverlayView(_ show: Bool) {
        if !self.player.isPlaying {
            self.player.setPlayerOverlayHidden(hidden: !show, link: self.asset?.imageBackdropLink)
        }
        else {
            self.player.setPlayerOverlayHidden(true)
        }
        if self.playerUI != nil {
            self.playerView.bringSubview(toFront: self.playerUI!)
        }
    }
    
    func loadVideoStream(completion: @escaping (_ success: Bool, _ error: Error?)->Void) {
        if self.player.currentAsset == nil {
            self.asset?.loadVideoStream(completion: { (_asset, _error) in
                if _error != nil {
                    completion(false, _error)
                    DispatchQueue.main.async { [_error] in
                        self.playerError = _error
                        self.playerUI?.showError(_error!)
                        self.playerUI?.setBigPlayButtonHidden(true)
                    }
                }
                else {
                    if let __asset = _asset {
                        self.playerUI?.setShouldShowControls(true)
                        self.player.currentAsset = __asset
                        self.playerUI?.updatePlaybackTime(__asset.currentPlaybackTime)
                        self.playerUI?.setMaximumDuration(__asset.assetDuration)
                        
                    }
                    self.player.play()
                    self.playerUI?.setBigPlayButtonHidden(true)
                    self.playerUI?.updatePlayButtonImage(isPlaying: true)
                    
                    completion(true, nil)
                }
            })
        }
        else {
            completion(false, nil)
        }
    }
}

/*extension VimmiPlayer: VMMPlayerHandler {
    
    func playerDidStartPlaying(player: VMMCorePlayer) {
        self.showOverlayView(false)
        self.playerUI?.setBigPlayButtonHidden(true)
        self.playerUI?.updatePlayButtonImage(isPlaying: self.player.isPlaying)
    }
    
    func playerDidPause(player: VMMCorePlayer) {
        self.playerUI?.updatePlayButtonImage(isPlaying: self.player.isPlaying)
        self.playerUI?.setBigPlayButtonHidden(false)
    }
    
    func playerTimeObserverFired(player: VMMCorePlayer, time: Double) {
        self.playerUI?.updatePlaybackTime(time)
    }
    
    func playerDidChangePlaybackTime(player: VMMCorePlayer, time: Double) {
        self.playerUI?.updatePlaybackTime(time)
    }
    
    func playerDidFinishPlaying(player: VMMCorePlayer) {
        self.player.setPlayerPlaybackTime(timeInSeconds: 0.0, completion: nil)
    }
}*/

extension VimmiPlayer: VMMPlayerUIDelegate {
    internal func didTapPlayButton() {
        if self.asset?.streamLoaded == true {
            self.changePlayerState()
        }
        else if self.isMediaLoaded {
            self.playerUI?.setUIEnabled(false)
            self.loadVideoStream() { (success, error) in
                self.playerUI?.setUIEnabled(true)
                if success {
                    self.player.play()
                }
            }
        }
    }
    
    private func changePlayerState() {
        if self.player.isPlaying {
            self.player.pause()
        }
        else {
            self.player.play()
        }
    }
    
    internal func didTapSoundButton() {
        if self.player.volume > 0.0 {
            self.player.volume = 0.0
        }
        else {
            self.player.volume = 1.0
        }
        self.playerUI?.updateSoundButtonImage(soundEnabled: self.player.volume > 0.0)
    }
    
    internal func didChangeProgressSliderValue(time: Double) {
        var playbackTime = time
        if let assetDuration = self.asset?.assetDuration {
            if playbackTime > assetDuration {
                playbackTime = assetDuration - 0.1
            }
        }
        self.player.setPlayerPlaybackTime(timeInSeconds: playbackTime) {
            if let time = self.asset?.currentPlaybackTime {
                self.playerUI?.sliderProgress.setValue(Float(time), animated: true)
            }
        }
    }
    
    internal func didTapFullScreenButton() {
        if self.isFullScreen {
            let oldFrame = self.playerView.frame
            if let frame = self.fullScreenView?.frame {
                self.playerView.frame = frame
            }
            self.isFullScreen = false
            self.fullScreenView?.removeFromSuperview()
            self.fullScreenView = nil
            self.player.updateWithPlayerView(self.playerView)
            
            UIView.animateKeyframes(withDuration: 0.5, delay: 0.0, options: .layoutSubviews, animations: { [oldFrame] in
                self.playerView?.frame = oldFrame
            }) { _ in
                self.setupPlayerUIView()
                self.playerUI?.setShouldShowControls(self.asset?.streamLoaded ?? false)
                if self.playerError != nil {
                    self.playerUI?.showError(self.playerError!)
                }
                self.playerUI?.setBigPlayButtonHidden(self.player.isPlaying)
            }
        }
        else {
            self.isFullScreen = true
            self.fullScreenView = UIView(frame: self.playerView.frame)
            
            self.fullScreenView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.fullScreenView!.backgroundColor = .black
            self.parentController.view.addSubview(self.fullScreenView!)
            self.player.updateWithPlayerView(self.fullScreenView!)
            
            UIView.animateKeyframes(withDuration: 0.5, delay: 0.0, options: .layoutSubviews, animations: {
                self.fullScreenView?.frame = self.parentController.view.bounds
                
            }) { _ in
                self.setupPlayerUIView()
                self.playerUI?.setShouldShowControls(self.asset?.streamLoaded ?? false)
                if self.playerError != nil {
                    self.playerUI?.showError(self.playerError!)
                }
                self.playerUI?.setBigPlayButtonHidden(self.player.isPlaying)
            }
            
        }
    }
}
